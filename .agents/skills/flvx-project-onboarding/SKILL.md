---
name: flvx-project-onboarding
description: Onboard a new maintainer or fresh Codex session to FV-DX. Use for repository orientation, current-version questions, task routing, cold starts, or deciding what to read before changing code.
---

# FV-DX project onboarding

Use this Skill before unfamiliar FV-DX work.

## Read first

1. `AGENTS.md`
2. `docs/PROJECT_STATUS.md`
3. `docs/dx/README.md`
4. `docs/architecture/README.md`
5. The matching development log and specialist Skill

## Workflow

1. Confirm branch, HEAD, worktree state, remotes, and nearest `AGENTS.md`.
2. Classify the task as backend, frontend, Agent, installer, database, release,
   security, or operations.
3. Establish evidence and environment boundaries; do not rely on chat history.
4. Read the owning source and tests before proposing a change.
5. Use `bash scripts/bootstrap-dev.sh --check` and run proportional gates.

## Never

Do not touch production, frozen tags, commercial authorization, or old sensitive
history. Do not treat DX evidence as production acceptance.

## Tests and acceptance

Run `bash scripts/bootstrap-dev.sh --check` and the owning component's smallest
read-only check. The task owner, source paths, tests, rollback concerns, and required docs are
identified before editing. Common failure: reading only the root README and
missing nested instructions.

## References

- `docs/dx/handover.md`
- `docs/development-log/README.md`
- `.agents/skills/README.md`
