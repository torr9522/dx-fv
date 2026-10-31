---
name: testing-debugging
description: Plan or execute FV-DX unit, integration, runtime, browser, data-plane, recovery, and stability testing. Trigger on failures, regressions, acceptance, flaky reconciliation, UDP loss, or release gates.
---

# Testing and debugging

## Read first

Read `docs/development-log/12-testing-and-debugging.md`,
`docs/verification/README.md`, and the owning component instructions/tests.

## Workflow

Start with the smallest deterministic test, then expand by blast radius. Capture
expected state before mutation and verify database plus panel API plus runtime.
For asynchronous reconcile, wait on the intended observable state with a bounded
deadline. For networks, compare direct and FV paths with the same client,
target, timing, and packet count. Preserve exact errors and classify attribution.

## Never

Do not lower assertions, add unbounded load, flood UDP, call a build browser
acceptance, infer Agent ONLINE from TCP, or blame FV for loss without a baseline.

## Tests and acceptance

Use commands in `AGENTS.md`; include migration rollback, socket runtime restore,
frontend browser routes, database restore, Agent recovery, and stability when
relevant. Acceptance records success counts, EOF/reset/timeout/loss and remaining
unknowns. Common failure: asserting immediately before async reconciliation.

## References

- `docs/verification/shadowsocks-compatibility.md`
- `docs/dx/known-limitations.md`
