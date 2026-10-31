# Testing and debugging history

## Test strategy

Testing grew with the runtime blast radius: repository/handler unit tests,
migration failure injection, go-gost runtime transaction tests, frontend
lint/build, installer contracts, real DX data-plane checks, database restore,
restart recovery, and a public release gate.

## Important failures and root causes

- BusinessLine creation deadlock: transaction boundary misuse; `FIXED`.
- QIX orchestration reads: escaped transaction consistency; `FIXED`.
- Frontsea bind collision: database inventory missed live listeners; `FIXED` by
  runtime conflict retry/cache.
- Tunnel update test race: asynchronous reconcile could make immediate state
  assertions nondeterministic; tests must wait for the intended state rather
  than weaken assertions. Exact historic incident details beyond retained tests
  are `UNKNOWN`.
- ForwardX runtime replacement: broad replacement could disturb sessions;
  `FIXED` for BusinessLine switching by UDP-only mutation.
- Stale Workbox state: old index/chunk generations mixed; `FIXED`.
- Public UDP variability and FV Shadowsocks loss: attribution `UNKNOWN`.

## Current commands and acceptance

Commands are centralized in `AGENTS.md` and `docs/dx/development.md`. Real tests
must compare direct and FV paths, use normal bounded traffic, query panel state
rather than infer online status from TCP, and keep DX distinct from production.

## Maintenance warning

Do not skip a failed suite, lower an assertion, label a build as browser
acceptance, or attribute network loss without a same-time baseline. Preserve
failure evidence even when the outcome remains unknown.
