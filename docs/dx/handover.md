# Maintainer and Codex handover

Use this checklist on a new server or at the start of a new maintenance session.

1. Read root `AGENTS.md`, component `AGENTS.md`, and all files in `docs/dx/`.
2. Verify `git branch --show-current`, `git rev-parse HEAD`, `git status`, remotes,
   tags, and the range from upstream commit `3549fe5...`.
3. Confirm the task's environment. Do not infer that a DX ID, port, database, or
   service name is valid in production.
4. Install the pinned Go, Node, and pnpm versions; use a disposable local database.
5. Run `scripts/check-release-readiness.sh` before release-related work.
6. For BusinessLine code, trace the model, migration, repository, handler,
   control-plane service names, API client, and UI together.
7. Preserve stable `_tcp`/`_udp` service identity and shared-QIX ownership.
8. Add a numbered migration for BusinessLine schema changes and test upgrade,
   rollback, existing rows, and repeated startup.
9. Build the frontend with `DX_FV_BUILD=<commit>` and deploy it by atomic release
   directory/symlink, never by overlay copy.
10. Record which tests were actually run and clearly separate DX evidence from
    production evidence.

Never obtain operational secrets from old chat logs as a normal setup method.
Provision new credentials through the system owner, keep them outside Git, and
rotate any credential whose exposure is uncertain.
