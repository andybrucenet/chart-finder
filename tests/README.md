# tests

- Purpose: Document how automated test suites are organized per application layer.
- Layout: Each stack keeps its test projects beside the code it validates (e.g., backend tests live under `src/backend/*Tests`). Add stack-specific folders here only when we need extra docs.
- Execution: Run `dotnet test ChartFinder-backend.sln` for the full suite or target the individual `*Tests` projects under `src/backend/`.
