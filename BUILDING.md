# BUILDING Chart Finder

This guide assumes you have already completed the one-time onboarding steps in [`docs/notes/setup/README.md`](docs/notes/setup/README.md). With `.local/` hydrated and credentials in place, use the workflows below for day-to-day development.

## Daily Checklist (All Roles)
1. **Refresh environment metadata** – Only if API keys (rare) change or backend Cloud provider templates change (example: AWS IAM permissions; very rare). In either case - simply run `make setup-dev-env` and the `.local` cache is updated.
2. **Confirm AWS session** – run `./scripts/aws-login.sh` so subsequent commands share the right Identity Center persona.
3. **Sync dependencies** – backend (`make backend-build` handles restore), frontend (`make frontend-install` or stack-specific install target).
4. **Run the appropriate workflow** – backend, frontend, or infra sections below.
5. **Record outcomes** – capture notable changes or issues in `docs/notes/current-chat.md` so the next session picks up smoothly.

## Backend Workflow

Normally you will simply run `make stack-refresh` from the list below - this pretty much does everything.

For specific steps see below.

| Step | Command | Notes |
| --- | --- | --- |
| Restore & build | `make backend-build` | Runs `backend/Makefile` which restores, builds, and ensures env metadata + source signatures are current. |
| Tests | `make backend-test` | Executes .NET test projects and backend client tests (`backend/clients`). |
| Stack deploy | `make stack-refresh` | Rebuilds backend + infra, runs `aws-sam-preflight.sh`, deploys via `aws-sam-deploy.sh build`, refreshes the OpenAPI spec, and runs the `utils/v1/version` smoke test. Set `CF_STACK_DEPLOYMENT_MODE=batch` to auto-confirm SAM prompts. |
| Smoke tests | `make backend-smoke` | Hits the deployed `utils/v1/version` endpoint (also run automatically by `make stack-refresh`). |

Key references:
- AWS cookbook: [`docs/cookbooks/backend/aws.md`](docs/cookbooks/backend/aws.md)
- Identity Center + permission-set maintenance: [`docs/notes/sso-cli-setup.md`](docs/notes/sso-cli-setup.md)
- Script catalog: [`scripts/README.md`](scripts/README.md)

## Frontend Workflow

Chart Finder currently maintains an Expo/React stack and a Flutter prototype. `CF_LOCAL_FRONTEND_ENV` controls which stack top-level Make targets operate on.

| Task | React Commands | Flutter Commands |
| --- | --- | --- |
| Install deps | `make frontend-install` (delegates to `frontend/Makefile-react`, which calls `scripts/frontend-npm-install.sh`) | `cd src/frontend/chart-finder-flutter && fvm flutter pub get` (see [`docs/notes/setup/flutter-fvm.md`](docs/notes/setup/flutter-fvm.md)) |
| Build / lint | `make frontend-build`, `make frontend-lint`, `make frontend-test` | (Flutter targets TBD – drive via `fvm flutter test` / `flutter build <platform>`) |
| Version artifacts | `make frontend-version` (updates `versionInfo.ts` from `frontend/version.json`) | Future Flutter target will regenerate the Dart equivalent |
| Dev server | `make frontend-start` / platform-specific variants | `fvm flutter run -d <device>` |

Near-term roadmap items (tracked in `docs/notes/current-chat.md`):
- Split `frontend/Makefile` into stack-aware wrappers (`Makefile-react`, `Makefile-flutter`) driven by `CF_LOCAL_FRONTEND_ENV`.
- Ensure both stacks read the generated API client metadata from `docs/api/chart-finder-openapi-v1.json`.
- Add smoke tests that load the “Version” screen per stack.

## Infrastructure & Cloud Ops

Normally you don't need to do anything here...the initial `make setup-dev-env` gets all the `.local` files hydrated. And the `make stack-refresh` automatically checks for any changes to backend / infra configs and rebuilds as necessary.

Use these steps only as a general reference; again, your expected workflow will typically just be `make stack-refresh`.

| Step | Command | Notes |
| --- | --- | --- |
| Sync hydrated configs | `make infra configs` | Runs `scripts/sync-configs.sh` to rehydrate `.local/infra`. |
| SAM build/preflight | `make infra build` (or `stage`) | Calls `scripts/aws-sam-preflight.sh`. |
| Deploy | `make infra publish` | Wraps `scripts/aws-sam-deploy.sh build`; respects `CF_STACK_DEPLOYMENT_MODE`. |
| Stack status / URI | `make infra status` / `make infra uri` | Delegates to `aws-sam-deploy.sh status|uri`. |
| Smoke test | `make infra smoke` | Uses `scripts/aws-sam-stack-state.sh` + `curl` to hit `utils/v1/version`, updating `CF_LOCAL_AWS_BASE_URI` if it changed. |

For TLS operations, use:
- `make tls-status` → `scripts/tls-status.sh` (checks expiry).
- `make tls-renew` → `scripts/tls-renew.sh` (renews/imports the wildcard certificate).

## Troubleshooting & Utilities
- **Environment drift** – rerun `make setup-dev-env` or `scripts/sync-configs.sh` after editing `.in` files or `.local/local.env`.
- **SAM/IAM errors** – consult `docs/notes/sso-cli-setup.md` for the admin bootstrap flow (permission-set inline policy, artifact bucket creation). Re-run `scripts/admin/admin-setup-dev-env.sh` whenever IAM templates change.
- **Version bumps** – `./scripts/update-version.sh backend|frontend` drives the interactive workflow and regenerates artifacts.
- **Custom scripts** – see [`scripts/README.md`](scripts/README.md) for a catalog of every helper, when to run it, and which Make targets already wrap it.

When in doubt, prefer the Make targets—they orchestrate the scripts in the correct order and keep `.local` state consistent. Use the scripts directly only for troubleshooting or when building new automation.
