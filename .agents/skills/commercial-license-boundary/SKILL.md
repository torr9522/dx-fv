---
name: commercial-license-boundary
description: Review any FV-DX work near licensing, activation, paid features, machine binding, expiry, Keygen, installer policy, or public-release commercial boundaries.
---

# Commercial license boundary

## Read first

Read `docs/dx/commercial-license-boundary.md`, root `AGENTS.md`, and protected
file blob checks in `scripts/check-release-readiness.sh`.

## Workflow

Identify whether the task touches validation, policy, machine identity, expiry,
jobs, build-time account configuration, or frontend licensed settings. Compare
protected blobs to the accepted baseline. If a feature needs a legitimate paid
capability, preserve normal authorization and stop the test when no valid license
is available.

## Never

Do not bypass `https://api.keygen.sh/v1`, forge a response/license, disable
binding or expiry, change paid policy, expose a key, or make the installer alter
commercial state.

## Tests and acceptance

Run the commercial boundary gate and inspect the exact diff of all protected
paths. Acceptance means no unauthorized semantic change and no bypass in docs,
Skills, scripts, tests, or installer. Common failure: treating a test convenience
as permission to simulate a successful license response.

## References

- `docs/development-log/02-license-and-commercial-boundary.md`
- `docs/PROJECT_STATUS.md`
