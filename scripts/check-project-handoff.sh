#!/usr/bin/env bash
set -uo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "FAIL: run this script inside a Git worktree" >&2
  exit 1
}
cd "$repo_root" || exit 1

checks=0
failures=0
pass() { checks=$((checks + 1)); printf 'PASS: %s\n' "$*"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); printf 'FAIL: %s\n' "$*" >&2; }

required=(
  AGENTS.md README.md docs/PROJECT_STATUS.md
  docs/dx/README.md docs/dx/architecture.md docs/dx/database-migrations.md
  docs/dx/commercial-license-boundary.md docs/development-log/README.md
  docs/verification/README.md docs/architecture/README.md docs/decisions/README.md
  .agents/skills/README.md scripts/bootstrap-dev.sh scripts/package-reused-fvdx-release.sh
  deploy/installer/install-fvdx.sh scripts/check-fvdx-installer.sh
)
for n in $(seq -w 0 16); do
  case $n in
    00) f=00-project-origin.md;; 01) f=01-upstream-research.md;;
    02) f=02-license-and-commercial-boundary.md;; 03) f=03-initial-architecture.md;;
    04) f=04-business-line-development.md;; 05) f=05-frontsea-direct-development.md;;
    06) f=06-qix-shared-tunnel-development.md;; 07) f=07-database-migrations.md;;
    08) f=08-tcp-udp-protocol-switching.md;; 09) f=09-frontend-ui-development.md;;
    10) f=10-service-worker-cache-fix.md;; 11) f=11-native-installer-development.md;;
    12) f=12-testing-and-debugging.md;; 13) f=13-security-and-history-cleanup.md;;
    14) f=14-public-repository-publication.md;; 15) f=15-v1.0.0-stable-release.md;;
    16) f=16-v1.0.1-maintenance.md;;
  esac
  required+=("docs/development-log/$f")
done

missing=()
for path in "${required[@]}"; do [[ -s $path ]] || missing+=("$path"); done
if ((${#missing[@]} == 0)); then
  pass "required handoff files are present"
else
  fail "missing files: ${missing[*]}"
fi

installer_default="FLVX_RELEASE_VERSION=\"\${FLVX_RELEASE_VERSION:-v1.0.1}\""
if [[ $(grep -Fc "$installer_default" deploy/installer/install-fvdx.sh) -eq 1 ]] &&
   ! grep -Fq 'fvdx-remote-rc1' deploy/installer/install-fvdx.sh; then
  pass "installer defaults exactly to v1.0.1 and not the RC"
else
  fail "installer default version is not the v1.0.1 contract"
fi

stable_command='curl -fsSL https://raw.githubusercontent.com/torr9522/dx-fv/v1.0.1/deploy/installer/install-fvdx.sh | bash'
if grep -Fq "$stable_command" README.md && grep -Fq "$stable_command" docs/dx/native-installer.md; then
  pass "stable installation command is documented consistently"
else
  fail "README/native installer docs do not contain the fixed v1.0.1 command"
fi

skill_count=0
declare -A skill_names=()
skill_failed=false
while IFS= read -r skill_file; do
  skill_count=$((skill_count + 1))
  dir_name=$(basename "$(dirname "$skill_file")")
  name=$(sed -n '2s/^name:[[:space:]]*//p' "$skill_file")
  description=$(sed -n '3s/^description:[[:space:]]*//p' "$skill_file")
  if [[ -z $name || -z $description || $name != "$dir_name" ]]; then
    fail "invalid Skill frontmatter or directory name: $skill_file"
    skill_failed=true
  elif [[ -n ${skill_names[$name]:-} ]]; then
    fail "duplicate Skill name: $name"
    skill_failed=true
  else
    skill_names[$name]=1
  fi
  for section in '## Read first' '## Never' '## Tests and acceptance' '## References'; do
    grep -Fq "$section" "$skill_file" || { fail "$skill_file missing section: $section"; skill_failed=true; }
  done
  while IFS= read -r ref; do
    [[ -e $ref ]] || { fail "$skill_file references missing path: $ref"; skill_failed=true; }
  done < <(awk '
    /^## References/ { in_references=1; next }
    in_references && /^## / { exit }
    in_references && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/`.*/, "", line)
      print line
    }
  ' "$skill_file")
done < <(find .agents/skills -mindepth 2 -maxdepth 2 -name SKILL.md -type f | sort)
if [[ $skill_count -eq 15 && $skill_failed == false ]]; then
  pass "15 unique project Skills have required workflow sections and references"
elif [[ $skill_count -ne 15 ]]; then
  fail "expected 15 project Skills, found $skill_count"
fi

link_failed=false
while IFS=$'\t' read -r file target; do
  [[ -n $target ]] || continue
  case $target in http://*|https://*|mailto:*|'#'*) continue;; esac
  target=${target%%#*}
  [[ -n $target ]] || continue
  resolved=$(dirname "$file")/$target
  [[ -e $resolved ]] || { fail "$file has missing Markdown link: $target"; link_failed=true; }
done < <(perl -ne 'while (/\[[^]]*\]\(([^) ]+)(?:\s+"[^"]*")?\)/g) { print "$ARGV\t$1\n" }' \
  AGENTS.md README.md docs/PROJECT_STATUS.md docs/dx/*.md docs/development-log/*.md \
  docs/verification/*.md docs/architecture/*.md docs/decisions/*.md .agents/skills/*/SKILL.md)
$link_failed || pass "internal Markdown links resolve"

for phrase in 'api.keygen.sh/v1' 'commercial' 'production'; do
  if rg -qi "$phrase" AGENTS.md docs/dx/commercial-license-boundary.md .agents/skills/commercial-license-boundary/SKILL.md; then
    pass "protected handoff concept documented: $phrase"
  else
    fail "protected handoff concept missing: $phrase"
  fi
done

if rg -n --hidden -g '!skills/flvx-api/**' -g '!scripts/check-project-handoff.sh' \
  '(ghp_[A-Za-z0-9]{20,}|ss://[A-Za-z0-9+/=_-]{12,}|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY)' \
  AGENTS.md docs/PROJECT_STATUS.md docs/dx docs/development-log docs/verification \
  docs/architecture docs/decisions .agents scripts/bootstrap-dev.sh >/dev/null; then
  fail "credential/private-key pattern found in new handoff material"
else
  pass "no credential, Shadowsocks URI, or private-key pattern in handoff material"
fi

if bash -n scripts/bootstrap-dev.sh scripts/check-project-handoff.sh \
  scripts/package-reused-fvdx-release.sh deploy/installer/install-fvdx.sh; then
  pass "handoff and installer shell syntax"
else
  fail "shell syntax check"
fi

printf 'FV-DX project handoff: %d checks, %d failures\n' "$checks" "$failures"
((failures == 0))
