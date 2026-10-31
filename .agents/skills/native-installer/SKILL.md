---
name: native-installer
description: Develop, audit, or test the FV-DX Debian native curl installer, Release downloads, manifest verification, systemd, Caddy, credentials, and repeat-install protection.
---

# Native installer

## Read first

Read `docs/dx/native-installer.md`,
`docs/development-log/11-native-installer-development.md`, and installer source.

## Workflow

Pin installer source and default asset tag. Require HTTPS unless an explicit
local-test override is used. Download only the required Release files to a
private temporary directory, strictly verify manifest hashes before mutation,
read pipe-mode prompts from `/dev/tty`, generate credentials securely, initialize
schema 8, activate versioned files atomically, and add an independent Caddy site.
Reject existing install state before credentials or database changes.

## Never

Do not use floating `latest`, staging as public acceptance, Docker/toolchains on
the target, default credentials, whole-Caddyfile replacement, database overwrite,
or commercial-state changes.

## Tests and acceptance

Run `bash -n`, shellcheck, `scripts/check-fvdx-installer.sh`, verify-only public
downloads, isolated prefix tests, `/dev/tty` interaction, Caddy/external modes,
failure cleanup, and repeat refusal. Common failure: installer tag and asset tag
drifting apart.

## References

- `deploy/installer/install-fvdx.sh`
- `scripts/check-fvdx-installer.sh`
