# Chart Finder

Musician-facing service: play a tune, get the name, find the best charts.

## Getting Started
- Read the onboarding playbook: [`docs/notes/setup/README.md`](docs/notes/setup/README.md) – one-time setup, environment hydration, stack management, backend verification, and frontend placeholders.

## Daily Operations
- See the building guide [`./BUILDING.md`](./BUILDING.md) - All the steps required for building / running the software.

## Documentation Links
- [`docs/notes/project-for-ai.md`](docs/notes/project-for-ai.md) – current focus and rules of engagement.
- [`docs/notes/current-chat.md`](docs/notes/current-chat.md) – session trail and next actions.
- [`docs/cookbooks/backend/aws.md`](docs/cookbooks/backend/aws.md) – daily backend and deploy workflow.
- [`docs/notes/sso-cli-setup.md`](docs/notes/sso-cli-setup.md) – AWS Identity Center login + permission-set bootstrap.
- [`docs/notes/environment-variables.md`](docs/notes/environment-variables.md) – environment variable reference.
- [`docs/notes/versioning.md`](docs/notes/versioning.md) – release numbering and update workflow.
- [`docs/notes/setup/package-registries.md`](docs/notes/setup/package-registries.md) – npm/NuGet/pub.dev prep.
- [`docs/notes/setup/flutter-fvm.md`](docs/notes/setup/flutter-fvm.md) – FVM pinning + IDE integration for Flutter.
- [`docs/notes/setup/flutter-app.md`](docs/notes/setup/flutter-app.md) – Flutter scaffolding tips (project naming, platform creation).
- [`docs/api/`](docs/api) – checked-in OpenAPI specs generated via `make backend-swagger`.
- [`Makefile`](Makefile) – run `make help` for common build/setup targets.

## Codebase Map
- `infra/` – infrastructure definitions and hydration scripts.
- `backend/` – build automation and tooling for backend projects (source lives in `src/backend/`).
- `frontend/` – shared frontend tooling/Makefiles that delegate to the active stack (React/Flutter).
- `src/backend/` – API, domain, adapters, and their test projects (tests sit beside their targets).
- `src/frontend/` – client applications (React + Flutter live here; each stack pulls generated API clients from `docs/api/`).
