# FV-DX repository instructions

FV-DX is a downstream FLVX traffic-forwarding panel: a Go control plane, a
React/Vite operator UI, and a Go forwarding Agent. The frozen stable baseline is
`v1.0.0` at commit `f25dcb4576eea367afb0274f4b21b6c02c735984`.
This branch develops `v1.0.1` as a maintenance, documentation, handoff, and
installer release. Schema 8 is the current application schema.

## Read before changing anything

1. `docs/PROJECT_STATUS.md`
2. `docs/dx/README.md` and `docs/dx/architecture.md`
3. `docs/dx/design-decisions.md` and `docs/dx/known-limitations.md`
4. The relevant file under `docs/development-log/`
5. The relevant project Skill under `.agents/skills/`
6. The nearest nested `AGENTS.md` for the directory being edited

Use `docs/architecture/` for diagrams, `docs/decisions/` for durable decisions,
and `docs/verification/` for acceptance evidence. Evidence labels are defined
in `docs/development-log/README.md`.

## Architecture

| Path | Responsibility | Entry point |
| --- | --- | --- |
| `go-backend/` | Panel API, storage, and orchestration | `cmd/paneld/main.go` |
| `vite-frontend/` | React/Vite operator UI | `src/main.tsx` |
| `go-gost/` | FLVX forwarding Agent | `main.go` |
| `go-gost/x/` | Local go-gost/x runtime fork | Go module |
| `deploy/installer/` | Native Debian installer | `install-fvdx.sh` |

BusinessLine is the user-facing aggregate. It maps to Forward, ForwardPort,
Tunnel, and ChainTunnel runtime records. Frontsea Direct owns two hop-local
Forward paths and automatically allocates an IX port. QIX lines share an
existing Tunnel that no individual BusinessLine owns. Protocol switching adds
or removes only the UDP service and must preserve the TCP service identity.

## Project Skills

Repository Skills are automatically discovered from `.agents/skills/`. Use
`/skills` to inspect them or invoke one explicitly as `$skill-name`.

- `flvx-project-onboarding`: cold start and task routing
- `flvx-architecture`: component and resource ownership
- `business-line-development`: aggregate creation/deletion and API work
- `frontsea-direct`: two-hop allocation, conflicts, and rollback
- `qix-shared-tunnel`: shared-Tunnel lifecycle and isolation
- `protocol-switching`: TCP-only/TCP+UDP transitions
- `database-migrations`: schema and backup/restore discipline
- `agent-lifecycle`: registration, commands, recovery, and online status
- `frontend-ui`: routes, grouping, cache cleanup, and atomic publishing
- `native-installer`: public curl installer and native deployment
- `testing-debugging`: unit, integration, data-plane, and stability checks
- `release-management`: versions, immutable assets, tags, and release gates
- `commercial-license-boundary`: protected authorization behavior
- `security-and-secrets`: public-repository and credential safety
- `flvx-api`: read-only-first API investigation and authenticated operations

Each Skill records its source and license in `.agents/skills/README.md`.

## Build and test

Required versions are recorded in module files and `docs/dx/development.md`.
The development host may define a stale global `GOROOT`; unset it before using
the pinned Go binary. Start with:

```bash
bash scripts/bootstrap-dev.sh --check
unset GOROOT
(cd go-backend && TZ=UTC go test ./...)
(cd go-backend && go build ./cmd/paneld)
(cd go-gost/x && go test ./...)
(cd go-gost && go test ./...)
(cd vite-frontend && pnpm install --frozen-lockfile)
(cd vite-frontend && pnpm exec eslint .)
(cd vite-frontend && pnpm run build)
bash scripts/check-fvdx-installer.sh
bash scripts/check-project-handoff.sh
```

`vite-frontend` has no unit-test runner. A lint/build PASS is not browser or
data-plane acceptance. The optional PostgreSQL contract suite must use a
disposable database, never DX or production.

## Database rules

- `schema_version` is authoritative; current version is 8.
- BusinessLine schema belongs to explicit migrations 0007 and 0008.
- Never add BusinessLine to broad startup AutoMigrate.
- Add a numbered, transactional migration for any schema change. Update the
  version in the same transaction and test upgrade, repeated startup, failure
  rollback, and representative data preservation.
- There is no down-migration. Application rollback requires a validated matching
  database backup.
- Never edit a live SQLite database directly to implement a feature.

## Release rules

- `v1.0.0` and `fvdx-remote-rc1` are immutable history. Never move tags,
  replace assets, edit notes, or bypass their protection.
- Do not rewrite the clean publication history or re-import unaudited upstream
  history. Research upstream in a separate clone and import reviewed patches or
  use a reviewed clean rebaseline.
- `v1.0.1` may reuse the verified v1.0.0 application binaries only when byte
  identity is proven. Metadata must distinguish the release commit from
  application build commit `f25dcb4576eea367afb0274f4b21b6c02c735984`.
- Run `scripts/check-release-readiness.sh` and every gate in the release Skill.
  Do not weaken assertions, skip failures, force-push, or use floating `latest`
  as an installer asset source.

## Security and commercial boundaries

Never commit credentials, tokens, databases, Agent state, `device.id`, private
keys, SSH configuration, real infrastructure inventory, packet captures, raw
Codex sessions, or production logs. Do not persist panel passwords in the
repository or recommend reusable plaintext credential files. Redact examples
and scan the current tree plus all reachable history.

Do not modify or bypass commercial authorization, license-server access,
machine binding, expiry checks, or paid feature policy. Protected paths include:

- `go-backend/internal/license/keygen.go`
- `go-backend/internal/http/handler/license_validation.go`
- `go-backend/internal/http/handler/jobs.go`
- `go-backend/internal/store/repo/config_policy.go`
- licensed frontend settings

The authorization service remains `https://api.keygen.sh/v1`. Installation and
DX testing must not change commercial state or fabricate a license response.

## Environment safety

Production is outside normal development scope. Do not connect to, deploy,
restart, migrate, or edit production without an explicit task naming the exact
resource and operation. Keep DX Agent identities, node IDs, tunnels, databases,
and acceptance evidence separate from production. A DX PASS is not production
acceptance.

External UDP loss is not automatically an FV defect. Compare a same-time direct
baseline and record unresolved attribution as `UNKNOWN` or `KNOWN LIMITATION`.
The accepted Shadowsocks evidence includes intermittent FV UDP loss and does not
prove zero-loss operation.

## Starting a feature

1. Establish status and evidence; do not rely on chat history.
2. Research the existing path and a mature upstream implementation before
   designing a replacement.
3. Identify ownership, persistence, runtime, rollback, and security boundaries.
4. Preserve stable identities and the existing architecture unless evidence
   requires a change.
5. Add focused tests before or with the implementation.
6. Update decisions, development history, verification, and relevant Skills.
7. Run proportional gates; never make a test pass by lowering assertions.

Nested `AGENTS.md` files add directory-specific rules and take precedence within
their scope.
