# FV-DX project status

Last reviewed for the `v1.0.1` maintenance branch.

| Item | Status |
| --- | --- |
| Public repository | `torr9522/dx-fv` |
| Frozen stable | `v1.0.0` |
| Stable source commit | `f25dcb4576eea367afb0274f4b21b6c02c735984` |
| Historical acceptance RC | `fvdx-remote-rc1` |
| Maintenance target | `v1.0.1` |
| Development branch | `v1.0.1-development` |
| Database schema | 8 |
| Upstream fixed point | FLVX `3.0.1-rc6`, commit `3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee` |

## v1.0.1 scope

The application behavior remains the verified v1.0.0 baseline. v1.0.1 changes
the native installer's default Release tag to `v1.0.1` and adds repository-owned
handoff material: `AGENTS.md`, project Skills, development history, architecture,
verification records, and development bootstrap/check scripts. No backend,
frontend, Agent, migration, or commercial-license behavior is intentionally
changed.

The v1.0.1 Release must reuse the v1.0.0 backend, initializer, and frontend
artifacts byte-for-byte. Its metadata distinguishes the v1.0.1 release commit
from application build commit `f25dcb4576eea367afb0274f4b21b6c02c735984`.

## Deployment status

The public installer is native Debian 12 AMD64/systemd with optional managed
Caddy. It does not require Docker or development toolchains. The stable command
is documented in the root README and pins both installer source and assets to
`v1.0.1`.

No repository evidence proves that a production environment runs v1.0.0 or
v1.0.1. Do not claim production deployment from DX acceptance records. This
maintenance task does not authorize any server deployment.

## Known limits

- BusinessLine supports `tcp_udp` and `tcp`, not UDP-only.
- The Frontsea automatic pool is fixed and process-local conflict memory is not
  a general distributed allocator.
- Protocol-update locking assumes one backend writer.
- Runtime rollback is compensating; a failed rollback requires inspection.
- Frontend unit tests are not configured; browser acceptance is separate.
- Real Shadowsocks UDP traversed FV with 70/80 packets received (12.5% loss) in
  the recorded run. Attribution remains `UNKNOWN`; zero-loss UDP is not claimed.

See `docs/dx/known-limitations.md` and `docs/verification/` for detail.

## Commercial boundary

The upstream license-validation system remains active, including
`https://api.keygen.sh/v1`, machine binding, expiry, and paid-feature policy.
FV-DX maintenance must not bypass, forge, or weaken it. The installer does not
change commercial authorization state.
