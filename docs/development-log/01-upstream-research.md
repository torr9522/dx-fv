# Upstream research

## Requirement and investigation

The downstream needed BusinessLine orchestration without duplicating mature
authentication, API envelopes, persistence, node commands, or forwarding
protocols. Research focused on the fixed FLVX source tree and its embedded
go-gost modules. There is no evidence that a separate third-party BusinessLine
implementation was copied; that detail is `UNKNOWN` and must not be invented.

## Adopted design

FV-DX reuses raw JWT `Authorization`, `{code,msg,data,ts}` responses, GORM
repositories, WebSocket Agent commands, and stable go-gost service names. New
work follows the existing handler/repository boundary and local `go-gost/x`
replace directive.

## Rejected patterns and maintenance rule

Hand-rolled forwarding, ad hoc SQL in handlers, name-based infrastructure
discovery, and blanket runtime replacement were rejected because they weaken
ownership and rollback guarantees. Before new work, inspect current source,
tests, and a maintained upstream implementation. Import only the smallest
reviewed change and retain licenses.

## Verification

Module boundaries and replace directives are in the three `go.mod` files.
Nested `AGENTS.md` files document local conventions. Build and test commands are
in `docs/dx/development.md`.

Sources: fixed upstream tree, current module files, nested instructions.
