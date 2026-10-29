# Database migrations

The current development schema version is 8. `schema_version` is read at panel
startup. Migrations are applied in order and startup stops on failure.

BusinessLine is deliberately excluded from the generic model AutoMigrate path:

- `0007_add_business_line` creates `business_line` and its indexes.
- `0008_add_business_line_protocol_mode` adds `protocol_mode` and sets existing
  rows to `tcp_udp`.

Both migrations run inside database transactions and update `schema_version` in
the same transaction. Migration tests verify upgrades, rollback on injected
failure, existing ID preservation, and repeat startup behavior.

## SQLite backup and restore

Stop writes before taking a file-level backup. For a systemd deployment:

```bash
sudo systemctl stop flvx-test-backend.service
sqlite3 /path/to/gost.db '.backup /secure/off-host/gost.db.backup'
sha256sum /secure/off-host/gost.db.backup
sudo systemctl start flvx-test-backend.service
```

Use environment-specific service names and paths. Do not stop production from a
development procedure. Keep backups outside Git and verify them with
`sqlite3 backup.db 'PRAGMA integrity_check;'` on an isolated host.

To restore, stop the target panel, retain a second copy of the current database,
restore the selected backup with ownership and mode preserved, run integrity
checks, then start the panel and inspect migration logs. Never restore a DX
database into production or vice versa.

## Upgrade discipline

1. Record current application commit and schema version.
2. Back up and validate the database.
3. Run migration tests against a copy of representative data.
4. Deploy the backend only during an approved maintenance operation.
5. Confirm the new schema and BusinessLine counts before accepting traffic.

There is no standalone down-migration. Rollback means restoring the application
and its matching pre-upgrade database backup. A source rollback without a
database plan is not a valid rollback.
