---
name: agent-lifecycle
description: Register, inspect, update, recover, or test FV-DX forwarding Agents and panel command delivery. Trigger on Node online status, Agent identity, WebSocket commands, runtime state, restart, or recovery.
---

# Agent lifecycle

## Read first

Read `docs/dx/development.md`, `docs/verification/agent-recovery.md`,
`go-gost/AGENTS.md`, and `go-gost/x/AGENTS.md`.

## Workflow

Use the panel's normal node registration flow. Keep each environment's identity
in that Agent's protected config. Confirm compatibility before upgrading. Treat
the panel Node API status/heartbeat as acceptance, then inspect PID, restart
count, version, SHA256, and command results. Restart one test Agent at a time and
verify runtime reconciliation.

## Never

Do not copy production tokens, print registration secrets, commit `device.id` or
Agent state, replace an Agent without compatibility evidence, or equate a TCP
socket with panel-accepted online status.

## Tests and acceptance

Run `(cd go-gost && go test ./...)`, `(cd go-gost/x && go test ./...)`, lifecycle
and socket transaction tests, then bounded DX recovery. Acceptance requires API
online state and restored listeners without unrelated service changes. Common
failure: restarting a production or non-DX service with a similar name.

## References

- `docs/development-log/12-testing-and-debugging.md`
- `docs/dx/handover.md`
