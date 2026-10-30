#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

installer=deploy/installer/install-fvdx.sh
builder=scripts/build-fvdx-release.sh

bash -n "$installer" "$builder"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$installer" "$builder"
else
  echo "shellcheck is required for installer validation" >&2
  exit 1
fi

required_installer_patterns=(
  'FLVX_RELEASE_BASE_URL'
  'FLVX_RELEASE_VERSION'
  '/dev/tty'
  'sha256sum --strict -c'
  "length(\$1) != 64"
  'SERVER_ADDR=127.0.0.1:'
  'schema 8'
  'frontend-current.next'
  '检测到已有 FV 安装'
)
for pattern in "${required_installer_patterns[@]}"; do
  grep -Fq "$pattern" "$installer" || {
    echo "installer contract is missing: $pattern" >&2
    exit 1
  }
done

if grep -Eiq '(^|[^[:alnum:]_])(docker|docker-compose)([^[:alnum:]_]|$)' "$installer"; then
  echo "native installer must not invoke Docker" >&2
  exit 1
fi
if grep -Fq 'Sagit-chu/flvx' "$installer" || grep -Fq 'Sagit-chu/flux-panel' "$installer"; then
  echo "installer must not hard-code the upstream repository" >&2
  exit 1
fi

for artifact in flvx-paneld-linux-amd64 flvx-init-linux-amd64 frontend.tar.gz release-metadata.json; do
  grep -Fq "$artifact" "$installer" || {
    echo "installer does not require artifact: $artifact" >&2
    exit 1
  }
  grep -Fq "$artifact" "$builder" || {
    echo "release builder does not create artifact: $artifact" >&2
    exit 1
  }
done

echo "FV-DX installer static contract: PASS"
