#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

version=${1:-}
output_dir=${2:-}
[[ $version =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || {
  echo "usage: $0 VERSION OUTPUT_DIR" >&2
  exit 2
}
[[ -n $output_dir ]] || {
  echo "usage: $0 VERSION OUTPUT_DIR" >&2
  exit 2
}
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
release_dir="$output_dir/$version"
[[ ! -e $release_dir ]] || {
  echo "release directory already exists: $release_dir" >&2
  exit 1
}

build_dir=$(mktemp -d /tmp/flvx-release-build.XXXXXX)
trap 'find "$build_dir" -depth -delete 2>/dev/null || true' EXIT
mkdir -p "$release_dir"

build_commit=$(git rev-parse HEAD)
build_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

(
  cd go-backend
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -trimpath -ldflags="-s -w -X 'go-backend/internal/license.AccountID=${KEYGEN_ACCOUNT_ID:-}'" \
    -o "$release_dir/flvx-paneld-linux-amd64" ./cmd/paneld
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -trimpath -ldflags='-s -w' \
    -o "$release_dir/flvx-init-linux-amd64" ./cmd/flvx-init
)

(
  cd vite-frontend
  pnpm install --frozen-lockfile
  DX_FV_BUILD="$build_commit" pnpm run build
  test -s dist/index.html
  find dist/assets -maxdepth 1 -type f -name '*.js' -print -quit | grep -q .
  tar -czf "$release_dir/frontend.tar.gz" -C dist .
)

backend_sha256=$(sha256sum "$release_dir/flvx-paneld-linux-amd64" | awk '{print $1}')
init_sha256=$(sha256sum "$release_dir/flvx-init-linux-amd64" | awk '{print $1}')
frontend_sha256=$(sha256sum "$release_dir/frontend.tar.gz" | awk '{print $1}')

cat > "$release_dir/release-metadata.json" <<EOF
{
  "product": "FV-DX",
  "artifact_version": "$version",
  "release_version": "$version",
  "release_tag": "$version",
  "source_repository": "https://github.com/torr9522/dx-fv",
  "installer_path": "deploy/installer/install-fvdx.sh",
  "release_commit": "$build_commit",
  "application_build_commit": "$build_commit",
  "build_commit": "$build_commit",
  "build_time": "$build_time",
  "platform": "linux-amd64",
  "schema_version": 8,
  "migrations": "embedded-in-backend",
  "asset_sha256": {
    "flvx-paneld-linux-amd64": "$backend_sha256",
    "flvx-init-linux-amd64": "$init_sha256",
    "frontend.tar.gz": "$frontend_sha256"
  }
}
EOF

(
  cd "$release_dir"
  sha256sum \
    flvx-paneld-linux-amd64 \
    flvx-init-linux-amd64 \
    frontend.tar.gz \
    release-metadata.json > manifest.sha256
  sha256sum --strict -c manifest.sha256
)
chmod 0755 "$release_dir/flvx-paneld-linux-amd64" "$release_dir/flvx-init-linux-amd64"
chmod 0644 "$release_dir/frontend.tar.gz" "$release_dir/release-metadata.json" "$release_dir/manifest.sha256"
install -m 0755 deploy/installer/install-fvdx.sh "$output_dir/install.sh"

printf 'ARTIFACT_VERSION=%s\n' "$version"
printf 'BUILD_COMMIT=%s\n' "$build_commit"
printf 'BUILD_TIME=%s\n' "$build_time"
printf 'RELEASE_DIR=%s\n' "$release_dir"
sha256sum "$output_dir/install.sh" "$release_dir"/*
