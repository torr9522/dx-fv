# QIX shared-Tunnel development

## Requirement and original gap

Multiple QIX BusinessLines must share one pre-created Tunnel while retaining
independent Forward targets and protocol modes. Treating the Tunnel as a child
of one line would let one deletion or update disrupt every consumer.

## Design, issue, and root cause

The final ownership model makes the QIX Tunnel environment-selected shared
infrastructure. Early orchestration reads outside the open transaction could see
inconsistent state or lock incorrectly; `b120e6a` moved them into the transaction.
Rebuilding the shared Tunnel during a line protocol switch was rejected because
Tunnel lifecycle is broader than that line.

## Final implementation

Each QIX line creates one Forward referencing the same type-2 Tunnel. Delete
removes only the line and Forward. Protocol transition mutates only that
Forward's UDP service. Tunnel creation, deletion, reconnect, and restart are not
part of line lifecycle.

## Impact and verification

BusinessLine stores `tunnel_id`; no new Agent protocol is required. Repository
tests cover transactional reads and DX acceptance verified two simultaneous
lines, shared-Tunnel identity, TCP/UDP, protocol isolation, and cleanup.

## Maintenance warning

Never infer sharing from a name and never cascade line deletion into the QIX
Tunnel. Any Tunnel lifecycle feature must enumerate all consumers and prove
isolation before mutation.

Sources: `b120e6a`, delete/protocol code, QIX verification.
