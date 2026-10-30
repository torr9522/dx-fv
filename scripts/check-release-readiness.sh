#!/usr/bin/env bash
set -uo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "FAIL: run this script inside a Git worktree" >&2
  exit 1
}
cd "$repo_root"

readonly UPSTREAM_BASE_COMMIT=3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee
readonly UPSTREAM_BASE_TREE=6076e2ad5bc0ac0934d9c0a19b433661ff14db0b
readonly CLEAN_BASELINE_COMMIT=a5240dc45bcc21a9571bbea9745b423dbc166733
readonly REPLAYED_DX_TIP=568408e07697c264114d1801634c731c32d2b13b
readonly REPLAYED_DX_COUNT=15

failures=0
checks=0

pass() {
  checks=$((checks + 1))
  printf 'PASS: %s\n' "$1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

run() {
  local label=$1
  shift
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "required command: $1"
  else
    fail "missing required command: $1"
    return 1
  fi
}

tmp_dir=$(mktemp -d /tmp/flvx-release-check.XXXXXX)
trap 'find "$tmp_dir" -depth -delete 2>/dev/null || true' EXIT

required_files=(
  LICENSE LICENSE-APACHE NOTICE README.md .gitignore .gitleaksignore
  go-gost/LICENSE go-gost/x/LICENSE vite-frontend/LICENSE
  docs/dx/README.md docs/dx/architecture.md docs/dx/development.md
  docs/dx/database-migrations.md docs/dx/deployment.md
  docs/dx/design-decisions.md docs/dx/known-limitations.md
  docs/dx/project-history.md docs/dx/provenance.md
  docs/dx/release-process.md docs/dx/handover.md docs/dx/native-installer.md
  docs/dx/commercial-license-boundary.md
  docs/dx/fvdx-remote-rc1.md
  deploy/examples/panel.env.example deploy/examples/flvx-paneld.service.example
  deploy/examples/Caddyfile.example deploy/installer/install-fvdx.sh
  scripts/build-fvdx-release.sh scripts/check-fvdx-installer.sh
)

missing=()
for path in "${required_files[@]}"; do
  [[ -s "$path" ]] || missing+=("$path")
done
if ((${#missing[@]} == 0)); then
  pass "required licenses, documentation, and examples are present"
else
  fail "missing required files: ${missing[*]}"
fi

if [[ -z $(git status --porcelain=v1) ]]; then
  pass "worktree is clean"
else
  fail "worktree is not clean"
fi

run "patch whitespace check" git diff --check HEAD

forbidden_report="$tmp_dir/forbidden-tracked-files.txt"
while IFS= read -r path; do
  lower=${path,,}
  case "$lower" in
    vite-frontend/.env.development|vite-frontend/.env.production)
      continue
      ;;
    *.db|*.sqlite|*.sqlite3|*.pem|*.key|*.p12|*.pfx|*.pcap|*.pcapng|*.log|*/.env|*/.env.*|.env|.env.*|*/auth.json|*/device.id|*/gost.json|*/agent-state*|*/agent_state*|go-backend/cmd/paneld/paneld|test-results/*)
      printf '%s\n' "$path" >>"$forbidden_report"
      ;;
  esac
done < <(git ls-files)

if [[ -s "$forbidden_report" ]]; then
  fail "forbidden runtime/secret/build files are tracked (see $forbidden_report during this run)"
  sed -n '1,100p' "$forbidden_report" >&2
else
  pass "no forbidden runtime/secret/build paths are tracked"
fi

lfs_report="$tmp_dir/lfs-pointers.txt"
while IFS= read -r path; do
  if [[ -f "$path" ]] && head -n 1 "$path" 2>/dev/null | grep -qx 'version https://git-lfs.github.com/spec/v1'; then
    printf '%s\n' "$path" >>"$lfs_report"
  fi
done < <(git ls-files)
if [[ -s "$lfs_report" ]]; then
  if command -v git-lfs >/dev/null 2>&1; then
    run "Git LFS object integrity" git lfs fsck
  else
    fail "Git LFS pointers exist but git-lfs is not installed"
  fi
else
  pass "no Git LFS pointers are tracked"
fi

for tool in go node pnpm gitleaks; do
  require_command "$tool" || true
done

run "FV-DX native installer static contract" scripts/check-fvdx-installer.sh

commercial_files=(
  go-backend/internal/license/keygen.go
  go-backend/internal/http/handler/license_validation.go
  go-backend/internal/http/handler/jobs.go
  go-backend/internal/store/repo/config_policy.go
  vite-frontend/src/config/site.ts
  vite-frontend/src/pages/config.tsx
)
commercial_boundary_ok=true
for path in "${commercial_files[@]}"; do
  if [[ $(git rev-parse "$CLEAN_BASELINE_COMMIT:$path" 2>/dev/null || true) != \
        $(git rev-parse "$REPLAYED_DX_TIP:$path" 2>/dev/null || true) ]] ||
      [[ $(git rev-parse "$REPLAYED_DX_TIP:$path" 2>/dev/null || true) != \
        $(git rev-parse "HEAD:$path" 2>/dev/null || true) ]] ||
      [[ $(git rev-parse "$REPLAYED_DX_TIP:$path" 2>/dev/null || true) != \
        $(git hash-object "$path" 2>/dev/null || true) ]]; then
    commercial_boundary_ok=false
  fi
done
if {
    git diff --unified=0 "$CLEAN_BASELINE_COMMIT..HEAD" -- \
      go-backend/internal/http/handler/handler.go
    git diff --unified=0 -- go-backend/internal/http/handler/handler.go
  } | grep -E '^[+-][^+-].*(license|activation|commercial|is_commercial|授权|激活|商业)' >/dev/null; then
  commercial_boundary_ok=false
fi
if grep -E '(is_commercial|license_key|license_machine_id|KEYGEN_ACCOUNT_ID)=' \
    deploy/installer/install-fvdx.sh >/dev/null; then
  commercial_boundary_ok=false
fi
if $commercial_boundary_ok; then
  pass "commercial-license implementation and installer boundary"
else
  fail "commercial-license implementation or installer boundary changed"
fi

if command -v gitleaks >/dev/null 2>&1; then
	current_secret_report="$tmp_dir/gitleaks-current.json"
	if gitleaks dir --no-banner --redact --report-format json \
			--report-path "$current_secret_report" .; then
		pass "gitleaks scan of current worktree"
	else
		count=unknown
		[[ -s "$current_secret_report" ]] && count=$(jq 'length' "$current_secret_report" 2>/dev/null || echo unknown)
		fail "gitleaks reported $count non-allowlisted current-tree finding(s)"
		if command -v jq >/dev/null 2>&1 && [[ -s "$current_secret_report" ]]; then
			jq -r '.[] | [.RuleID,.File,(.StartLine|tostring)] | @tsv' \
				"$current_secret_report" | sort -u >&2
		fi
	fi

	secret_report="$tmp_dir/gitleaks.json"
	if gitleaks git --no-banner --redact --report-format json \
			--report-path "$secret_report" "$repo_root"; then
    pass "gitleaks scan of reachable Git history"
  else
    count=unknown
    [[ -s "$secret_report" ]] && count=$(jq 'length' "$secret_report" 2>/dev/null || echo unknown)
    fail "gitleaks reported $count non-allowlisted historical finding(s)"
    if command -v jq >/dev/null 2>&1 && [[ -s "$secret_report" ]]; then
      jq -r '.[] | [.RuleID,.File,(.StartLine|tostring),(.Commit[0:12])] | @tsv' \
        "$secret_report" | sort -u >&2
		fi
	fi

	known_sensitive_commits=(
		9fa968d07cd6c7bc55b479a81c201f5e57d051be
		47696e928b14650e009def17dcb13320ec932a8c
	)
	known_sensitive_reachable=()
	for commit in "${known_sensitive_commits[@]}"; do
		if git rev-list --all | grep -Fqx "$commit"; then
			known_sensitive_reachable+=("$commit")
		fi
	done
	if ((${#known_sensitive_reachable[@]} == 0)); then
		pass "known sensitive upstream commits are not reachable"
	else
		fail "known sensitive upstream commits are reachable: ${known_sensitive_reachable[*]}"
	fi

	self_test_dir="$tmp_dir/gitleaks-self-test"
	mkdir -p "$self_test_dir"
	printf '%s%s%s\n' 'AK' 'IA' 'ABCDEFGHIJKLMNOP' >"$self_test_dir/fixture.txt"
	if gitleaks dir --no-banner --redact "$self_test_dir" >/dev/null 2>&1; then
		fail "gitleaks self-test did not detect the synthetic secret"
	else
		pass "gitleaks self-test rejects a synthetic secret"
	fi
	find "$self_test_dir" -type f -delete
	if gitleaks dir --no-banner --redact "$self_test_dir" >/dev/null 2>&1; then
		pass "gitleaks self-test recovers after fixture removal"
	else
		fail "gitleaks self-test still fails after fixture removal"
	fi
fi

provenance_ok=true
mapfile -t root_commits < <(git rev-list --max-parents=0 HEAD)
if ((${#root_commits[@]} != 1)) || [[ "${root_commits[0]:-}" != "$CLEAN_BASELINE_COMMIT" ]]; then
	provenance_ok=false
fi
if [[ $(git rev-parse "$CLEAN_BASELINE_COMMIT^{tree}" 2>/dev/null || true) != "$UPSTREAM_BASE_TREE" ]]; then
	provenance_ok=false
fi
if ! git merge-base --is-ancestor "$REPLAYED_DX_TIP" HEAD 2>/dev/null; then
	provenance_ok=false
fi
if [[ $(git rev-list --count "$CLEAN_BASELINE_COMMIT..$REPLAYED_DX_TIP" 2>/dev/null || true) != "$REPLAYED_DX_COUNT" ]]; then
	provenance_ok=false
fi
while IFS=$'\t' read -r new_commit original_commit; do
	if [[ -z "$new_commit" && -z "$original_commit" ]]; then
		continue
	fi
	if [[ -z "$original_commit" ]] ||
			! grep -Fq "$new_commit" docs/dx/provenance.md ||
			! grep -Fq "$original_commit" docs/dx/provenance.md; then
		provenance_ok=false
	fi
done < <(git log --reverse --format='%H%x09%(trailers:key=Original-Commit,valueonly)' \
	"$CLEAN_BASELINE_COMMIT..$REPLAYED_DX_TIP")
if ! grep -Fq "$UPSTREAM_BASE_COMMIT" docs/dx/provenance.md ||
		! grep -Fq "$UPSTREAM_BASE_TREE" docs/dx/provenance.md; then
	provenance_ok=false
fi
if $provenance_ok; then
	pass "independent-history provenance and DX replay mapping"
else
	fail "independent-history provenance or DX replay mapping is invalid"
fi

if command -v go >/dev/null 2>&1; then
  go_version=$(go env GOVERSION 2>/dev/null || true)
  go_number=${go_version#go}
  go_floor=$(printf '%s\n%s\n' 1.26.10 "$go_number" | sort -V | head -n 1)
  if [[ "$go_floor" == "1.26.10" &&
        "$go_number" != "1.27.0" && "$go_number" != "1.27.1" &&
        "$go_number" != "1.27.2" ]]; then
    pass "supported Go version: $go_version"
  else
    fail "unsupported Go version: ${go_version:-unknown}; require patched Go 1.26.10+"
  fi

	if git cat-file -e "$CLEAN_BASELINE_COMMIT^{commit}" 2>/dev/null; then
		mapfile -t changed_go_files < <(
			{
				git diff --name-only "$CLEAN_BASELINE_COMMIT"..HEAD -- '*.go'
				git diff --name-only -- '*.go'
				git diff --cached --name-only -- '*.go'
      } | sort -u
    )
    if ((${#changed_go_files[@]} == 0)); then
      pass "gofmt check (no downstream Go changes)"
    else
      gofmt_output=$(gofmt -l "${changed_go_files[@]}" 2>&1)
      if [[ -z "$gofmt_output" ]]; then
        pass "gofmt check for downstream Go changes"
      else
        printf '%s\n' "$gofmt_output" >&2
        fail "gofmt check for downstream Go changes"
			fi
		fi
	else
		fail "clean baseline commit is missing"
	fi
  run "backend migration tests repeated 3 times" bash -c \
    'cd go-backend && TZ=UTC go test ./internal/store/repo -run "TestMigrateSchema" -count=3'
  run "backend tests" bash -c 'cd go-backend && TZ=UTC go test ./...'
  run "backend build" bash -c \
    'cd go-backend && go build -o "$1/paneld" ./cmd/paneld' _ "$tmp_dir"
  run "go-gost/x tests" bash -c 'cd go-gost/x && go test ./...'
  run "Agent tests" bash -c 'cd go-gost && go test ./...'
  run "Agent build" bash -c \
    'cd go-gost && CGO_ENABLED=0 go build -o "$1/gost" .' _ "$tmp_dir"
fi

if command -v node >/dev/null 2>&1 && command -v pnpm >/dev/null 2>&1; then
  node_version=$(node --version 2>/dev/null || true)
  pnpm_version=$(pnpm --version 2>/dev/null || true)
  [[ "$node_version" == "v22.23.4" ]] && pass "pinned Node version: $node_version" || \
    fail "Node version is $node_version; publication uses v22.23.4"
  [[ "$pnpm_version" == "10.28.1" ]] && pass "pinned pnpm version: $pnpm_version" || \
    fail "pnpm version is $pnpm_version; publication uses 10.28.1"

  run "frontend dependency lock" bash -c \
    'cd vite-frontend && pnpm install --frozen-lockfile'
  run "frontend lint" bash -c 'cd vite-frontend && pnpm exec eslint .'
  run "frontend build" bash -c \
    'cd vite-frontend && DX_FV_BUILD="$(git rev-parse HEAD)" pnpm run build'
  if [[ -s vite-frontend/dist/index.html ]] &&
      find vite-frontend/dist/assets -maxdepth 1 -type f -name '*.js' -print -quit 2>/dev/null | grep -q .; then
    pass "frontend artifact contains index.html and hashed JavaScript"
  else
    fail "frontend artifact is incomplete"
  fi

  gate_version="gate-$(git rev-parse --short=12 HEAD)"
  gate_output="$tmp_dir/native-release"
  if scripts/build-fvdx-release.sh "$gate_version" "$gate_output" >/dev/null &&
      (cd "$gate_output/$gate_version" && sha256sum --strict -c manifest.sha256 >/dev/null) &&
      [[ -x "$gate_output/install.sh" ]] &&
      [[ $(wc -l < "$gate_output/$gate_version/manifest.sha256") -eq 4 ]]; then
    pass "native release artifacts and SHA256 manifest"
  else
    fail "native release artifacts or SHA256 manifest"
  fi
fi

printf '\nRelease-readiness checks: %d total, %d failed\n' "$checks" "$failures"
if ((failures > 0)); then
  exit 1
fi
