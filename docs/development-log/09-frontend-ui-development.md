# Frontend UI development

## Requirement and original gap

Operators needed BusinessLines grouped by route, not a flat collection of the
underlying hop rules. The first UI exposed too much infrastructure and grouped a
single route as `BusinessLine + hop`.

## Iteration and root cause

`aee5e83` added the initial creation page. `b2d4e0d` simplified the workflow.
`9ae5796` fixed grouping to use only `pathType`, Frontsea first and QIX second.
The root cause was treating generated Forward hops as user-facing grouping
dimensions. Nullable backend IDs were also normalized in `bc6a65e`. These are
`FIXED`.

## Final implementation

BusinessLine is the primary page; creation asks for path, entry, target, and
protocol. Details expose lower IDs for diagnosis, while Rules remains the
advanced view. The UI uses the repository's shadcn bridge and BrowserRouter.

## Files, data, tests, and limits

Changes live under `vite-frontend/src/pages`, route configuration, API types,
and BusinessLine components. No separate frontend database or Agent change was
needed. TypeScript, ESLint, production build, direct-route refresh, desktop, and
390 px browser checks are separate gates. There is no unit-test framework, a
`KNOWN LIMITATION`.

Future UI work must not infer route type from display names or generated ports.

Sources: `aee5e83`, `b2d4e0d`, `bc6a65e`, `9ae5796`.
