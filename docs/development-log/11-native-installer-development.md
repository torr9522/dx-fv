# Native installer development

## Requirement and original gap

FV-DX needed one anonymous public curl command for Debian 12 AMD64 without
Docker, Go, Node, Git, or a compiler on the panel host. It also needed safe
interactive input, random credentials, HTTPS, atomic frontend activation, and
repeat-install refusal.

## Design and issues found

The installer downloads a fixed Release directory, validates a strict manifest,
and stages files before mutation. Prompts use `/dev/tty` because stdin is the
curl pipe. Managed Caddy adds one independent site and import rather than
replacing Caddyfile. Historical installer fixes covered portable multiline
Caddy syntax, secure source rules, manifest parsing, and rollback/cleanup.

## Final implementation

`deploy/installer/install-fvdx.sh` checks OS, architecture, disk, DNS, ports, and
existing state; downloads backend/init/frontend/metadata; verifies SHA256;
generates cryptographic administrator credentials; initializes schema 8; writes
systemd and optional Caddy configuration; verifies login, HTTPS, and SPA routes;
then atomically records state. Existing database/service/version state stops the
run before credential generation.

## Files, tests, limits, and maintenance

Static contracts are in `scripts/check-fvdx-installer.sh`; release assembly is
in `scripts/build-fvdx-release.sh`. The installer does not alter commercial
state. It supports Debian 12 AMD64 only. v1.0.1 changes only the default asset
tag. Never test it against production or substitute local staging for public
download acceptance.

Sources: installer history, current script, v1.0.0 installation verification.
