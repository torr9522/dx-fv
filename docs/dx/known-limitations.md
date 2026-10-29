# Known limitations

- BusinessLine supports only `tcp_udp` and `tcp`; UDP-only is intentionally absent.
- The Frontsea automatic pool is fixed at `34700..34799` with code-defined
  reservations. It is not a general multi-pool allocator.
- The protocol-update lock is process-local. The supported panel topology is a
  single backend instance unless locking is redesigned for multiple writers.
- Runtime rollback is compensating, not an Agent-side distributed transaction.
  A rollback failure is reported and requires operator inspection.
- BusinessLine infrastructure IDs are environment configuration. A fresh database
  needs test nodes and a test QIX Tunnel before orchestration can be exercised.
- Frontend unit tests are not configured. TypeScript, lint, build, route checks,
  and real-browser acceptance are separate gates.
- PostgreSQL contract coverage requires an explicitly supplied disposable DSN.
- The stale-PWA repair removes root-scope registrations and Workbox precaches for
  the current origin. Reintroducing `vite-plugin-pwa` registration would regress
  the accepted deployment model.
- The repository still contains upstream release/install machinery. DX production
  does not automatically follow upstream releases; release commands must target
  the downstream repository only after an approved publication process.
- Protocol switching is verified in DX but, at the publication audit boundary,
  is not deployed or accepted in production.
