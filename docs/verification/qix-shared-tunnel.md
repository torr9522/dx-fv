# QIX shared-Tunnel verification

Status: `PASS` in DX.

Two BusinessLines shared one dedicated QIX test Tunnel. Both transferred TCP and
UDP, protocol switching one line did not disrupt the other, and the shared
Tunnel was not recreated, reconnected, or deleted by line lifecycle operations.
The test Tunnel and production infrastructure were distinct.
