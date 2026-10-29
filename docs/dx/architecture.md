# DX architecture

## Components

- `go-backend/`: panel API, database, orchestration, and Agent commands.
- `vite-frontend/`: React/Vite operator UI.
- `go-gost/`: FLVX Agent wrapper.
- `go-gost/x/`: local go-gost/x fork used by the Agent.

BusinessLine is the user-facing aggregate. Forward, ForwardPort, Tunnel, and
ChainTunnel remain the runtime resources. The Rules page is intentionally kept
as an advanced view of those resources; the BusinessLine page is the normal
management view.

## BusinessLine model

`business_line` records the name, owner, `path_type`, entry and target, stable
IDs of generated resources, status, timestamps, and `protocol_mode`. The only
protocol values are `tcp_udp` and `tcp`; omitted values default to `tcp_udp`.
There is no UDP-only mode.

Creation uses environment-selected infrastructure:

- `FLVX_BUSINESS_LINE_GZ_NODE_ID`
- `FLVX_BUSINESS_LINE_FRONTSEA_NODE_ID`
- `FLVX_BUSINESS_LINE_QIX_TUNNEL_ID`

These are database IDs, not addresses or credentials. They must be resolved
separately in each environment.

## Frontsea Direct

A Frontsea line maps to two Forward records:

```text
GZ entry port -> Frontsea automatic port -> target host:port
```

The Frontsea port is selected from `34700..34799`. The allocator excludes ports
already referenced by ForwardPort, statically reserved ports in
`business_line.go`, and live conflicts discovered while applying Agent config.
It does not sort or group lines by the automatic port.

Creation records two local tunnel/chain containers and two Forward IDs in one
database transaction, commits, then applies both runtime services. A runtime
failure removes the partially created BusinessLine resources. An address-in-use
failure caches that Frontsea port as a conflict and retries another candidate.

## QIX shared Tunnel

A QIX line creates one Forward that references an existing type-2 Tunnel:

```text
GZ entry port -> shared QIX Tunnel -> target host:port
```

The Tunnel is shared infrastructure. Creating, deleting, or changing the
protocol of one BusinessLine must not create, delete, or restart that Tunnel.
BusinessLine deletion removes the line and its Forward but deliberately leaves
the shared Tunnel intact.

## Runtime service identity and protocol changes

Each Forward has stable service names derived from
`<forwardID>_<userID>_<userTunnelID>`:

- `<base>_tcp`
- `<base>_udp`

`tcp_udp -> tcp` sends `DeleteService` only for the `_udp` name. `tcp -> tcp_udp`
sends `UpdateService` only for `_udp`. The `_tcp` service is not submitted by
the protocol transition, preserving its listener and established sessions.

Frontsea transitions apply to the GZ and Frontsea Forward. If the second step
fails, completed steps are rolled back in reverse order. The database mode is
updated with an expected-old-value condition only after all runtime operations
succeed. If the database update fails, runtime is rolled back. A process-local
mutex serializes protocol changes. QIX transitions operate on the BusinessLine
Forward only and never manage the shared Tunnel lifecycle.

Regular Forward reconciliation reads the owning BusinessLine and emits only TCP
for `tcp`, or TCP and UDP for `tcp_udp`. Legacy service-base candidates are kept
for cleanup compatibility.

## API and UI

The downstream API endpoints are:

- `POST /api/v1/business-line/list`
- `POST /api/v1/business-line/create`
- `POST /api/v1/business-line/update-protocol`
- `POST /api/v1/business-line/delete`

Authentication follows FLVX convention: the JWT is sent raw in `Authorization`,
without a `Bearer` prefix. All responses use `{code,msg,data,ts}`.

The BusinessLine UI groups only by `pathType`, with Frontsea first and QIX
second. Details may expose underlying IDs and internal ports, but those resources
are not top-level user objects.
