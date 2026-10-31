---
name: database-migrations
description: Create, review, test, back up, or restore FV-DX database schema changes. Trigger on schema_version, migrations, BusinessLine tables, SQLite/PostgreSQL, backup, restore, or rollback.
---

# Database migrations

## Read first

Read `docs/dx/database-migrations.md`,
`docs/development-log/07-database-migrations.md`, and repository migration tests.

## Workflow

Record the current schema and validated backup. Add the next numbered migration
inside `migrateSchema`; make data/schema changes and schema_version update one
transaction. Support SQLite and PostgreSQL. Test legacy upgrade, representative
data, repeat startup, and injected failure rollback. Restore only to an isolated
copy before an approved live operation.

## Never

Do not put BusinessLine into generic AutoMigrate, edit schema_version manually,
write feature data directly into SQLite, invent a down-migration, or mix DX and
production backups.

## Tests and acceptance

Run `(cd go-backend && TZ=UTC go test ./internal/store/repo -run
'TestMigrateSchema' -count=1)` and then all backend tests. Verify integrity,
version, indexes, foreign mappings, and backup restore. Common failure: advancing
the version outside the transaction.

## References

- `docs/verification/database-recovery.md`
- `go-backend/internal/store/repo/repository.go`
