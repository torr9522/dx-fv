# Downstream project history

The upstream fixed point is FLVX `3.0.1-rc6`, commit
`3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee`.

The downstream commits through the functional baseline are:

| Commit | Purpose |
|---|---|
| `ac34d4a` | BusinessLine orchestration API |
| `d586008` | BusinessLine creation page |
| `fd39f6f` | avoid BusinessLine transaction deadlock |
| `c79f848` | retry Frontsea ports after runtime conflicts |
| `a2a501b` | cache discovered Frontsea port conflicts |
| `019ce6e` | keep QIX orchestration reads in transaction |
| `97e5e7d` | versioned database migration, including schema 7 |
| `3afd6c4` | simplify BusinessLine user workflow |
| `740e932` | serialize nullable BusinessLine IDs consistently |
| `2fe3db9` | group BusinessLines by route path |
| `062ef0e` | remove stale frontend/PWA cache behavior |
| `535e129` | schema 8 and BusinessLine protocol mode |
| `8196178` | incremental BusinessLine protocol switching |

The protocol implementation was validated in DX for Frontsea and QIX, including
repeated switching and shared-Tunnel isolation. That is development evidence,
not production acceptance. The repository contains no evidence establishing
which FV-DX schema or version, if any, is deployed in production.

Do not squash or rewrite these commits during routine maintenance. If a secret
scan requires history remediation, stop and agree on a dedicated migration plan,
backup refs, remote coordination, credential revocation, and force-push policy
before changing any commit IDs.
