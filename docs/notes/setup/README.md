# Chart Finder – One-Time Setup

Onboarding checklist for new contributors. Fill in the placeholders (e.g., `<CF_LOCAL_DEV_ID>`) with your own values—avoid copying another developer’s identifiers such as `andybrucenet`.

## 1. One-Time Prerequisites
- **AWS access**  
  - Follow `docs/notes/cloud-provider-onboarding-checklist.md` and `docs/notes/sso-cli-setup.md` to enroll in AWS Identity Center, configure SSO profiles, and collect account/role identifiers (account ID, permission-set ARN, region, `CF_LOCAL_DEV_ID`, artifact bucket name, etc.).  
  - Capture any secrets or generated IDs somewhere safe; these flow into `.local/local.env`.
- **Toolchains**  
  - Install the base toolset: Git, bash-compatible shell, AWS CLI v2, `dotnet` (per `global.json`), Node.js + npm (for the React app), and Python 3.  
  - Install mobile tooling as needed: Xcode (macOS), Android Studio, and Expo CLI.  
  - Flutter-specific tooling must run through **FVM**: `dart pub global activate fvm`, then `fvm install <version>` / `fvm use <version>` inside `src/frontend/chart-finder-flutter`. IDEs and shells should point at `.fvm/flutter_sdk` (or call `fvm flutter ...`) so the repo controls the SDK version.
- **Package registries**  
  - Sign in to npm (if publishing private packages later), NuGet (for internal feeds), and pub.dev (if publishing Flutter artifacts). Document any API keys in your personal credentials store, not in the repo.

## 2. Environment Hydration (`.local`)
1. Ensure the repo root contains `.local/` (ignored by Git).  
2. Run `make setup-dev-env` (top-level Makefile) which wraps `scripts/setup-dev-env.sh`. The script will prompt for the values gathered above (AWS account, `CF_LOCAL_ENV_ID`, `CF_LOCAL_AWS_ARTIFACT_BUCKET`, etc.) and hydrate:
   - `.local/local.env`
   - Hydrated infra templates under `.local/infra/**`
   - Cached metadata in `.local/state/**`
3. If you need to rebuild specific sections, use the `CF_ENV_VARS_OPTION_*` flags described in `docs/notes/environment-variables.md`.

## 3. Stack Management
- **Daily flow**  
  - `make stack-refresh` runs backend build + infra build/publish, then refreshes the OpenAPI spec.  
  - Use `CF_STACK_DEPLOYMENT_MODE=batch make stack-refresh` (or `make stack-refresh-batch`) to auto-confirm SAM deploy prompts.  
  - `scripts/aws-sam-preflight.sh` and `scripts/aws-sam-deploy.sh build` remain the lower-level escape hatches when debugging SAM directly.
- **Environment-specific values** live under `.local/infra` and `docs/notes/environment-variables.md`; always verify those before attempting `sam` commands.

## 4. Backend Verification
- `make backend-test` (or `make test`) runs the .NET unit/integration suites.  
- After a deploy, hit the API Gateway calculator endpoint documented in `docs/cookbooks/backend/aws.md` to confirm Lambda wiring.  
- Use `scripts/backend-openapi-annotate.sh` + `make backend-swagger` to refresh `docs/api/chart-finder-openapi-v1.json`, then verify the metadata (`x-chartfinder-*`) matches the build you just shipped.  
- Capture logs via CloudWatch (ensure Identity Center permissions allow access); structured logging requirements live in the TODO list—update them as observability matures.

## 5. Frontend Deployment Placeholder
- React and Flutter apps live under `src/frontend/**` with automation in `frontend/`. Until the multi-stack Makefile split lands, follow `docs/notes/current-chat.md` for the active frontend focus.  
- Planned flow: run `make frontend` targets to generate platform assets, ensure the React/Flutter apps read `docs/api/chart-finder-openapi-v1.json` for the correct client version, and add smoke tests that load the “Version” screen. Document the finalized steps here once the Flutter deployment story is complete.

---

For quick reference, the top-level `README.md` “Documentation Links” section points back to this file plus the other living guides (`project-for-ai.md`, `current-chat.md`, etc.). Keep this setup guide updated whenever onboarding steps change.***
