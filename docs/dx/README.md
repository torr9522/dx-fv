# DX FLVX maintenance index

This directory is the source of truth for the FV-DX downstream fork. It
supplements, and does not replace, the upstream FLVX documentation.

## Fixed provenance

- Upstream: `Sagit-chu/flvx`
- Upstream release: `3.0.1-rc6`
- Upstream commit: `3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee`
- Downstream feature baseline: `8196178745fbfa51ad5c5efaa09577daab28a61c`
- Frozen stable: `v1.0.0` at `f25dcb4576eea367afb0274f4b21b6c02c735984`
- Maintenance target: `v1.0.1`

The repository remains a derivative work. `LICENSE`, `LICENSE-APACHE`, `NOTICE`,
and `vite-frontend/LICENSE` must remain present. See [provenance.md](provenance.md).

## Reading order

1. [architecture.md](architecture.md): BusinessLine and runtime mapping.
2. [development.md](development.md): supported toolchains, build, tests, and local startup.
3. [database-migrations.md](database-migrations.md): schema ownership, backup, upgrade, and rollback.
4. [deployment.md](deployment.md): DX/production boundaries and atomic frontend releases.
5. [design-decisions.md](design-decisions.md): decisions that must not be accidentally reversed.
6. [project-history.md](project-history.md): upstream baseline and downstream commit history.
7. [known-limitations.md](known-limitations.md): verified limits and deployment status.
8. [release-process.md](release-process.md): repository and release gate.
9. [handover.md](handover.md): checklist for a new maintainer or Codex session.
10. [native-installer.md](native-installer.md): native Debian release and install layout.
11. [commercial-license-boundary.md](commercial-license-boundary.md): unchanged upstream authorization boundary.
12. [fvdx-remote-rc1.md](fvdx-remote-rc1.md): remote installation acceptance pre-release scope.

For a cold start, begin with [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md), then
use `../architecture/`, `../development-log/`, `../decisions/`, and
`../verification/`. Project Skills under `.agents/skills/` route work to these
documents.

Example files under `deploy/examples/` contain placeholders only. Never commit a
real `.env`, database, Agent state, token, certificate, private key, packet capture,
or production-generated config.
