# Design decisions

## BusinessLine is the normal UI object

The prior Rules UI grouped `BusinessLine + hop`, turning one route into multiple
top-level groups. The BusinessLine view now groups exclusively by `pathType`:
Frontsea, then QIX. The Rules view remains available for advanced diagnosis.

## Infrastructure IDs are configuration, not discovery heuristics

GZ node, Frontsea node, and QIX Tunnel IDs come from explicit environment
variables. Main grouping uses `BusinessLine.path_type`; it must not infer path
from names, ports, Forward IDs, node IDs, or Tunnel suffixes.

## QIX Tunnel ownership

The QIX Tunnel is shared infrastructure and is not owned by any one
BusinessLine. Deleting a QIX line or changing its protocol never deletes or
rebuilds the Tunnel.

## Protocol service granularity

TCP and UDP have stable independent Agent service names. Protocol switching
adds/removes only UDP. Replacing the complete Forward runtime would risk draining
established TCP sessions and reintroducing the historical FX failure mode.

## Business transaction semantics

Frontsea changes cover both hops. Runtime steps are rolled back in reverse on a
partial failure, and the BusinessLine database mode changes only after runtime
success. Optimistic expected-state persistence and a process-local lock prevent
two panel requests from silently overwriting each other.

## Versioned BusinessLine migrations

BusinessLine schema is owned by explicit migrations so the deployed schema can
be audited and upgraded predictably. Do not add it back to broad AutoMigrate.

## Frontend release consistency

An old cached index and mixed hashed assets previously allowed one domain to load
different UI generations and caused lazy-route blank pages. The accepted design
is a versioned immutable release directory, atomic symlink switch, non-sticky
index/SPA cache policy, immutable hashed assets, legacy PWA cleanup, and a build
marker. Overlay deployment and automatic upstream update checks remain disabled.
