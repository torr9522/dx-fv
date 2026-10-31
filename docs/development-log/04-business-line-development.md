# BusinessLine development

## Requirement and original gap

One UI/API operation had to create, list, change, and delete a complete route.
FLVX primitives required multiple operator actions and did not carry aggregate
ownership or rollback semantics.

## Initial implementation and problems

Commit `eb1154c` introduced orchestration; `aee5e83` added the UI. Early
transactional reads could deadlock or escape the open transaction. `6ad0a65`
avoided the create deadlock and `b120e6a` kept QIX reads in the transaction.
Nullable IDs initially leaked inconsistent shapes; `bc6a65e` normalized API
serialization. All are `FIXED`.

## Final implementation

Requests validate ownership, path, ports, target, and protocol. Creation writes
BusinessLine and lower resources in a transaction, commits, then applies runtime
services with compensation on failure. Deletion removes owned Forward resources;
Frontsea removes line-local tunnels, while QIX preserves shared infrastructure.

## Files and impact

Primary files are `go-backend/internal/http/handler/business_line.go`,
`go-backend/internal/store/repo/repository_business_line.go`, the BusinessLine
model, route registration, and frontend BusinessLine pages. Schema 7 adds the
table and unique mappings. Agent changes were unnecessary because existing
commands are reused.

## Testing, results, limits, maintenance

Handler/repository tests cover validation, nullable responses, transactional
reads, expected-state updates, and rollback ordering. DX acceptance exercised
real creation/deletion. Keep repository access out of handlers, preserve stable
resource IDs, and add rollback tests for every new multi-step operation.

Sources: commits `eb1154c` through `bc6a65e`, tests, DX acceptance.
