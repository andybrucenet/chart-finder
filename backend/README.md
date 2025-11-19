# backend

Build tooling and automation for the Chart Finder backend.

- Solution is `src/backend/backend.sln`
- Source projects live under `src/backend/`.
- Use `make` targets in this directory (or the root Makefile) to build, test, deploy, and regenerate OpenAPI specs.
- `./.config/dotnet-tools.json` pins local dotnet tools (e.g., the Swagger CLI) used by these targets.
- Client SDK generation & publishing lives under `backend/clients/` (see its README for npm/NuGet workflows).
