# Database migration development

## Requirement and original gap

BusinessLine persistence needed predictable upgrades across SQLite and
PostgreSQL. Broad GORM AutoMigrate did not provide a sufficient versioned
contract for aggregate ownership and later protocol mode.

## Design and encountered failures

Commit `29a936d` introduced schema 7 and explicit migration 0007. Commit
`c995aad` introduced schema 8 and 0008. Early migration work exposed the risk of
partially created tables/columns with an advanced version. The final design runs
each migration and version update in one transaction. Failure injection tests
prove rollback. This issue is `FIXED`.

## Final implementation

0007 creates `business_line` and indexes. 0008 adds `protocol_mode` and
backfills existing rows to `tcp_udp`. BusinessLine remains excluded from generic
AutoMigrate. Startup reads `schema_version`, applies ordered missing migrations,
and stops on error.

## Data, tests, and operations

Tests verify legacy upgrade, ID preservation, repeat startup, default backfill,
and rollback for both migrations. Backup uses SQLite's `.backup` against a
quiesced copy, checksum and integrity validation, then isolated restore.
There is no down-migration: rollback requires the matching pre-upgrade backup.

## Maintenance warning

Never edit schema_version manually, bypass a numbered migration, or restore DX
data into production. New migrations must cover both supported databases and
must fail closed.

Sources: `29a936d`, `c995aad`, migration tests, recovery verification.
