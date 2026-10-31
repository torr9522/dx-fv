---
name: frontsea-direct
description: Work on FV-DX Frontsea Direct two-hop orchestration, automatic IX port selection, live bind conflict handling, and partial-failure rollback. Trigger on Frontsea paths or the 34700-34799 pool.
---

# Frontsea Direct

## Read first

Read `docs/development-log/05-frontsea-direct-development.md`,
`docs/dx/architecture.md`, and BusinessLine handler/repository tests.

## Workflow

1. Resolve explicit GZ and Frontsea node IDs for the environment.
2. Lock allocation, exclude `34700..34725`, persisted ForwardPort use, and
   cached live conflicts from `34700..34799`.
3. Create both hop resources transactionally.
4. Apply runtime services in order.
5. On bind conflict, clean up, remember the port, and retry; on other failures,
   compensate and report the exact failed hop.

## Never

Do not hard-code real node/address data, reuse production ports, silently widen
the pool, or leave one hop after a failed create/update.

## Tests and acceptance

Run BusinessLine handler/repository tests and real bounded TCP/UDP two-hop checks
in DX. Verify selected port uniqueness and no orphans after injected failure.
Common failure: checking database ports but not live Agent listeners.

## References

- `docs/verification/frontsea-direct.md`
- `go-backend/internal/http/handler/business_line.go`
