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

## 2025-11-22 Session Notes
- Added `frontend/Makefile` as a stack-aware wrapper plus `frontend/Makefile-flutter`, ensuring `CF_LOCAL_FRONTEND_ENV` selects the correct frontend stack while React/Flutter makefiles now pin their own version-artifact runs.
- Extended `scripts/frontend-version-artifacts.sh` so it emits both `versionInfo.ts` and the new Flutter `lib/version_info.dart`, keeping metadata generation consistent across stacks.
- Introduced `frontend/scripts/frontend-flutter-cf-env-vars-to-make.sh`, which validates `CF_FRONTEND_FLUTTER_VER`, runs the required `fvm` install/use flow without leaking PATH mutations, and ensures Flutter version parity before exporting Make vars.
- Gated `fvm flutter pub get` behind a `.local/state` stamp in `frontend/Makefile-flutter` so dependency installs only rerun when `pubspec.yaml`/`pubspec.lock` change; `clean` now clears the stamp to force refreshes.
- Added `scripts/frontend-ios-simulator.sh` to detect or boot the desired iOS simulator (`CF_FRONTEND_IOS_SIMULATOR_NAME`, default `iPhone 18`) using `xcrun simctl`, giving future targets a reusable “ensure simulator is ready” step.
- Captured the command to pick the newest available `iPhone 16` simulator runtime:
  ```bash
  xcrun simctl list devices --json \
  | jq -r '
      .devices
      | to_entries[]
      | .key as $runtime
      | .value[]
      | select(type == "object")
      | select((.name == "iPhone 16") and (.isAvailable == true))
      | [$runtime, .name, .udid]
      | @tsv
    ' | sort -ur | head -n 1
  ```

## TODO
- Avoid unnecessary `.NET` rebuilds: if no backend source files changed, `make stack-refresh` should skip `dotnet build` (and thus prevent spurious stack publishes).
- Add a proper release flow where client publishes use only `A.B.C` versions (not `-build.*`) and require a matching `CHANGELOG.md` entry before publishing.
- Lock down the Flutter app model: map the navigation stack, confirm native outputs for every target platform, enforce an MVC split between UI and logic, and wire in a skinnable theme from the start.
- [HIGH] Capture backend Lambda logging requirements and ensure structured logs flow from .NET to CloudWatch (or equivalent) for observability.

## Next Steps
### Frontend Platform Follow-Ups
- Update `scripts/frontend-ios-simulator.sh` to consume the saved `simctl`/`jq` query so it auto-selects the newest available `iPhone 16` runtime before booting.
- Wire the Flutter app to render the generated `version_info.dart` (initial “Version” screen + smoke test target), proving the build can run on iOS.
- Integrate the Flutter make targets with the simulator helper so `make frontend-ios` starts a sim, deploys, and verifies the app (aim for a working iOS run loop).
- Import the Flutter (Dart) Chart Finder API client generated from `docs/api/chart-finder-openapi-v1.json`, deriving version/build metadata via the normalization helpers in `scripts/lcl-os-checks.sh`.
- Finish the dependency audit by running `npm outdated --long` in `chart-finder-react` and planning the required upgrades/replacements for deprecated packages.
- Add scripted checks around `fvm flutter` commands so CI/dev boxes verify the pinned `CF_FRONTEND_FLUTTER_VER` before builds run.
