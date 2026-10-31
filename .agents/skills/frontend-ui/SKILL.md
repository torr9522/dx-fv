---
name: frontend-ui
description: Develop, review, build, or debug the FV-DX React/Vite UI. Trigger on BusinessLine pages, routes, grouping, mobile layout, stale assets, Service Workers, cache policy, or frontend publishing.
---

# Frontend UI

## Read first

Read `vite-frontend/AGENTS.md`,
`docs/development-log/09-frontend-ui-development.md`, and
`docs/development-log/10-service-worker-cache-fix.md`.

## Workflow

Use `src/shadcn-bridge/heroui`, preserve semantic theme imports, and group
BusinessLines by `pathType`. Keep API types aligned with backend nullability.
Build with the pinned Node/pnpm versions. Publish a complete versioned directory,
then atomically switch `frontend-current`; keep immutable hashed-asset and
no-cache index/SPA policies.

## Never

Do not reintroduce Workbox/PWA registration or official auto-update requests,
overlay-copy into the active frontend, infer route groups from hop data, or claim
lint/build is browser acceptance.

## Tests and acceptance

Run frozen install, `pnpm exec eslint .`, and `pnpm run build`. Browser-check
login, home, BusinessLine, Rules, create/detail, direct SPA routes, refresh,
desktop and 390 px; require zero registrations and old Workbox caches. Common
failure: cached index referencing a different hashed-asset generation.

## References

- `docs/dx/design-decisions.md`
- `vite-frontend/src/main.tsx`
