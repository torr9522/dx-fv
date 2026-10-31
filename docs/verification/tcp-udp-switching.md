# TCP and UDP protocol switching

Status: `PASS` for Frontsea and QIX DX paths.

Repeated `tcp_udp -> tcp -> tcp_udp` transitions removed and restored only the
UDP service. Established TCP remained usable; observed EOF, reset, timeout,
Agent restart, Tunnel recreation, and Tunnel reconnection counts attributable
to switching were zero in the acceptance run. Frontsea rollback and QIX shared
Tunnel isolation are also covered by source tests.
