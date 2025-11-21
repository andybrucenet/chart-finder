# Chart Finder – Daily Reload Snapshot

## Project Focus
- Deliver a musician-facing service that identifies played tunes and surfaces purchasable charts.
- Backend (`ChartFinder.Api`) is an ASP.NET Core app hosted on AWS Lambda via SAM; domain models live in `src/backend/ChartFinder.Domain`.
- Infrastructure templates reside under `infra/` and are hydrated into `.local/` for per-developer runs.

## Active Objective
- Finish the AWS bootstrap so the existing calculator controller is reachable through an API Gateway endpoint.
- Prioritize CI/CD enablement (SAM build/deploy, CodeBuild pipeline, IAM, artifact buckets) before expanding application features.

## Working Agreements
- AWS CLI and build commands do not work from AI - only the user can run them.
- User executes all build, deploy, dotnet, and AWS CLI commands; the AI never runs them.
- Do not modify or generate code without explicit user direction.
- When documenting or adding shell script environment options, use the `SCRIPTNAME_OPTION_<NAME>` style (e.g., `FRONTEND_NPM_INSTALL_OPTION_FORCE_INSTALL`) so each option clearly maps to its script.
- Shell scripts must avoid generic variable names: prefix inputs with `i_`, locals with `l_`, and globals with `the_<script>_<name>` to reduce clashes when scripts source each other; reserve ALL_CAPS for external tool/env options only.
- New scripts must be source-friendly: implement a `<script>_main` entrypoint, guard execution with a trailing `source-only` check, and avoid global `set -euo pipefail`; always handle errors explicitly so sourcing the script has no side effects.
- Stack deploys default to interactive confirmations; set `CF_STACK_DEPLOYMENT_MODE=batch` (or `AWS_SAM_DEPLOY_OPTION_NO_CONFIRM=1` directly) when automation needs to auto-confirm `sam deploy`.
- Treat `.local/` as the source of truth for hydrated configuration; consult those files when validating deploy settings.
- When generating new code - always add XML documentation (or equivalent) for public methods.
- Keep onboarding notes in `docs/notes/` and use existing scripts (`setup-dev-env.sh`, `sync-configs.sh`) for repo hydration.
- Script-specific variables use the form `the_[script-name]_[var-name]` and `ALL_CAPS` is reserved for "real" environment variables (those that are shared between scripts or passed to 3rd-party tools). Thus, for a script like frontend-src-sig.sh which needs to track location of the Flutter frontend src dir, we'd use a name like `the_frontend_src_sig_flutter_dir` instead of a name like `FLUTTER_DIR`. This was humans can easily see which env vars are meant to be shared vs. those env vars which are really local to the script itself (albeit still a global env var).
- *NEVER USE `set -euo` in a generated script!* Instead, check your error return codes. Using `set -euo` results in instant failures on any unexpected command, can pollute other scripts if 'source-only' option is used to source in (reuse) a script.

## Quick Daily Kickoff
1. Rehydrate configs if needed: `./scripts/setup-dev-env-aws.sh` or `./scripts/sync-configs.sh`.
2. Verify SAM handler (`ChartFinder.Api`) is in both `infra/aws/serverless.template` and `.local/infra/aws/serverless.template`.
3. Build and deploy manually: `./scripts/aws-sam-preflight.sh`, then `./scripts/aws-sam-deploy.sh build`.
4. Hit `/calculator/v1/add/{x}/{y}` on the deployed API Gateway URL for a smoke test.
