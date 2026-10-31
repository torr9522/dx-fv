# Development, build, and test

## Supported tools

- Go `1.26.10` or newer patched release. Do not use Go `1.27.0` through `1.27.2`.
- Node.js `22.23.4` as pinned by `.node-version`.
- pnpm `10.28.1` as pinned by `vite-frontend/package.json`.
- A C compiler is required for normal SQLite development builds when CGO is used.

On the existing DX host, pinned tools are installed under `/opt/toolchains/`.
On a new host, install equivalent versions through the normal trusted package or
toolchain channels; do not copy toolchain directories from production.
If the shell exports `GOROOT` for another Go release, unset it before running the
pinned Go binary; otherwise the compiler can load a mismatched standard library.

## Clone and dependency setup

```bash
git clone https://github.com/torr9522/dx-fv.git
cd dx-fv
bash scripts/bootstrap-dev.sh --check

cd vite-frontend
corepack enable
corepack prepare pnpm@10.28.1 --activate
pnpm install --frozen-lockfile
```

Go modules are downloaded by the standard Go commands. There are three modules:
`go-backend`, `go-gost`, and `go-gost/x`. `go-gost/go.mod` replaces
`github.com/go-gost/x` with the local `./x` module.

Project Codex Skills are repository-owned under `.agents/skills/`; do not copy
them to a production panel host. A new Codex session started from the repository
root reads `AGENTS.md` and discovers those Skills automatically.

## Build

```bash
(cd go-backend && go build -o /tmp/flvx-paneld ./cmd/paneld)
(cd go-gost/x && go test ./...)
(cd go-gost && CGO_ENABLED=0 go build -o /tmp/flvx-gost .)
(cd vite-frontend && DX_FV_BUILD="$(git rev-parse HEAD)" pnpm run build)
```

The frontend output is `vite-frontend/dist/`. Its `index.html` must reference
content-hashed files under `assets/`; build output is not committed.

## Tests

```bash
(cd go-backend && TZ=UTC go test ./...)
(cd go-backend && TZ=UTC go test ./internal/store/repo -run 'TestMigrateSchema' -count=1)
(cd go-gost/x && go test ./...)
(cd go-gost && go test ./...)
(cd vite-frontend && pnpm exec eslint .)
(cd vite-frontend && pnpm run build)
```

The frontend has no unit-test runner. Do not represent a successful build as
browser acceptance. Browser tests must separately cover desktop, 390 px mobile,
direct SPA routes, refreshes, BusinessLine creation/details, and the Rules view.

The optional PostgreSQL contract test requires a disposable database and
`FLVX_POSTGRES_TEST_DSN`. Never point it at DX or production.

## Local panel

Copy `deploy/examples/panel.env.example` outside the repository, replace all
placeholders, and start a disposable panel database:

```bash
set -a
. /path/to/local-panel.env
set +a
(cd go-backend && go run ./cmd/paneld)
```

Run the frontend separately with `pnpm run dev`. BusinessLine creation requires
registered test Agents and valid local IDs for the three BusinessLine environment
variables. An empty database can exercise login and migrations, but not live
Forward orchestration until test Agents and a test QIX Tunnel exist.

## Agent registration

Register Agents through the panel's normal node workflow. Store the generated
Agent secret only in that test Agent's protected environment/configuration. Do
not commit `device.id`, Agent state, `gost.json`, panel JWTs, or registration
commands containing secrets. Use distinct nodes and a distinct QIX Tunnel for DX.
