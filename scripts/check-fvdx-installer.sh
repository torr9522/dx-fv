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
  'https://github.com/torr9522/dx-fv/releases/download'
  'fvdx-remote-rc1'
  '/dev/tty'
  'sha256sum --strict -c'
  "length(\$1) != 64"
  'found ? 0 : 1'
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

[[ $(grep -Fc 'https://github.com/torr9522/dx-fv/releases/download' "$installer") -eq 1 ]] || {
  echo "installer must define the release base URL exactly once" >&2
  exit 1
}
[[ $(grep -Fc 'fvdx-remote-rc1' "$installer") -eq 1 ]] || {
  echo "installer must define the pinned release version exactly once" >&2
  exit 1
}

if grep -Eq 'handle [^{]+\{[^}]+\}' "$installer"; then
  echo "Caddy handle blocks must use portable multiline syntax" >&2
  exit 1
fi

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

for metadata_field in source_repository release_tag installer_path build_commit schema_version; do
  grep -Fq "\"$metadata_field\"" "$builder" || {
    echo "release metadata is missing: $metadata_field" >&2
    exit 1
  }
done
grep -Fq 'sha256sum --strict -c manifest.sha256' "$builder" || {
  echo "release builder must verify its generated manifest" >&2
  exit 1
}

echo "FV-DX installer static contract: PASS"
