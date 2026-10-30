# Commercial-license boundary

FV-DX preserves the fixed upstream FLVX `3.0.1-rc6` commercial-license behavior.
The upstream implementation is in:

- `go-backend/internal/license/keygen.go`: Keygen API and machine calls.
- `go-backend/internal/http/handler/license_validation.go`: machine-scoped
  validation and activation.
- `go-backend/internal/http/handler/handler.go`: activation and brand gates.
- `go-backend/internal/http/handler/jobs.go`: periodic revalidation/downgrade.
- `go-backend/internal/store/repo/config_policy.go`: protected config policy.
- `vite-frontend/src/config/site.ts` and `vite-frontend/src/pages/config.tsx`:
  licensed brand-setting presentation.

The backend validates against `https://api.keygen.sh/v1`. Machine fingerprint
and machine ID participate in validation. Invalid, expired, revoked, or
definitively rejected licenses do not enable commercial state. Protected brand
settings remain gated by `is_commercial`.

The 15 replayed DX commits did not change the Keygen client, machine validation,
periodic job, config policy, or commercial frontend page. The shared handler
changed only to register BusinessLine endpoints. BusinessLine, protocol mode,
migrations, cache fixes, and native installation do not read or set
`is_commercial` and do not depend on a paid feature.

The installer initializes the upstream default unlicensed state. It does not
accept a license key, contact Keygen, set `is_commercial`, remove machine
binding, alter expiry handling, or activate a paid feature. Commercial features
require a legitimate upstream license and account configuration.

Redistributed source components retain the GPLv3, Apache-2.0, and MIT notices
listed in `provenance.md`. The Keygen service is not bundled. No separate
closed-source commercial binary was identified in the native payload. This is
a technical record, not a substitute for legal review before public release.
