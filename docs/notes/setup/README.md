# Chart Finder – One-Time Setup

Onboarding checklist for new contributors. Fill in the placeholders (e.g., `<CF_LOCAL_DEV_ID>`) with your own values—avoid copying another developer’s identifiers such as `andybrucenet`.

## 1. One-Time Prerequisites
- **AWS access**  
  - Follow <a href="../cloud-provider-onboarding-checklist.md" target="_blank" rel="noopener">docs/notes/cloud-provider-onboarding-checklist.md</a> and <a href="../sso-cli-setup.md" target="_blank" rel="noopener">docs/notes/sso-cli-setup.md</a> to enroll in AWS Identity Center, configure SSO profiles, and collect account/role identifiers (account ID, permission-set ARN, region, `CF_LOCAL_DEV_ID`, artifact bucket name, etc.).  
  - Capture any secrets or generated IDs somewhere safe; these flow into `.local/local.env`.
- **Toolchains**  
  - Install the base toolset: Git, bash-compatible shell, AWS CLI v2, `dotnet` (per `global.json`), Node.js + npm (for the React app), and Python 3.  
  - Install mobile tooling as needed: Xcode (macOS), Android Studio, and Expo CLI.  
  - Flutter-specific tooling must run through **FVM**: see <a href="./flutter-fvm.md" target="_blank" rel="noopener">docs/notes/setup/flutter-fvm.md</a> for the pinned version, `.fvm/fvm_config.json`, and IDE tips.
- **Package registries**  
  - Use <a href="./package-registries.md" target="_blank" rel="noopener">docs/notes/setup/package-registries.md</a> for the npm/NuGet/pub.dev walkthroughs. Store tokens in a password manager and hydrate `.local/local.env` with any required variables (e.g., `CF_LOCAL_BACKEND_API_KEY_NUGET_ORG`).

## 2. Environment Hydration (`.local`)
1. Ensure the repo root contains `.local/` (ignored by Git).  
2. Run `make setup-dev-env` (top-level Makefile) which wraps `scripts/setup-dev-env.sh`. The script will prompt for the values gathered above (AWS account, `CF_LOCAL_ENV_ID`, `CF_LOCAL_AWS_ARTIFACT_BUCKET`, etc.) and hydrate:
   - `.local/local.env`
   - Hydrated infra templates under `.local/infra/**`
   - Cached metadata in `.local/state/**`
3. If you need to rebuild specific sections, use the `CF_ENV_VARS_OPTION_*` flags described in <a href="../environment-variables.md" target="_blank" rel="noopener">docs/notes/environment-variables.md</a>.

## 3. Initial Stack Management
- **Stack creation**  
  - `make stack-refresh` runs backend build + infra build/publish, refreshes the OpenAPI spec, and executes the backend smoke test.  
  - Use `CF_STACK_DEPLOYMENT_MODE=batch make stack-refresh` (or `make stack-refresh-batch`) to auto-confirm SAM deploy prompts.  
  - `scripts/aws-sam-preflight.sh` and `scripts/aws-sam-deploy.sh build` remain the lower-level escape hatches when debugging SAM directly.
- **Environment-specific values** live under `.local/infra` and `docs/notes/environment-variables.md`; always verify those before attempting `sam` commands.
- **Identity Center + IAM permissions** change over time—keep <a href="../sso-cli-setup.md" target="_blank" rel="noopener">docs/notes/sso-cli-setup.md</a> handy for the latest delegated-admin and permission-set steps.

## 4. Backend Verification
- `make backend-test` runs the .NET unit/integration suites.  
- `make backend-smoke` hits the deployed `utils/v1/version` endpoint (documented in <a href="../../cookbooks/backend/aws.md" target="_blank" rel="noopener">docs/cookbooks/backend/aws.md</a>) to confirm Lambda/API Gateway wiring.  
- `make stack-refresh` runs both commands automatically, ensuring every deploy rebuilds, tests, updates the OpenAPI spec, and performs the smoke test.

## 5. Frontend Deployment Placeholder
- React and Flutter apps live under `src/frontend/**` with automation in `frontend/`. Until the multi-stack Makefile split lands, follow <a href="../current-chat.md" target="_blank" rel="noopener">docs/notes/current-chat.md</a> for the active frontend focus.  
- Planned flow: run `make frontend` targets to generate platform assets, ensure the React/Flutter apps read `docs/api/chart-finder-openapi-v1.json` for the correct client version, and add smoke tests that load the “Version” screen. Document the finalized steps here once the Flutter deployment story is complete.

---

For quick reference, the top-level <a href="../../README.md" target="_blank" rel="noopener">README.md</a> “Documentation Links” section points back to this file plus the other living guides (<a href="../project-for-ai.md" target="_blank" rel="noopener">project-for-ai.md</a>, <a href="../current-chat.md" target="_blank" rel="noopener">current-chat.md</a>, etc.). Keep this setup guide updated whenever onboarding steps change.***
