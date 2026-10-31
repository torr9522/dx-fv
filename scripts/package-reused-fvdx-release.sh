#!/usr/bin/env bash
set -Eeuo pipefail

readonly EXPECTED_APPLICATION_COMMIT=f25dcb4576eea367afb0274f4b21b6c02c735984

version=${1:-}
source_release=${2:-}
output_root=${3:-}
release_commit=${4:-}

[[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ && -d $source_release && -n $output_root && $release_commit =~ ^[0-9a-f]{40}$ ]] || {
  echo "usage: $0 VERSION VERIFIED_SOURCE_RELEASE OUTPUT_ROOT RELEASE_COMMIT" >&2
  exit 2
}

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
[[ $(git rev-parse "$release_commit^{commit}") == "$release_commit" ]] || {
  echo "release commit is not present in this repository: $release_commit" >&2
  exit 1
}

source_release=$(cd "$source_release" && pwd)
mkdir -p "$output_root"
output_root=$(cd "$output_root" && pwd)
release_dir="$output_root/$version"
[[ ! -e $release_dir ]] || { echo "release directory already exists: $release_dir" >&2; exit 1; }

required=(flvx-paneld-linux-amd64 flvx-init-linux-amd64 frontend.tar.gz release-metadata.json manifest.sha256)
for asset in "${required[@]}"; do
  [[ -f $source_release/$asset ]] || { echo "verified source asset missing: $asset" >&2; exit 1; }
done
(cd "$source_release" && sha256sum --strict -c manifest.sha256)

source_build_commit=$(jq -er '.application_build_commit // .build_commit' "$source_release/release-metadata.json")
[[ $source_build_commit == "$EXPECTED_APPLICATION_COMMIT" ]] || {
  echo "source application build commit mismatch" >&2
  exit 1
}

mkdir -m 0755 "$release_dir"
install -m 0755 "$source_release/flvx-paneld-linux-amd64" "$release_dir/flvx-paneld-linux-amd64"
install -m 0755 "$source_release/flvx-init-linux-amd64" "$release_dir/flvx-init-linux-amd64"
install -m 0644 "$source_release/frontend.tar.gz" "$release_dir/frontend.tar.gz"

backend_sha256=$(sha256sum "$release_dir/flvx-paneld-linux-amd64" | awk '{print $1}')
init_sha256=$(sha256sum "$release_dir/flvx-init-linux-amd64" | awk '{print $1}')
frontend_sha256=$(sha256sum "$release_dir/frontend.tar.gz" | awk '{print $1}')
release_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat >"$release_dir/release-metadata.json" <<EOF
{
  "product": "FV-DX",
  "artifact_version": "$version",
  "release_version": "$version",
  "release_tag": "$version",
  "source_repository": "https://github.com/torr9522/dx-fv",
  "installer_path": "deploy/installer/install-fvdx.sh",
  "release_commit": "$release_commit",
  "application_build_commit": "$EXPECTED_APPLICATION_COMMIT",
  "build_commit": "$EXPECTED_APPLICATION_COMMIT",
  "build_time": "$release_time",
  "platform": "linux-amd64",
  "schema_version": 8,
  "migrations": "embedded-in-backend",
  "reused_from_release": "v1.0.0",
  "asset_sha256": {
    "flvx-paneld-linux-amd64": "$backend_sha256",
    "flvx-init-linux-amd64": "$init_sha256",
    "frontend.tar.gz": "$frontend_sha256"
  }
}
EOF

(
  cd "$release_dir"
  sha256sum flvx-paneld-linux-amd64 flvx-init-linux-amd64 frontend.tar.gz release-metadata.json >manifest.sha256
  sha256sum --strict -c manifest.sha256
)
chmod 0644 "$release_dir/release-metadata.json" "$release_dir/manifest.sha256"

for asset in flvx-paneld-linux-amd64 flvx-init-linux-amd64 frontend.tar.gz; do
  cmp -s "$source_release/$asset" "$release_dir/$asset" || {
    echo "reused asset changed during packaging: $asset" >&2
    exit 1
  }
done

printf 'RELEASE_VERSION=%s\n' "$version"
printf 'RELEASE_COMMIT=%s\n' "$release_commit"
printf 'APPLICATION_BUILD_COMMIT=%s\n' "$EXPECTED_APPLICATION_COMMIT"
printf 'RELEASE_DIR=%s\n' "$release_dir"
sha256sum "$release_dir"/*
