# Shadowsocks compatibility

Method: `aes-256-gcm`. Endpoint details and credentials are deliberately not
retained in this public repository.

| Check | Result |
| --- | --- |
| Direct TCP authentication and forwarding | PASS |
| FV TCP authentication and forwarding | PASS |
| Direct UDP relay | PASS |
| FV UDP relay | 70/80 received, 12.5% loss |

The FV UDP path genuinely relayed packets, but the recorded run had intermittent
loss. The direct baseline and known public underlay variability do not provide
enough evidence to isolate the cause. Attribution is `UNKNOWN`; this is a
`KNOWN LIMITATION`, not a resolved FV defect and not evidence of zero-loss UDP.

Source: project-owner final compatibility acceptance record. No URI, password,
server address, port, exit address, or temporary client configuration is stored.
