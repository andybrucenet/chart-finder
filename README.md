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

## Codebase Map
- `infra/` – infrastructure definitions and hydration scripts.
- `src/backend/` – API, domain, and infrastructure adapters.
- `src/frontend/` – client applications (mobile prototype lives here).
- `tests/` – backend test projects mirroring `src/backend`.
