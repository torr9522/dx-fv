# FV-DX development log

This directory reconstructs the engineering history from the clean Git history,
source, tests, existing DX documentation, immutable release records, and
project-owner acceptance facts. It is a curated technical record, not a copy of
chat logs or Codex session data.

Evidence labels:

- `VERIFIED`: directly supported by source, tests, Git objects, or an immutable
  public Release.
- `ACCEPTANCE`: reported by the project-owner acceptance process; sensitive raw
  operational artifacts are deliberately absent.
- `FIXED`: a verified historical defect with an implemented correction.
- `KNOWN LIMITATION`: a confirmed constraint that remains.
- `UNKNOWN`: evidence is insufficient to attribute a cause.

Commit IDs are abbreviated only when unambiguous in this repository. The clean
publication baseline and complete replay mapping are in `docs/dx/provenance.md`.
Do not add unverifiable narrative to fill a gap; mark it `UNKNOWN` instead.

## Timeline

1. `00-project-origin.md`
2. `01-upstream-research.md`
3. `02-license-and-commercial-boundary.md`
4. `03-initial-architecture.md`
5. `04-business-line-development.md`
6. `05-frontsea-direct-development.md`
7. `06-qix-shared-tunnel-development.md`
8. `07-database-migrations.md`
9. `08-tcp-udp-protocol-switching.md`
10. `09-frontend-ui-development.md`
11. `10-service-worker-cache-fix.md`
12. `11-native-installer-development.md`
13. `12-testing-and-debugging.md`
14. `13-security-and-history-cleanup.md`
15. `14-public-repository-publication.md`
16. `15-v1.0.0-stable-release.md`
17. `16-v1.0.1-maintenance.md`
