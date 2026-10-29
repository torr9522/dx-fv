# Provenance and licenses

FLVX is derived from `bqlpfy/flux-panel`. The current upstream repository is
`Sagit-chu/flvx`. This downstream branch starts from upstream FLVX `3.0.1-rc6`,
commit `3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee`.

The publication repository intentionally uses an independent history. Its
parentless baseline commit is `a5240dc45bcc21a9571bbea9745b423dbc166733`,
whose tree `6076e2ad5bc0ac0934d9c0a19b433661ff14db0b` exactly matches the fixed
upstream commit's source tree. The upstream commit object, branches, tags, and
older blobs are deliberately not imported.

The 15 downstream commits were replayed in their original order. Authors,
author dates, subjects, boundaries, and `Original-Commit` trailers were
preserved:

| Original commit | Publication commit |
| --- | --- |
| `ac34d4ae35db070a9614429d36c783d3e3ed1d86` | `eb1154c8a0705f38d5d6bdf4583b4699098a2ad8` |
| `d58600848a475b390da0c211a63675dbcec5e39b` | `aee5e83a3cb4a221ae70eb71f54ef8c61ba984d9` |
| `fd39f6faf5c65cdf35e7accca5cd8d01a5a98a5d` | `6ad0a65bc8ec3876567dcbd3a36c1cbf6168a425` |
| `c79f848d63946e23a2715585398b536ad1b6ba94` | `5fe12814ab4cfe5dc0ebbf3308723b2ddf699bcf` |
| `a2a501b2cf42fbab4a88d29c63bd26644a078c92` | `caab7d66937d3b78bc94112e8b4b0f665045161e` |
| `019ce6ee84be6d6d22446e07da6366b2dc55719f` | `b120e6ae65cd643a7829c5a510defb433b352a17` |
| `97e5e7d87a84b2342769a36b12818ea7c4445999` | `29a936d04dbefc6c972e8d0d190086914c0425ed` |
| `3afd6c4f4ad2748f9c032327ce5873b8d54970c7` | `b2d4e0dd57b3ede2b0f52528e01be7a2c7bfc988` |
| `740e9323a36ba2cd3d70551d481caeb30350a18f` | `bc6a65ed837c4dbd59815b4575ddfc88e854eb55` |
| `2fe3db90560257b9ac70e1bd75c9b9c6ef1f1b2a` | `9ae57965d365cfdbc8a1a75504d97973a065ce38` |
| `062ef0e6e200168bca2e51c30a8be43229588af9` | `3b213c2ea607f2e88ee09df92e6bb1fd15a27825` |
| `535e129f10dbf1592ac3806fc8222c73597a0f34` | `c995aad968ef603d431fa89f433048039aaf9807` |
| `8196178745fbfa51ad5c5efaa09577daab28a61c` | `090802359721689ac31dbe12e8220d2b88479e5e` |
| `74b73ed104d940ae39ee35f9f660c0919d7dc31b` | `30b17e0527689b9288d89046cef71a7635049392` |
| `2ffea41de9649d77b6a51cc228dcf6e1b08c2961` | `a985781c45bb7d600d886fd9643c994ba353fe11` |

Future upstream work must be inspected in a separate maintenance clone and
imported as reviewed patches or through a reviewed clean rebaseline. Do not
merge unaudited upstream history into this repository.

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
