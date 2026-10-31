# Initial architecture

## Requirement and gap

Operators needed a stable, auditable object spanning user intent, persisted
resources, and Agent listeners. Raw Forward/Tunnel screens exposed implementation
detail and could not express ownership of shared versus line-local resources.

## Design

BusinessLine owns identifiers for its generated resources and records path,
entry, target, status, owner, and later protocol mode. Frontsea creates two
Forward hops plus line-local tunnel containers. QIX creates one Forward pointing
at an explicitly configured shared Tunnel. Rules remains the advanced view.

## Issues and final boundaries

Inferring routes from names, ports, node IDs, or suffixes was fragile and was
rejected. Environment-selected database IDs identify GZ, Frontsea, and QIX test
infrastructure per environment. They are neither addresses nor credentials.

## Impact, tests, and limits

The database gained BusinessLine at schema 7; Agent protocol stayed compatible
because orchestration emits existing service commands. Handler and repository
tests cover validation and resource reads. A fresh database still needs
registered test Agents and a test QIX Tunnel before real orchestration; this is
a `KNOWN LIMITATION`.

Sources: `eb1154c`, `docs/dx/architecture.md`, `business_line.go`.
