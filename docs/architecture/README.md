# FV-DX architecture diagrams

These diagrams summarize the implementation documented in
`docs/dx/architecture.md`. Source code remains authoritative.

## Components

```mermaid
flowchart LR
  Browser[React operator UI] -->|JSON API| Panel[Go paneld]
  Panel --> DB[(SQLite or PostgreSQL)]
  Panel -->|WebSocket commands| Agent[FLVX Agent]
  Agent --> Runtime[go-gost/x services]
  Installer[Native installer] --> Panel
  Installer --> Browser
  Caddy[Caddy or external proxy] --> Browser
  Caddy --> Panel
```

## BusinessLine creation

```mermaid
sequenceDiagram
  participant UI
  participant API as BusinessLine API
  participant DB
  participant A as Agent runtime
  UI->>API: create request
  API->>API: validate owner, path, entry, target, protocol
  API->>DB: transaction creates aggregate and resources
  DB-->>API: commit
  API->>A: apply stable TCP/UDP services
  alt runtime failure
    API->>A: compensate completed runtime steps
    API->>DB: remove created aggregate resources
  else success
    API-->>UI: BusinessLine response
  end
```

## Frontsea Direct data path

```mermaid
flowchart LR
  Client -->|configured GZ entry| GZ[GZ Forward]
  GZ -->|automatic 34700..34799 IX port| IX[Frontsea Forward]
  IX --> Target[Target host and port]
```

Ports `34700..34725` are statically reserved. Allocation also excludes persisted
ForwardPort use and live bind conflicts. A partial two-hop apply is rolled back.

## QIX shared Tunnel data path

```mermaid
flowchart LR
  C1[Line A client] --> F1[Forward A]
  C2[Line B client] --> F2[Forward B]
  F1 --> T[Shared QIX Tunnel]
  F2 --> T
  T --> D1[Target A]
  T --> D2[Target B]
```

The Tunnel is infrastructure, not a child of either line. Deleting or switching
one line cannot delete, rebuild, or restart it.

## Protocol switch

```mermaid
stateDiagram-v2
  tcp_udp --> tcp: Delete only forward UDP service
  tcp --> tcp_udp: Update only forward UDP service
  note right of tcp
    TCP service identity remains stable
  end note
```

Frontsea applies both Forward hops and compensates completed hops in reverse on
failure. QIX changes only the line's Forward. The database expected-state update
happens after runtime success; persistence failure triggers runtime rollback.
