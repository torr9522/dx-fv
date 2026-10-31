---
name: security-and-secrets
description: Audit FV-DX for credentials, infrastructure disclosure, unsafe history, release assets, public documentation, or credential handling. Trigger on public release, Git history, secrets, tokens, configs, logs, or incident cleanup.
---

# Security and secrets

## Read first

Read `docs/development-log/13-security-and-history-cleanup.md`,
`docs/dx/provenance.md`, `.gitignore`, `.gitleaksignore`, and the release gate.

## Workflow

Inventory tracked files, notes, refs, reachable blobs, build artifacts, source
maps, docs, Skills, and scripts. Run redacted current-tree and full-history
scans; review findings rather than blanket-allowlisting. Keep credentials in
ephemeral protected input and cleanup paths. Revoke exposed credentials before
remote writes. Publish curated technical facts, never raw sessions.

## Never

Do not print tokens/passwords, commit `.env`, databases, Agent state, SSH config,
real infrastructure maps, packet captures, logs, SS URIs, or admin credentials.
Do not delete a file in a new commit and claim history is clean.

## Tests and acceptance

Require zero unreviewed current/history findings, known sensitive commits
unreachable, no forbidden tracked paths, no secrets in Release archives, and a
working synthetic-secret self-test. Common failure: scanning only HEAD.

## References

- `scripts/check-release-readiness.sh`
- `docs/dx/provenance.md`
