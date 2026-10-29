# Deployment and environment boundaries

This document describes environment boundaries; it is not authorization to
deploy. Every production change requires a separate task, fresh backups, and an
explicit approved scope. Public documentation deliberately uses placeholders
instead of operational hostnames, addresses, ports, IDs, or line names.

## Environment inventory

| Purpose | Panel | Host | Boundary |
|---|---|---|---|
| DX/test | `https://panel.test.example.com` | `TEST_PANEL_IP` | disposable acceptance data only |
| Production | `https://panel.example.com` | `PRODUCTION_ENDPOINT` | never use as a test target |

The QIX resources are distinct:

| Environment | Tunnel ID | Port | Rule |
|---|---:|---:|---|
| DX/test | `TEST_TUNNEL_ID` | `TEST_PORT` | test only |
| Production | `PRODUCTION_TUNNEL_ID` | `PRODUCTION_PORT` | shared production infrastructure |

Never copy IDs between environments. A database ID has meaning only in its own
database. Production protocol switching has not been accepted merely because the
same code passed DX tests.

## DX backend layout

The native installer creates `flvx.service`, runs the versioned backend through
`/opt/flvx/current`, and reads a protected environment file under `/etc/flvx/`.
Use `deploy/examples/` as a template on a new host; never copy a real environment
file into Git.

## Atomic frontend release

Build with a commit marker, stage into a new immutable release directory, verify,
then switch one symlink atomically:

```bash
commit=$(git rev-parse HEAD)
release_root=/opt/flvx/frontend-releases
release_dir="$release_root/$commit"

(cd vite-frontend && DX_FV_BUILD="$commit" pnpm run build)
install -d -m 0755 "$release_dir"
rsync -a --delete vite-frontend/dist/ "$release_dir/"
test -s "$release_dir/index.html"
test -n "$(find "$release_dir/assets" -maxdepth 1 -type f -name '*.js' -print -quit)"
ln -sfn "$release_dir" /opt/flvx/frontend-current.next
mv -Tf /opt/flvx/frontend-current.next /opt/flvx/frontend-current
```

Use a new directory or fail if the commit directory already exists in stricter
automation. Never `cp -r build/*` over the active directory. Keep the previous
release until browser verification is complete.

Caddy must serve `/assets/*` from `frontend-current` with immutable caching,
while `index.html`, SPA fallback routes, and `sw.js` must revalidate or use
no-cache. `deploy/examples/Caddyfile.example` shows the intended split.

The frontend writes `window.__DX_FV_BUILD__`, unregisters the legacy root-scope
Service Worker, and removes legacy Workbox precaches. `public/sw.js` is a
one-time cleanup worker for already controlled clients. Vite PWA registration is
not enabled. The footer no longer performs automatic upstream version requests,
so an upstream release must not trigger a popup or reload.

## Backend and Agent boundary

Backend deployment and database migration are separate from frontend deployment.
Frontend-only releases must not restart Agents or touch Forward, Tunnel,
ForwardPort, ports, or protocol modes. Agent binaries are deployed only by an
explicit Agent release task. A BusinessLine change must never manage the lifecycle
of a shared QIX Tunnel.
