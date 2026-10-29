# Provenance and licenses

FLVX is derived from `bqlpfy/flux-panel`. The current upstream repository is
`Sagit-chu/flvx`. This downstream branch starts from upstream FLVX `3.0.1-rc6`,
commit `3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee`.

The root `LICENSE` applies GPLv3 to FLVX modifications and new components. The
root `LICENSE-APACHE` and `NOTICE` preserve the original flux-panel Apache-2.0
attribution. `go-gost/LICENSE` and `go-gost/x/LICENSE` preserve the MIT notice
for the embedded go-gost forks. `vite-frontend/LICENSE` preserves the MIT notice
for the frontend template. Go and JavaScript dependencies retain their own
licenses; their exact versions are defined by the three `go.mod` files and
`vite-frontend/pnpm-lock.yaml`.

The downstream changes add BusinessLine orchestration, the Frontsea port pool,
QIX shared-Tunnel integration, versioned BusinessLine migrations, protocol-mode
switching, the Chinese BusinessLine UI, route-path grouping, stale PWA cleanup,
and an operational atomic frontend deployment layout.

No downstream change grants permission to remove upstream notices, claim the
upstream code as original downstream work, or bypass FLVX commercial-license
validation. The license activation and commercial-feature checks remain part of
the upstream codebase and are outside the DX feature changes.

Before any public release, run the release-readiness script and perform a legal
review appropriate to the intended distribution. This document records source
provenance; it is not legal advice.
