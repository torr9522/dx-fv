# Release and repository process

## Local publication gate

Run from the repository root:

```bash
scripts/check-release-readiness.sh
```

The script is local-only. It does not contact panel hosts, modify databases,
push Git, or create a release. It requires the pinned Go/Node/pnpm toolchains and
`gitleaks`; a missing tool is a failure, not a skipped PASS.

Before a private or public push, independently review all findings. A clean
current tree is insufficient: the Git history reachable from the branch is part
of the push. Never suppress a random credential-shaped historical value without
evidence that it is a fixture or a revoked non-secret.

## Repository policy

- Preserve root licenses and notices.
- Commit source, lockfiles, tests, examples, and maintenance docs.
- Do not commit build output, databases, `.env`, keys, Agent state, logs, packet
  captures, runtime binaries, or browser test state.
- Keep the upstream `origin` as fetch-only context until the user names the new
  remote. Never push this branch to `Sagit-chu/flvx`.
- Initially use a private repository. Public visibility needs a fresh license and
  full-history secret review.

## Version and deployment release

1. Start from a clean `dx-fv-dev` and record the base commit.
2. Run the local publication gate.
3. Review the diff, migrations, and production/DX status documentation.
4. Create a signed or annotated downstream tag only when a release is approved.
5. Build artifacts from the tag in CI; do not commit binaries.
6. Deploy to DX and complete browser/runtime acceptance.
7. Treat production deployment as a separate, explicitly approved change.

No tag should imply production acceptance unless production was actually tested.
