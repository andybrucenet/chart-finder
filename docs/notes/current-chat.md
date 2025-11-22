# 2025-01-17

## Key Decisions
- Maintain a single repo while partitioning code into `src/backend`, `src/frontend`, and `src/infra`; backend tests live alongside their projects under `src/backend`.
- Keep `src/backend/backend.sln` alongside the backend sources so future front-end stacks (Flutter, MAUI, etc.) stay decoupled.
- Treat DynamoDB as one implementation of a `IChartRepository` interface; plan for alternate providers and keep domain models AWS-agnostic.
- Record AWS SAM build outputs under `.aws-sam/` but keep them untracked; expand `.gitignore` with platform-specific artifacts when needed.
- Capture ongoing architecture and process notes inside `docs/notes/` so conversations remain versioned with the project.

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

## Next Steps
- Update scripts/README.md so new scripts (android-run, frontend-android-emulator, frontend-flutter-sync-client) are documented and tied back to the Make targets that invoke them.
- Verify the Flutter dependency sync flow:
  1. Backend change updates docs/api/chart-finder-openapi-v1.json.
  2. `make frontend deps` checks pubspec.yaml’s chart_finder_client entry, updating it and rerunning `flutter pub get` when the spec version changes.
- Hook AndroidManifest versioning (`versionName` = CF_FRONTEND_VERSION_SHORT, `versionCode` = CF_FRONTEND_VERSION_GLOBAL_RELEASE) into the Flutter deps target.
- Re-run the Android pipeline end-to-end (deps, build, start) to confirm everything compiles and launches.
- Negative/positive checks after verification:
  * Tamper with chart-finder-openapi-v1.json to simulate an invalid spec version and confirm the dependency normalization fails as expected.
  * Change CF_FRONTEND_VERSION_SHORT / CF_FRONTEND_VERSION_GLOBAL_RELEASE and confirm AndroidManifest picks up the new values automatically.
- Once Android is stable, repeat the integration work for macOS, then iOS, then Windows.

