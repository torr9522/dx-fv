---
name: business-line-development
description: Develop or review FV-DX BusinessLine APIs, models, repositories, UI, creation, deletion, and lower-resource mappings. Trigger on BusinessLine features, bugs, ownership, or orchestration changes.
---

# BusinessLine development

## Read first

Read `docs/development-log/04-business-line-development.md`,
`docs/dx/architecture.md`, `go-backend/AGENTS.md`, and
`go-backend/internal/http/handler/AGENTS.md`.

## Main source

- `go-backend/internal/http/handler/business_line.go`
- `go-backend/internal/store/repo/repository_business_line.go`
- BusinessLine model and frontend BusinessLine pages

## Workflow

Validate owner/path/entry/target/protocol; keep database reads/writes in the
repository; use one transaction for aggregate creation; commit before runtime;
compensate every applied runtime step on failure; delete only owned resources;
serialize nullable IDs as JSON numbers/null; update UI types and docs together.

## Never

Do not directly edit SQLite, access `repo.DB()` from handlers, cascade QIX line
deletion into the shared Tunnel, or infer path type from display strings.

## Tests and acceptance

Run handler/repository BusinessLine tests, migration tests, all backend tests,
frontend lint/build, and relevant real DX data-plane checks. Verify no orphan
Forward, ForwardPort, or line-local Tunnel. Common failure: a runtime rollback
path that leaves the database aggregate behind.

## References

- `docs/verification/frontsea-direct.md`
- `docs/verification/qix-shared-tunnel.md`
