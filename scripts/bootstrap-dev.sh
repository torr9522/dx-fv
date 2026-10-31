#!/usr/bin/env bash
set -Eeuo pipefail

readonly GO_VERSION=1.26.10
readonly NODE_VERSION=22.23.4
readonly PNPM_VERSION=10.28.1
readonly GITLEAKS_VERSION=8.30.1
readonly TOOLCHAIN_ROOT=/opt/toolchains

mode=${1:---check}
case "$mode" in
  --check|--install) ;;
  *) echo "usage: $0 [--check|--install]" >&2; exit 2 ;;
esac

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "FAIL: run this script inside the FV-DX Git worktree" >&2
  exit 1
}
cd "$repo_root"

failures=0
missing_packages=()
bootstrap_temp_dir=""

cleanup() {
  if [[ -n $bootstrap_temp_dir && -d $bootstrap_temp_dir ]]; then
    find "$bootstrap_temp_dir" -depth -delete 2>/dev/null || true
  fi
}
trap cleanup EXIT

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

version_of() {
  "$@" 2>/dev/null | head -1
}

find_go() {
  local candidate
  for candidate in "${FLVX_DEV_GO:-}" "$TOOLCHAIN_ROOT/go$GO_VERSION/bin/go" "$(command -v go 2>/dev/null || true)"; do
    [[ -n $candidate && -x $candidate ]] || continue
    if [[ $(env -u GOROOT "$candidate" env GOVERSION 2>/dev/null || true) == "go$GO_VERSION" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

find_node_dir() {
  local candidate node
  for candidate in "${FLVX_DEV_NODE_DIR:-}" "$TOOLCHAIN_ROOT/node-v$NODE_VERSION-linux-x64/bin"; do
    node="$candidate/node"
    [[ -x $node ]] || continue
    if [[ $($node --version 2>/dev/null || true) == "v$NODE_VERSION" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  node=$(command -v node 2>/dev/null || true)
  if [[ -n $node && $($node --version 2>/dev/null || true) == "v$NODE_VERSION" ]]; then
    dirname "$node"
    return 0
  fi
  return 1
}

find_gitleaks() {
  local candidate
  for candidate in "${FLVX_DEV_GITLEAKS:-}" "$TOOLCHAIN_ROOT/gitleaks-$GITLEAKS_VERSION/gitleaks" "$(command -v gitleaks 2>/dev/null || true)"; do
    [[ -n $candidate && -x $candidate ]] || continue
    if "$candidate" version 2>/dev/null | grep -Fq "$GITLEAKS_VERSION"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

check_os() {
  [[ -r /etc/os-release ]] || { fail "Linux distribution metadata missing"; return; }
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${ID_LIKE:-}" in
    debian:*|ubuntu:*|*:debian*) pass "Linux distribution: ${PRETTY_NAME:-$ID}" ;;
    *) fail "unsupported development distribution: ${PRETTY_NAME:-unknown} (Debian/Ubuntu required by bootstrap)" ;;
  esac
  if [[ $(uname -m) == x86_64 ]]; then
    pass "CPU architecture: x86_64"
  else
    fail "unsupported CPU architecture: $(uname -m)"
  fi
}

check_packages() {
  local command package
  while read -r command package; do
    if command -v "$command" >/dev/null 2>&1; then
      pass "system tool: $command"
    else
      fail "missing system tool: $command (package $package)"
      missing_packages+=("$package")
    fi
  done <<'EOF'
git git
curl curl
tar tar
xz xz-utils
sha256sum coreutils
gcc build-essential
make build-essential
sqlite3 sqlite3
jq jq
shellcheck shellcheck
python3 python3
EOF
}

check_toolchains() {
  local go_cmd node_dir pnpm_version gitleaks_cmd
  if go_cmd=$(find_go); then
    if [[ -n ${GOROOT:-} && ${GOROOT:-} != "$(env -u GOROOT "$go_cmd" env GOROOT)" ]]; then
      warn "GOROOT=$GOROOT overrides the pinned toolchain; build shells must unset GOROOT"
    fi
    pass "Go $GO_VERSION: $go_cmd"
  else
    fail "Go $GO_VERSION not found (other Go releases do not satisfy the pinned module toolchain)"
  fi
  if node_dir=$(find_node_dir); then
    pass "Node $NODE_VERSION: $node_dir/node"
    if pnpm_version=$(PATH="$node_dir:$PATH" corepack pnpm --version 2>/dev/null) && [[ $pnpm_version == "$PNPM_VERSION" ]]; then
      pass "pnpm $PNPM_VERSION through Corepack"
    else
      fail "pnpm $PNPM_VERSION is not available through the pinned Node Corepack"
    fi
  else
    fail "Node $NODE_VERSION not found"
  fi
  if gitleaks_cmd=$(find_gitleaks); then
    pass "gitleaks $GITLEAKS_VERSION: $gitleaks_cmd"
  else
    fail "gitleaks $GITLEAKS_VERSION not found"
  fi
}

print_plan() {
  cat <<EOF

Installation plan (no credentials are installed or copied):
  - apt packages: ${missing_packages[*]:-(none missing)}
  - Go $GO_VERSION from https://go.dev/dl/ into $TOOLCHAIN_ROOT/go$GO_VERSION
  - Node $NODE_VERSION from https://nodejs.org/dist/ into $TOOLCHAIN_ROOT/node-v$NODE_VERSION-linux-x64
  - pnpm $PNPM_VERSION through the pinned Node Corepack
  - gitleaks $GITLEAKS_VERSION from its official GitHub release into $TOOLCHAIN_ROOT/gitleaks-$GITLEAKS_VERSION

The script does not install Codex credentials, SSH keys, GitHub tokens, browser
cookies, panel credentials, or Agent tokens. It does not edit shell startup files.
EOF
}

download_verified() {
  local url=$1 checksum_url=$2 expected_name=$3 destination=$4 checksum_file
  checksum_file=$(mktemp)
  curl -fsSL "$checksum_url" -o "$checksum_file"
  curl -fsSL "$url" -o "$destination"
  grep -E "(^|[[:space:]])${expected_name//./\\.}$" "$checksum_file" | head -1 >"$checksum_file.selected"
  [[ -s $checksum_file.selected ]] || { rm -f "$checksum_file" "$checksum_file.selected"; return 1; }
  (cd "$(dirname "$destination")" && sha256sum -c "$checksum_file.selected")
  rm -f "$checksum_file" "$checksum_file.selected"
}

download_single_hash() {
  local url=$1 checksum_url=$2 expected_name=$3 destination=$4 expected
  expected=$(curl -fsSL "$checksum_url" | tr -d '[:space:]')
  [[ $expected =~ ^[0-9a-fA-F]{64}$ ]] || return 1
  curl -fsSL "$url" -o "$destination"
  printf '%s  %s\n' "$expected" "$expected_name" |
    (cd "$(dirname "$destination")" && sha256sum -c -)
}

install_toolchains() {
  local tmp go_archive node_archive gl_archive node_dir
  bootstrap_temp_dir=$(mktemp -d /tmp/fvdx-bootstrap.XXXXXX)
  tmp=$bootstrap_temp_dir
  install -d -m 0755 "$TOOLCHAIN_ROOT"

  if ! find_go >/dev/null; then
    go_archive="go$GO_VERSION.linux-amd64.tar.gz"
    download_single_hash "https://go.dev/dl/$go_archive" "https://go.dev/dl/$go_archive.sha256" "$go_archive" "$tmp/$go_archive" || {
      echo "FAIL: unable to verify Go archive from official metadata" >&2; return 1;
    }
    tar -xzf "$tmp/$go_archive" -C "$tmp"
    mv "$tmp/go" "$TOOLCHAIN_ROOT/go$GO_VERSION"
  fi

  if ! find_node_dir >/dev/null; then
    node_archive="node-v$NODE_VERSION-linux-x64.tar.xz"
    download_verified "https://nodejs.org/dist/v$NODE_VERSION/$node_archive" \
      "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt" "$node_archive" "$tmp/$node_archive"
    tar -xJf "$tmp/$node_archive" -C "$TOOLCHAIN_ROOT"
  fi
  node_dir=$(find_node_dir)
  PATH="$node_dir:$PATH" corepack install --global "pnpm@$PNPM_VERSION"

  if ! find_gitleaks >/dev/null; then
    gl_archive="gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_checksums.txt" -o "$tmp/checksums.txt"
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/$gl_archive" -o "$tmp/$gl_archive"
    (cd "$tmp" && grep -F "  $gl_archive" checksums.txt | sha256sum -c -)
    install -d -m 0755 "$TOOLCHAIN_ROOT/gitleaks-$GITLEAKS_VERSION"
    tar -xzf "$tmp/$gl_archive" -C "$TOOLCHAIN_ROOT/gitleaks-$GITLEAKS_VERSION" gitleaks
    chmod 0755 "$TOOLCHAIN_ROOT/gitleaks-$GITLEAKS_VERSION/gitleaks"
  fi
}

run_check() {
  failures=0
  missing_packages=()
  check_os
  check_packages
  check_toolchains
  if ((failures == 0)); then
    cat <<EOF
PASS  FV-DX development prerequisites are available.
Use these pinned tools for build commands:
  unset GOROOT
  export PATH="$TOOLCHAIN_ROOT/go$GO_VERSION/bin:$TOOLCHAIN_ROOT/node-v$NODE_VERSION-linux-x64/bin:$TOOLCHAIN_ROOT/gitleaks-$GITLEAKS_VERSION:\$PATH"
EOF
    return 0
  fi
  printf 'FAIL  %d prerequisite check(s) failed.\n' "$failures" >&2
  return 1
}

if [[ $mode == --check ]]; then
  run_check
  exit
fi

run_check || true
print_plan
[[ -r /dev/tty && -w /dev/tty ]] || { echo "FAIL: --install requires an interactive TTY" >&2; exit 1; }
printf 'Proceed with this development-machine installation? [y/N] ' >/dev/tty
read -r answer </dev/tty
[[ $answer == y || $answer == Y ]] || { echo "Installation cancelled."; exit 0; }

if [[ $EUID -ne 0 ]]; then
  echo "FAIL: --install modifies apt and $TOOLCHAIN_ROOT; rerun the same command with sudo" >&2
  exit 1
fi
if ((${#missing_packages[@]} > 0)); then
  apt-get update
  apt-get install -y --no-install-recommends "${missing_packages[@]}"
fi
install_toolchains
run_check
