# Security and history cleanup

## Requirement and risk

The downstream repository had to become public without exposing credentials,
operational inventory, databases, Agent identities, or unaudited upstream blobs.
A clean working tree alone was insufficient because every reachable Git object
would be published.

## Investigation and rejected approaches

The team scanned the current tree and reachable history, reviewed suspicious
credential-shaped values, and identified sensitive upstream ancestry. Merely
deleting files in a new commit or copying raw Codex sessions into documentation
was rejected because the data would remain reachable or disclose unrelated
information.

## Final implementation

A parentless commit with a source tree identical to the fixed upstream point was
created, followed by 15 reviewed DX replays with provenance trailers. Later
public-release commits replaced operational inventory with placeholders. Git
notes, reachable blobs, tracked forbidden files, current tree, and history are
part of the release gate. Original sessions are never published; only curated,
redacted facts enter this log.

## Verification and maintenance

The baseline tree hash and replay mapping are checked automatically. Known
sensitive upstream commits must remain unreachable. Never merge old refs or
force-push a remediation casually; use a separately approved history migration
if new evidence requires one.

Sources: `docs/dx/provenance.md`, `.gitleaksignore`, release gate.
