# BUILDING Chart Finder

This guide assumes you have already completed the one-time onboarding steps in [`docs/notes/setup/README.md`](docs/notes/setup/README.md). With `.local/` hydrated and credentials in place, use the workflows below for day-to-day development.

## Backend / Cloud Workflow

For backend or infrastructure work the daily driver is:

```
make stack-refresh
```

That one target restores/builds the .NET solution, rehydrates infra configs when inputs change, runs `aws-sam-preflight.sh`, deploys via `aws-sam-deploy.sh build`, refreshes the OpenAPI spec (updating `docs/api/chart-finder-openapi-v1.json` with metadata), and executes the `utils/v1/version` smoke test. It will also prompt for AWS SSO login automatically if your session expired, update `CF_LOCAL_AWS_BASE_URI` when the API endpoint changes, and surface TLS or IAM issues along the way. Think of it as the Swiss Army knife—only drop to the individual steps below when you need tighter loops.

### Target Reference

| Step | Command | Notes |
| --- | --- | --- |
| Optional AWS login check | `./scripts/aws-login.sh` | Handy if you just want to verify Identity Center state. `make stack-refresh` implicitly does the same when it hits AWS. |
| Restore & build | `make backend-build` | Runs `backend/Makefile` which restores, builds, and ensures env metadata + source signatures are current. |
| Tests | `make backend-test` | Executes .NET test projects and backend client tests (`backend/clients`). |
| Stack deploy | `make stack-refresh` | Rebuilds backend + infra, runs `aws-sam-preflight.sh`, deploys via `aws-sam-deploy.sh build`, refreshes the OpenAPI spec, and runs the `utils/v1/version` smoke test. Set `CF_STACK_DEPLOYMENT_MODE=batch` to auto-confirm SAM prompts. |
| Smoke tests | `make backend-smoke` | Hits the deployed `utils/v1/version` endpoint (also run automatically by `make stack-refresh`). |

Key references:
- AWS cookbook: [`docs/cookbooks/backend/aws.md`](docs/cookbooks/backend/aws.md)
- Identity Center + permission-set maintenance: [`docs/notes/sso-cli-setup.md`](docs/notes/sso-cli-setup.md)
- Script catalog: [`scripts/README.md`](scripts/README.md)

## Frontend Workflow

Frontend development does not require AWS logins—work locally unless you are validating against a deployed API. Use `CF_LOCAL_FRONTEND_ENV` to pick the active stack (`react` or `flutter`) and run the stack-specific commands:

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

`make stack-refresh` already chains the infra targets (`infra configs`, `infra build`, `infra publish`, `infra smoke`). Use the commands below only when isolating a specific SAM or template issue; otherwise let the higher-level target keep everything in sync.

| Step | Command | Notes |
| --- | --- | --- |
| Sync hydrated configs | `make infra configs` | Runs `scripts/sync-configs.sh` to rehydrate `.local/infra`. |
| SAM build/preflight | `make infra build` (or `stage`) | Calls `scripts/aws-sam-preflight.sh`. |
| Deploy | `make infra publish` | Wraps `scripts/aws-sam-deploy.sh build`; respects `CF_STACK_DEPLOYMENT_MODE`. |
| Stack status / URI | `make infra status` / `make infra uri` | Delegates to `aws-sam-deploy.sh status|uri`. |
| Smoke test | `make infra smoke` | Uses `scripts/aws-sam-stack-state.sh` + `curl` to hit `utils/v1/version`, updating `CF_LOCAL_AWS_BASE_URI` if it changed. |

For TLS operations (typically handled alongside `stack-refresh` but callable standalone), use:
- `make tls-status` → `scripts/tls-status.sh` (checks expiry).
- `make tls-renew` → `scripts/tls-renew.sh` (renews/imports the wildcard certificate).

## Troubleshooting & Utilities
- **Environment drift** – rerun `make setup-dev-env` or `scripts/sync-configs.sh` after editing `.in` files or `.local/local.env`.
- **SAM/IAM errors** – consult `docs/notes/sso-cli-setup.md` for the admin bootstrap flow (permission-set inline policy, artifact bucket creation). Re-run `scripts/admin/admin-setup-dev-env.sh` whenever IAM templates change.
- **Version bumps** – `./scripts/update-version.sh backend|frontend` drives the interactive workflow and regenerates artifacts.
- **Custom scripts** – see [`scripts/README.md`](scripts/README.md) for a catalog of every helper, when to run it, and which Make targets already wrap it.

When in doubt, prefer the Make targets—they orchestrate the scripts in the correct order and keep `.local` state consistent. Use the scripts directly only for troubleshooting or when building new automation.
