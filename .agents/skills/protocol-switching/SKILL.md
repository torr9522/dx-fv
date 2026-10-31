---
name: protocol-switching
description: Develop or debug FV-DX BusinessLine TCP-only and TCP+UDP switching. Trigger on protocol_mode, UDP listener updates, session preservation, rollback, or QIX isolation.
---

# Protocol switching

## Read first

Read `docs/development-log/08-tcp-udp-protocol-switching.md`, migration docs,
BusinessLine protocol code/tests, and go-gost/x socket transaction tests.

## Workflow

Normalize to `tcp` or `tcp_udp`. Keep stable `<base>_tcp` and `<base>_udp`
identities. Delete only UDP when narrowing; update only UDP when widening.
Frontsea transitions both Forward hops and rolls back completed hops in reverse.
QIX transitions its Forward only. Persist with expected old state after runtime
success; roll runtime back if persistence fails.

## Never

Do not submit the TCP service, replace the complete Forward runtime, rebuild a
QIX Tunnel, add UDP-only implicitly, or bypass the process lock.

## Tests and acceptance

Run protocol validation/rollback, repository expected-state, go-gost/x runtime,
and migration tests. Real acceptance checks established TCP, EOF/reset/timeout,
Agent restarts, and shared-line isolation. Common failure: a successful first
Frontsea hop left changed after second-hop failure.

## References

- `docs/verification/tcp-udp-switching.md`
- `docs/dx/known-limitations.md`
