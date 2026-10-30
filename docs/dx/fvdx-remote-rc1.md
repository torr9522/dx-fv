# FV-DX Remote Installation Acceptance RC1

`fvdx-remote-rc1` is a pre-release used to validate anonymous GitHub downloads
and a native Debian 12 AMD64 installation on a freshly installed server.

Release assets contain the Linux AMD64 panel backend, database initializer,
frontend production archive, build metadata, and a SHA256 manifest. The
installer is pinned to this tag and does not follow `latest` or `main` for
runtime artifacts.

This candidate does not activate or bypass commercial licensing. It does not
include databases, credentials, Agent state, Shadowsocks URIs, SSH material,
runtime logs, or production configuration.

The tag records build and publication readiness only. Final public-release
acceptance requires a separate clean-server installation from the anonymous
GitHub URLs and the explicitly scoped runtime tests.
