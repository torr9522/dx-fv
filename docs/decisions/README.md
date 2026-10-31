# FV-DX decision register

| ID | Decision | Status | Primary evidence |
| --- | --- | --- | --- |
| D001 | BusinessLine is the normal UI aggregate; Rules is advanced detail | ACCEPTED | `docs/dx/design-decisions.md` |
| D002 | Infrastructure IDs are explicit environment configuration | ACCEPTED | `business_line.go` |
| D003 | Frontsea allocates from a bounded pool and retries live conflicts | ACCEPTED | commits `5fe1281`, `caab7d6` |
| D004 | QIX Tunnel is shared infrastructure, never line-owned | ACCEPTED | delete and protocol code |
| D005 | Protocol switches mutate UDP only and preserve TCP identity | ACCEPTED | commit `0908023` |
| D006 | BusinessLine schema uses numbered transactional migrations | ACCEPTED | migrations 0007/0008 |
| D007 | Frontend activation is an atomic symlink switch | ACCEPTED | native installer |
| D008 | No application Service Worker or official auto-update check | ACCEPTED | commit `3b213c2` |
| D009 | Public history starts from a clean source-tree-equivalent baseline | ACCEPTED | `docs/dx/provenance.md` |
| D010 | v1.0.1 reuses verified application binaries | ACCEPTED | release scope |

Do not reverse an accepted decision incidentally. A replacement needs evidence,
explicit ownership and rollback analysis, tests, and an update to this register.
Commercial authorization is a protected boundary, not a downstream decision.
