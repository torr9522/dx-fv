---
name: flvx-architecture
description: Explain or modify FV-DX component boundaries and resource ownership. Use for architecture reviews, data-flow questions, component diagrams, or cross-backend/frontend/Agent design work.
---

# FV-DX architecture

## Read first

Read `docs/dx/architecture.md`, `docs/architecture/README.md`,
`docs/dx/design-decisions.md`, and the nearest nested `AGENTS.md`.

## Source map

- Panel/orchestration: `go-backend/internal/http/handler`
- Persistence: `go-backend/internal/store`
- Agent: `go-gost`
- Runtime: `go-gost/x`
- UI: `vite-frontend/src`

## Workflow

Trace user intent through API, transaction, persisted ownership, Agent command,
and runtime service identity. State who owns cleanup and rollback. Prefer the
existing Forward/Tunnel runtime and stable service names over a parallel engine.
Update Mermaid diagrams and decision records when boundaries change.

## Never

Do not infer resource ownership from names or ports. Do not make a shared QIX
Tunnel line-owned or replace TCP runtime for a UDP-only change.

## Tests and acceptance

Run owning Go tests plus integration/browser gates for all crossed boundaries.
Acceptance requires explicit ownership, failure compensation, persistence, and
upgrade behavior. Common failure: describing the UI object without its lower
resource lifecycle.

## References

- `docs/development-log/03-initial-architecture.md`
- `docs/decisions/README.md`
