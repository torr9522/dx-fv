# Native Debian installer

FV-DX ships a native Debian 12 AMD64 installer. It does not use Docker and the
target host does not need Go, Node.js, pnpm, Git, or a compiler. Backend and
frontend artifacts are built on a trusted build host, published with a SHA256
manifest, and verified before the installer writes application state.

## Release layout

```bash
scripts/build-fvdx-release.sh VERSION OUTPUT_DIRECTORY
```

The command creates `OUTPUT_DIRECTORY/install.sh` and a version directory with
the backend, database initializer, frontend archive, release metadata, and
`manifest.sha256`. The metadata records the source commit and schema version.
Migrations are compiled into the backend; the initializer verifies schema 8.

All downloads use two settings. The checked-in defaults pin this remote
installation acceptance candidate:

```bash
FLVX_RELEASE_BASE_URL=https://github.com/torr9522/dx-fv/releases/download
FLVX_RELEASE_VERSION=fvdx-remote-rc1
```

The version is intentionally not `latest`: future releases cannot silently
change what this installer deploys. Never put a GitHub token or PAT in the
installation command.

## Installation behavior

```bash
curl -fsSL https://raw.githubusercontent.com/torr9522/dx-fv/main/deploy/installer/install-fvdx.sh | bash
```

Prompts are read from `/dev/tty`, so they work when the script is piped to Bash.
The installer asks for the domain, reverse-proxy mode, and whether generated
administrator credentials should be saved in a root-only file.

Managed mode installs Caddy, writes an independent site under
`/etc/caddy/sites-enabled/`, and adds only one import line to the existing
Caddyfile. External mode leaves Caddy and Nginx untouched, binds the backend to
`127.0.0.1:6365`, and writes an example under `/etc/flvx/`.

| Purpose | Path |
| --- | --- |
| Versioned backend | `/opt/flvx/releases/VERSION/` |
| Active backend | `/opt/flvx/current` |
| Versioned frontend | `/opt/flvx/frontend-releases/VERSION/` |
| Active frontend | `/opt/flvx/frontend-current` |
| Configuration | `/etc/flvx/` |
| SQLite database | `/var/lib/flvx/flvx.db` |
| Logs | `/var/log/flvx/` |

Backend and frontend activation use atomic symlink replacement. Hashed assets
receive immutable caching; `index.html`, SPA fallback routes, and cleanup
`sw.js` revalidate. The frontend does not register Workbox or an application
Service Worker and does not perform the upstream automatic update check.

The initializer refuses an existing database. It creates schema 8, replaces the
upstream seed credentials with a cryptographically random administrator name
and password, stores only a bcrypt hash, checks SQLite integrity, and exits.
Repeated installation is rejected before generating credentials or modifying
state.

## Operations

```bash
systemctl status flvx
systemctl restart flvx
journalctl -u flvx -f
```

The optional credential file is `/root/flvx-install-credentials.txt`, owned by
root with mode `0600`. It is operational state and must never be committed.

Local staging may use HTTP only with `FLVX_ALLOW_INSECURE_DOWNLOADS=1`.
Production release URLs must use HTTPS. Both use the same installer source.
Environment overrides remain available for controlled staging tests, but the
normal public command requires none.
