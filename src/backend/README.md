# src/backend

Server-side projects covering the API, core domain, and infrastructure adapters.

## Projects
- `ChartFinder.Api` – ASP.NET Core Lambda entry point.
- `ChartFinder.Domain` – shared entities and repository abstractions.
- `ChartFinder.Infrastructure.Aws` – AWS implementations.
- `ChartFinder.Infrastructure.FileSystem` – local/offline adapters.
- `ChartFinder.Api.UnitTests` – unit coverage for the API surface.
- `ChartFinder.Api.IntegrationTests` – end-to-end harness for the Lambda/API gateway path.

## Tests

All test projects have 'Tests' at the end. To run these tests, `dotnet test src/backend/backend.sln` from the repo root.

## Docs
- Build and deploy routines: `docs/cookbooks/backend/aws.md`.
- Version metadata + shared build settings: `src/backend/Directory.Build.props`.
