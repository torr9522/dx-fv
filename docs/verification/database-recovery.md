# Database recovery verification

Status: `PASS` in an isolated DX copy.

Schema 8 and `PRAGMA integrity_check` were verified, a separate backup was
restored to an independent test database, and BusinessLine, Forward, Tunnel,
ForwardPort, and protocol mappings remained consistent. The unique running
database was not overwritten. Migration unit tests separately cover version 7,
version 8, repeated startup, and injected-failure rollback.
