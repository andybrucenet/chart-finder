# Chart Finder

Musician-facing service: play a tune, get the name, find the best charts.

## Start Here
- `docs/notes/project-for-ai.md` – current focus and rules of engagement.
- `docs/notes/current-chat.md` – session trail and next actions.
- `docs/cookbooks/backend/aws.md` – daily backend and deploy workflow.
- `docs/notes/environment-variables.md` – environment variable reference.
- `docs/notes/versioning.md` – release numbering scheme and update workflow.
- `docs/api/` – checked-in OpenAPI specs generated via `make backend-swagger`.
- `Makefile` – run `make help` for common build/setup targets.

## Frontend Setup – Flutter
- Flutter tooling must be installed and invoked via **FVM** so each project pins its own SDK; run `dart pub global activate fvm`, then `fvm install <version>` / `fvm use <version>` in the Flutter app folder before issuing any `flutter` commands.
- IDEs should point at `<project>/.fvm/flutter_sdk` (or shell commands should use `fvm flutter …`) to guarantee the expected SDK without touching the global installation.

## Codebase Map
- `infra/` – infrastructure definitions and hydration scripts.
- `backend/` – build automation and tooling for backend projects (source lives in `src/backend/`).
- `src/backend/` – API, domain, and infrastructure adapters.
- `src/frontend/` – client applications (mobile prototype lives here).
- `tests/` – backend test projects mirroring `src/backend`.
