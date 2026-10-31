---
name: flvx-api
description: Investigate or operate the FV-DX JSON API safely. Trigger on endpoint mapping, read-only panel queries, authenticated API automation, BusinessLine operations, response envelopes, or raw JWT header behavior.
---

# FV-DX API operations

## Read first

Read root `AGENTS.md`, the relevant handler, and only the needed reference under
`skills/flvx-api/references/`. Treat those references as inherited project
documentation and verify endpoints against current routes before use.

## Authentication and safety

Responses use `{code,msg,data,ts}`. Authenticated calls send the raw JWT in
`Authorization` with no `Bearer` prefix. Obtain credentials through a secure
interactive channel only when the user explicitly authorizes an operation. Keep
password/JWT in memory or a mode-0600 file under a private `/run` directory with
a cleanup trap. Never echo, log, persist in home dotfiles, or commit them.

## Workflow

1. Confirm the exact panel/environment and authorization scope.
2. Inspect current routes/request structs; begin with a read-only status/list.
3. Authenticate without shell xtrace and verify `code == 0`.
4. For mutation, record the target and expected rollback, then change the
   smallest resource through the formal API.
5. Verify via API and clean ephemeral credentials.

## Never

Do not modify production from a development task, write SQLite directly, copy
tokens between environments, return secrets in reports, or guess endpoints from
the legacy reference package.

## Tests and acceptance

Use disposable/DX scope, validate HTTP status and API code, and confirm persisted
plus runtime state. Common failure: adding `Bearer` or retaining credentials in
`~/.flvx/.env`.

## References

- `skills/flvx-api/references/auth.md`
- `skills/flvx-api/references/types.md`
- `docs/dx/architecture.md`
