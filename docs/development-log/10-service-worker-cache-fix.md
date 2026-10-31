# Service Worker cache fix

## Requirement and observed defect

Ordinary refreshes and direct SPA routes sometimes loaded an old bundle or a
mixed generation, producing stale UI or blank lazy routes. Existing Workbox
registrations and precaches outlived a deployment. Status: `FIXED`.

## Failed approach and root cause

Overlay-copying new assets and relying on users to force refresh did not provide
an atomic generation boundary. An old cached index could reference removed or
incompatible hashed chunks. Official automatic update behavior also conflicted
with controlled downstream releases.

## Final implementation

Commit `3b213c2` removed active PWA registration and automatic update checks.
`src/main.tsx` unregisters root-scope workers and deletes Workbox precaches.
`public/sw.js` is a one-shot cleanup worker that deletes old caches, claims
clients, unregisters itself, and reloads pages. Deployment uses versioned
frontend directories and an atomic `frontend-current` symlink. Hashed assets are
immutable; index, SPA fallback, and cleanup worker revalidate.

## Impact, tests, limits, and maintenance

No database or Agent change. Browser acceptance verifies registration count 0,
no Workbox caches, current hashed assets, refresh, and direct routes. Cleanup is
origin-scoped; reintroducing `vite-plugin-pwa` registration or overlay deployment
would regress the fix. Preserve both cleanup code and cache headers.

Sources: `3b213c2`, `src/main.tsx`, `public/sw.js`, installer Caddy template.
