# Frontsea Direct development

## Requirement and original gap

Frontsea Direct needs a GZ entry, an automatically selected IX listener, and a
target, presented as one line. Manual intermediate ports caused collisions and
made cleanup error-prone.

## Design and failed behavior

The initial allocator used database state but a port can be occupied by a live
listener absent from ForwardPort. Such a bind failed after commit. Commit
`5fe1281` classified address-in-use failures and retried; `caab7d6` cached
discovered conflicts for the process lifetime. The runtime conflict gap is
`FIXED` for the supported single-panel topology.

## Final implementation

The pool is `34700..34799`; `34700..34725` are statically reserved. Selection
excludes reserved ports, persisted use on that node, and cached runtime conflicts.
The transaction creates two hop resources. Runtime applies both; partial failure
is compensated and an eligible bind conflict selects another candidate.

## Files, database, Agent, and tests

`business_line.go` owns allocation/orchestration;
`repository_business_line.go` supplies transactional used-port queries.
BusinessLine stores both Forward/tunnel IDs and the IX port. Existing Agent
UpdateService/DeleteService commands are used. Tests cover selection,
transaction behavior, and reverse rollback; DX acceptance covered real TCP/UDP.

## Limits and maintenance

The pool is intentionally fixed, conflict memory is process-local, and rollback
is compensating rather than distributed. Do not expand the pool or reservation
boundary without an explicit infrastructure decision and collision tests.

Sources: `5fe1281`, `caab7d6`, current code, Frontsea verification.
