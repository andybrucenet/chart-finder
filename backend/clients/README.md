# Backend Client Tooling

This directory tracks the tooling that generates language-specific SDKs from
`docs/api/chart-finder-openapi-v1.json`. The generated outputs are treated as
build artifacts and written under `.local/backend/clients/`, keeping the repo
lean while still letting us publish npm / NuGet packages.

## Workflow
1. Ensure the OpenAPI spec is current: `make backend-swagger`.
2. Install tooling (one-time): `cd backend/clients && make setup`. Complete the registry prep outlined in [`docs/notes/setup/package-registries.md`](../../docs/notes/setup/package-registries.md) so npm/NuGet/pub.dev credentials are already cached (`CF_LOCAL_BACKEND_API_KEY_NUGET_ORG`, `npm login`, `dart pub token add`, etc.).
3. Run `CLIENTS_FORCE=1 make build` (or just `make build`) to regenerate + publish.
   The Makefile compares `docs/api/chart-finder-openapi-v1.json` with the cached
   copy under `.local/state/chart-finder-openapi-v1.json` and skips the build
   when the spec is unchanged. Set `CLIENTS_FORCE=1` to override the check. The
   scripts source `scripts/cf-env-vars.sh`, normalize package versions, inject
   `CF_DEFAULT_BASE_URI` into a temporary copy of the spec, and emit code under
   `.local/backend/clients/<lang>`.
4. The build target automatically:
   - runs `npm run generate:all` to refresh the code,
   - packs + pushes the .NET SDK to nuget.org using `CF_LOCAL_BACKEND_API_KEY_NUGET_ORG`,
   - runs `npm publish` in the TypeScript output directory.

Each generator command injects `CF_DEFAULT_BASE_URI` as the baked-in endpoint
and derives the package version from `CF_BACKEND_VERSION_SHORT` plus
`CF_BACKEND_BUILD_NUMBER`, so regenerated clients only change when the backend
contract changes.
