# License and commercial boundary

## Requirement

Public downstream work had to preserve open-source notices while leaving FLVX
commercial authorization fully intact. Downstream features are not permission
to bypass paid capability checks.

## Audit and design

GPLv3 covers downstream modifications; Apache-2.0 and MIT notices remain for
their respective inherited components. The commercial implementation, machine
binding, expiry checks, policy, and Keygen endpoint are treated as protected
baseline files. Installer behavior never writes commercial flags or license
state.

## Risks and rejected approaches

Removing checks, faking responses, embedding keys, changing the account ID to
unlock functionality, or documenting a bypass were rejected. An empty build-time
account value is not authorization. Commercial tests must use a legitimate
license or stop at the boundary.

## Files, tests, and maintenance

Protected files are listed in `docs/dx/commercial-license-boundary.md` and the
root `AGENTS.md`. `scripts/check-release-readiness.sh` compares their blobs
against the replayed baseline and inspects installer policy. Any intended change
requires explicit commercial-owner review; ordinary FV-DX feature work must not
touch them.

Status: `VERIFIED`, unchanged through v1.0.0. Source: blob comparisons and
commercial-boundary gate.
