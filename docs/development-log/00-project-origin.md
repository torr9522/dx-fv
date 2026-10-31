# Project origin

## Need and original gap

FV-DX began as a downstream extension of FLVX for managing complete traffic
routes as one operator object. The inherited Forward and Tunnel primitives were
useful, but operators had to understand every hop and could not safely treat a
two-hop route or a shared-Tunnel route as one lifecycle. `VERIFIED` by the fixed
upstream tree and first BusinessLine commit.

## Research and initial design

The team retained the mature FLVX Go backend, React UI, Agent command channel,
and go-gost runtime rather than replacing the forwarding engine. A BusinessLine
aggregate was layered over existing Forward, ForwardPort, Tunnel, and
ChainTunnel records. The source fixed point is FLVX `3.0.1-rc6`, commit
`3549fe5ad8a6e9b863b3e4f7b9bf738facff87ee`.

## Problems, failed approaches, and resolution

Directly publishing the original history was rejected because it contained
unrelated and potentially sensitive ancestry. Rebuilding all runtime behavior
was also unnecessary and risked diverging from mature FLVX semantics. The final
approach used a source-tree-equivalent clean baseline plus reviewed replayed
commits. This preserved attribution while limiting public history.

## Impact and verification

The architecture changed at the orchestration/UI layer, not the license system
or core protocol engine. Main components are `go-backend`, `vite-frontend`,
`go-gost`, and `go-gost/x`. Provenance is verified by the baseline tree hash and
15-entry replay map. Future work must research upstream separately and import
reviewed changes without merging unaudited history.

Sources: `docs/dx/provenance.md`, `a5240dc`, `eb1154c`.
