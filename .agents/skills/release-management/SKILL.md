---
name: release-management
description: Prepare, audit, tag, protect, publish, or verify an FV-DX release. Trigger on versions, GitHub Releases, manifests, binary identity, tags, rulesets, anonymous downloads, or release notes.
---

# Release management

## Read first

Read `docs/PROJECT_STATUS.md`, `docs/dx/release-process.md`,
`docs/dx/provenance.md`, and the version's development log.

## Workflow

Verify remote main and frozen refs before work. Run all local gates on a clean
normal-history branch. Prove binary provenance and identity; record release and
application build commits separately. Create one annotated tag at the approved
commit, push only intended refs without force, create a stable Release, protect
that exact tag, and anonymously verify every asset and SHA256.

## Never

Do not move/delete frozen tags, replace immutable assets/notes, rebuild unchanged
v1.0.0 application binaries for v1.0.1, use exposed credentials, push all tags,
merge unaudited upstream history, or deploy production as a release side effect.

## Tests and acceptance

Run release-readiness, handoff, secret/history, commercial, license, build, Skill,
cold-start, metadata/manifest, identity, and anonymous HTTP gates. Common failure:
metadata claiming old binaries were built from a documentation-only commit.

## References

- `docs/verification/release-gate.md`
- `scripts/check-release-readiness.sh`
