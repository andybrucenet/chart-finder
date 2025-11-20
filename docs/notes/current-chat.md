# 2025-01-17

## Key Decisions
- Maintain a single repo while partitioning code into `src/backend`, `src/frontend`, and `src/infra`; backend tests live alongside their projects under `src/backend`.
- Keep `src/backend/backend.sln` alongside the backend sources so future front-end stacks (Flutter, MAUI, etc.) stay decoupled.
- Treat DynamoDB as one implementation of a `IChartRepository` interface; plan for alternate providers and keep domain models AWS-agnostic.
- Record AWS SAM build outputs under `.aws-sam/` but keep them untracked; expand `.gitignore` with platform-specific artifacts when needed.
- Capture ongoing architecture and process notes inside `docs/notes/` so conversations remain versioned with the project.

## Next Actions
- Define a concise AWS naming convention that embeds project + environment without tripping service limits.
- Tag every AWS artifact with environment and owner metadata for cost tracking and filtering.
- Extend the setup flow to create one-time AWS resources (e.g., per-dev artifact buckets) once variables are known.
- Ensure `local.env` captures all required config values, including future `CF_BACKEND_PROVIDER` for AWS/Azure switching and inputs consumed by dedicated cloud setup scripts.
- Finish AWS CI/CD bootstrap: create artifact bucket + IAM attachments so CodeBuild/SAM deploy calls succeed end-to-end.
- Harden the new `aws-sam-deploy.sh` helper (document modes, pull SAM warnings into a tracking issue, consider migrating to a Makefile once targets settle).
- Add smoke tests for the deployed Lambda/API Gateway path to confirm the stack stays healthy.

## 2025-01-18 Session Notes
- Confirmed AWS remains first-class target, followed by local/offline, then Azure (and possibly Google) adapters.
- Documented preference to keep AI-generated code out of the repo; assistant now supplies inline snippets only when asked.
- Settled on storing IAM templates under `infra/aws/iam/` with runtime copies mirrored under `.local/`; future sync script will hard-link static files and hydrate templated ones via folder-specific manifests.
- Agreed trust policies live in `infra/aws/iam/roles/` (e.g., `codebuild-exec-trust.json`) and permission sets in `infra/aws/iam/policies/` once hydrated.

## 2025-01-19 Session Notes
- Converted infra configs to `.in` templates and updated `setup-dev-env.sh` plus `sync-configs.sh` to hydrate with `envsubst`, skip ignored files, and strip `.in` suffixes.
- Sanitized shared markdown notes by replacing account-specific values with placeholders and captured the real identifiers in a private reference table.
- Clarified AWS login helpers (`aws-login.sh`, etc.) so they source local env vars, avoid `exec` misuse, and support headless SSO logins.
- Discussed AWS resource scoping: single workload account for devs with per-dev naming (`CF_LOCAL_DEV_ID`), consistent tagging, and planned prompts for additional variables (artifact buckets, account IDs).
- Identified need for a dedicated AWS setup script that runs after base env hydration to create required infrastructure (e.g., CodeBuild artifact buckets) and eventual top-level `CF_BACKEND_PROVIDER` to support alternate clouds.
- Added `CF_LOCAL_ENV_ID`, `CF_LOCAL_AWS_ARTIFACT_BUCKET`, `CF_LOCAL_AWS_ACCOUNT_ID` prompts + auto-hydration; `codebuild-exec-permissions.json.in` now derives log/S3 ARNs from those values.
- Verified `.local` hydration + self-tests; next up is provisioning the real S3 artifact bucket and wiring CI/CD invocation.

## 2025-01-20 Session Notes
- Do not invoke build, deploy, or AWS CLI commands from the AI; those must be run manually by the user.
- Still unable to run AWS CI/CD end-to-end; time is going into provisioning per-dev artifacts and IAM roles.
- Admin bootstrap flow: dev hydrates `.local` (including `samconfig.toml`), admin runs `scripts/admin/admin-setup-dev-env.sh` against it to create the artifact bucket and scoped CodeBuild role/policy.
- `samconfig.toml` and `serverless.template` hydration still need refinement (e.g., `CodeUri` path adjustments) before the process is push-button.
- Next task: craft the IAM policy that grants `iam:PassRole` (plus CloudFormation/Lambda actions) to the dev permission set and have the admin bootstrap script attach that policy to the correct Identity Center permission set.

## 2025-01-21 Session Notes
- Documented the mandatory AWS Organizations delegation step so the workload account can call `sso-admin`; added reminders that admins must keep browsers separated per SSO persona.
- Added a post-process script to rewrite the hydrated `samconfig.toml` so guided setup still works but real deploys consume `.aws-sam/build/template.yaml`; updated the build script to validate after each `sam build`.
- ` ./scripts/cf-run-cmd.sh sam deploy --config-file .local/infra/aws/samconfig.toml --config-env dev ` failed with `iam:CreateRole` / `iam:TagRole` / `iam:DeleteRolePolicy` access denied while CloudFormation was creating `AspNetCoreFunctionRole` (see stack event messages for the exact ARN `arn:aws:iam::835972387595:role/chart-finder-dev-abruce-AspNetCoreFunctionRole-*`).
- Follow-up: extend the Identity Center inline policy (and admin bootstrap script) so the dev permission set grants CloudFormation the missing IAM actions (`iam:CreateRole`, `iam:DeleteRole`, `iam:AttachRolePolicy`, `iam:DetachRolePolicy`, `iam:PutRolePolicy`, `iam:TagRole`, `iam:UntagRole`, `iam:DeleteRolePolicy`) scoped to `arn:aws:iam::835972387595:role/cf-*-*`, then rerun the admin bootstrap before retrying the deploy.

## 2025-11-08 Session Notes
- IAM inline policy tuned to fence pass-role/read-only actions to `cf-sab-u-dev-*` roles plus the Identity Center role (`/aws-reserved/sso.amazonaws.com/us-east-2/...`), ensuring devs can inspect and deploy without touching other environments.
- `admin-setup-dev-env-aws.sh` now prunes old policy versions, provisions permission sets, and uses `--no-cli-pager` across AWS calls; SSO provisioning waits for `SUCCEEDED`.
- New deploy helper `aws-sam-deploy.sh` supports `build`/`clean`/`rebuild`/`status` modes, wrapping stack deletion and SAM deploy logic behind a Make-style interface.
- Successful `sam deploy` created the `cf-sab-u-dev` stack (Lambda + DynamoDB) with no IAM failures; CLI warning notes Pydantic’s Py3.14 incompatibility (benign, needs tracking).
- Next test: hit the deployed API/Lambda for a smoke check and capture the endpoint & expected payload in docs.

## 2025-11-17 Session Notes
- Frontend now reads Expo config from `app.config.ts` which imports the generated `VersionInfo`; version metadata (company/product, base URLs, versions, build numbers) flows from `.local` → `frontend/version.json` → `versionInfo.ts` → Expo config.
- Added `frontend-refresh-ios`, `frontend-refresh-android`, and `frontend-refresh-all` targets (plus top-level wrappers) to chain native rebuilds with Expo dev server runs.
- `versionInfo.ts` now includes `companyName`, `productName`, and slugified variants; `app.config.ts` derives bundle IDs/packages from these fields.
- TypeScript config allows explicit `.ts` imports (`allowImportingTsExtensions`), fixing Expo config resolution without needing a JS shim.
- Updated `useVersion` hook to consume the generated `UtilsApi` via `utilsGetVersionRaw()` and parse JSON directly, replacing the homegrown fetch helper.
- Version screen now renders the API response and warns-free monospace styling by using `Platform.select` for fonts.
- Calculator code path removed; frontend entry screen renamed to `VersionScreen`.
- Reminder: **AI must not run build/deploy/Expo/CocoaPods commands**—user owns `frontend-refresh-*`, `expo run`, etc.

### Next Steps
- Stand up the Flutter tooling via FVM before touching new code: `dart pub global activate fvm`, `fvm install/use <version>`, and wire VS Code build/deploy tasks to `.fvm/flutter_sdk`.
- Decide on the actual mobile app feature set (e.g., splash screens, chart discovery/purchase flows, potential “listen to music” capability).
- Design splash screens/logo assets for both iOS and Android, aligned with the new bundle identifiers.
- Outline the core screens and navigation (what replaces the current placeholder version check).
- Stand up parallel backend solutions/projects (e.g., net8 for Lambda, “ChartFinder.Api.NSwag” on net10) that link shared sources from `src/common`, so tooling with new runtime requirements doesn’t block the deployed runtime.

## 2025-11-20 Session Notes
- Renamed the generic `aws-run-cmd.sh` helper to `cf-run-cmd.sh` so every stack command (especially Make targets) can load the fully-hydrated env without implying AWS-only usage.
- Added `scripts/cf-env-vars-to-make.sh`, which sources `cf-env-vars.sh` and emits Make-style assignments/exports (including the derived `the_cf_env_vars_*` paths) so a single `$(eval $(shell …))` call bootstraps the environment for all recipes.
- Optimized `scripts/cf-env-vars.sh` for Cygwin-heavy runs by short-circuiting when `CF_ENV_VARS_TO_MAKE_ALREADY_RUN=1`, while still honoring explicit rebuild flags and keeping the cached backend/frontend metadata available.
- Updated the top-level, backend, backend-clients, and infra Makefiles to compute `ROOT` from their own paths and immediately call `$(ROOT)/scripts/cf-env-vars-to-make.sh`, ensuring targets in any subdirectory inherit the same env without wrapping `make` in `cf-run-cmd.sh`.
- Expanded `frontend-src-sig.sh` so it hashes both the React (`src/frontend/chart-finder-react`) and Flutter (`src/frontend/chart-finder-flutter`) trees (when present), skipping framework-specific build/cache folders and bumping the shared frontend build number whenever either stack changes; respected `CF_LOCAL_FRONTEND_ENV` so only the active stack is scanned when set.

## 2025-11-21 Session Notes
- Added `scripts/backend-openapi-annotate.sh` and wired it into the backend Makefile so OpenAPI downloads automatically embed `x-chartfinder-backend-version` and `x-chartfinder-backend-build-number`.
- Introduced `swagger-metadata` plus `SWAGGER_METADATA_SCRIPT/INPUT` knobs, letting us re-annotate any existing spec without regenerating or bumping backend build numbers.
- `BACKEND_OPENAPI_ANNOTATE_OPTION_STDOUT=1` now emits to stdout via a temp file, enabling non-destructive checks or piping into other tooling.
- Confirmed `docs/api/chart-finder-openapi-v1.json` carries the new metadata, so frontend clients can read the published version to select the matching generated API bundle.

## TODO
- Avoid unnecessary `.NET` rebuilds: if no backend source files changed, `make stack-refresh` should skip `dotnet build` (and thus prevent spurious stack publishes).
- Add a proper release flow where client publishes use only `A.B.C` versions (not `-build.*`) and require a matching `CHANGELOG.md` entry before publishing.
- Lock down the Flutter app model: map the navigation stack, confirm native outputs for every target platform, enforce an MVC split between UI and logic, and wire in a skinnable theme from the start.
- [HIGH] Capture backend Lambda logging requirements and ensure structured logs flow from .NET to CloudWatch (or equivalent) for observability.

## Next Steps
### Makefiles (1)
- Create a new `frontend/Makefile` that reads `CF_LOCAL_FRONTEND_ENV` (`react` or `flutter`) and dispatches to sub-makes.
- Update `frontend/Makefile-react` as needed (likely minimal) so it plays nicely with the new wrapper.
- Add `frontend/Makefile-flutter` covering all Flutter build/run commands.

### Frontend API Clients
- Ensure both React and Flutter frontends load the generated API client by reading `docs/api/chart-finder-openapi-v1.json`.

### Flutter Version Screen
- Implement the initial Flutter “Version” screen to confirm end-to-end wiring.

### Makefiles (2)
- Extend both frontend Makefiles with a smoke-test target that validates the version screen loads successfully.
