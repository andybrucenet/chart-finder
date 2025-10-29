# src/backend

- Purpose: Server-side code including API, domain, and infrastructure adapters.
- Projects: `ChartFinder.Api`, `ChartFinder.Domain`, `ChartFinder.Infrastructure.Aws`, `ChartFinder.Infrastructure.FileSystem`.
- Workflow: Restore/build/test via `ChartFinder.sln`; ensure new adapters ship with matching tests under `tests/backend`.
