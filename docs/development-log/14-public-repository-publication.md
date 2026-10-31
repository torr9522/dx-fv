# Public repository publication

## Requirement and preparation

FV-DX needed an independently auditable public repository and anonymous Release
downloads without importing private operational state. The publication gate had
to cover provenance, licenses, source, tests, manifests, and secrets.

## Final process

The clean history was pushed to `torr9522/dx-fv`; `main` was fixed at
`f25dcb4576eea367afb0274f4b21b6c02c735984` for remote acceptance. The
`fvdx-remote-rc1` pre-release held the verified installer assets. Anonymous HTTP
200 and manifest checks preceded stable promotion.

## Failure prevention

Local staging, authenticated download, floating `latest`, cached old packages,
and overwriting an existing tag were disallowed because they would not prove the
public user path. Release assets exclude databases, Agent configuration/tokens,
device state, logs, packet captures, and credentials.

## Verification and maintenance

The 32/32 v1.0.0 release gate is recorded in `docs/verification/release-gate.md`.
Future publication must re-run current/history scanning and anonymous downloads.
The downstream remote is the only allowed release target; never push this branch
to the upstream repository.

Sources: immutable public tags/releases and local gate script.
