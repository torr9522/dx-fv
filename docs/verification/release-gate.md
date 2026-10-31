# Public release gate

The v1.0.0 publication gate completed 32/32 checks before stable promotion.
The clean publication baseline, 15 replayed DX commits, anonymous Release
downloads, manifest hashes, commercial boundary, and current/history secret
scans were verified. The exact reproducible local gate is
`scripts/check-release-readiness.sh`.

v1.0.1 must run that gate again plus `scripts/check-project-handoff.sh`, Skill
validation, an independent cold-start session, and byte identity checks against
v1.0.0. This file must not be changed to claim those checks passed before their
actual execution.
