---
name: qix-shared-tunnel
description: Work on QIX BusinessLines that share an existing FV-DX Tunnel. Trigger on QIX creation, deletion, protocol changes, isolation, or shared-Tunnel lifecycle questions.
---

# QIX shared Tunnel

## Read first

Read `docs/development-log/06-qix-shared-tunnel-development.md`,
`docs/verification/qix-shared-tunnel.md`, and BusinessLine tests.

## Workflow

Resolve the configured QIX Tunnel ID, validate it inside the open transaction,
create only the line's Forward/ForwardPort mapping, and preserve Tunnel ownership
outside the BusinessLine. Enumerate other consumers before any Tunnel-level work.
Protocol changes mutate the line's UDP service only.

## Never

Do not create, delete, rebuild, reconnect, or restart the shared Tunnel as a side
effect of one BusinessLine. Do not infer the QIX Tunnel from a name or suffix.

## Tests and acceptance

Create at least two lines sharing one disposable Tunnel, mutate/delete one, and
prove the other remains usable and the Tunnel ID/runtime stays stable. Run
backend tests and bounded TCP/UDP checks. Common failure: generic cascade cleanup
treating shared infrastructure as aggregate-owned.

## References

- `docs/dx/design-decisions.md`
- `docs/development-log/08-tcp-udp-protocol-switching.md`
