# TCP/UDP protocol switching

## Requirement and original gap

Operators needed `tcp_udp` and `tcp` modes without interrupting established TCP
connections. The original full-runtime replacement pattern could recreate the
TCP service and drain sessions.

## Investigation, failed approach, and root cause

ForwardX runtime replacement had shown that replacing a whole service set for a
one-protocol change can disrupt unrelated sessions. QIX made this worse because
rebuilding a shared Tunnel affects other lines. Whole-runtime and Tunnel rebuild
approaches were rejected.

## Final implementation

Schema 8 stores `protocol_mode`. Stable service names end in `_tcp` and `_udp`.
`tcp_udp -> tcp` deletes only UDP; `tcp -> tcp_udp` updates only UDP. Frontsea
applies both hops and rolls completed hops back in reverse. QIX touches only its
Forward. Database persistence uses expected old state after runtime success; a
write failure rolls runtime back. A process-local mutex serializes requests.

## Files, tests, results, and limits

Primary code is in `business_line.go` and Forward service synchronization.
`go-gost/x/socket` tests protect runtime transaction/restore behavior. Handler
tests verify reverse rollback. DX acceptance observed no TCP EOF/reset/timeout,
Agent restart, Tunnel recreation, or reconnect caused by switching.

The lock is process-local and rollback is compensating: both are `KNOWN
LIMITATION`s for multi-writer designs. Preserve TCP service identity in future
changes.

Sources: `c995aad`, `0908023`, runtime tests, switching verification.
