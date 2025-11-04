# 2025-01-17

## Key Decisions
- Maintain a single repo while partitioning code into `src/backend`, `src/frontend`, and `src/infra`; mirror backend tests under `tests/backend`.
- Keep `ChartFinder.sln` at the repository root so future front-end stacks (Flutter, MAUI, etc.) stay decoupled.
- Treat DynamoDB as one implementation of a `IChartRepository` interface; plan for alternate providers and keep domain models AWS-agnostic.
- Record AWS SAM build outputs under `.aws-sam/` but keep them untracked; expand `.gitignore` with platform-specific artifacts when needed.
- Capture ongoing architecture and process notes inside `docs/notes/` so conversations remain versioned with the project.

## Next Actions
- Define a concise AWS naming convention that embeds project + environment without tripping service limits.
- Tag every AWS artifact with environment and owner metadata for cost tracking and filtering.
- Extend the setup flow to create one-time AWS resources (e.g., per-dev artifact buckets) once variables are known.
- Ensure `local.env` captures all required config values, including future `CF_BACKEND_PROVIDER` for AWS/Azure switching and inputs consumed by dedicated cloud setup scripts.
- Finish AWS CI/CD bootstrap: create artifact bucket + IAM attachments so CodeBuild/SAM deploy calls succeed end-to-end.

## 2025-01-18 Session Notes
- Confirmed AWS remains first-class target, followed by local/offline, then Azure (and possibly Google) adapters.
- Documented preference to keep AI-generated code out of the repo; assistant now supplies inline snippets only when asked.
- Settled on storing IAM templates under `infra/aws/iam/` with runtime copies mirrored under `.local/`; future sync script will hard-link static files and hydrate templated ones via folder-specific manifests.
- Agreed trust policies live in `infra/aws/iam/roles/` (e.g., `codebuild-exec-trust.json`) and permission sets in `infra/aws/iam/policies/` once hydrated.

## 2025-01-19 Session Notes
- Converted infra configs to `.in` templates and updated `setup-dev-env.sh` plus `sync-configs.sh` to hydrate with `envsubst`, skip ignored files, and strip `.in` suffixes.
- Sanitized shared markdown notes by replacing account-specific values with placeholders and captured the real identifiers in a private reference table.
- Clarified AWS login helpers (`aws-login.sh`, `aws-run-cmd.sh`) so they source local env vars, avoid `exec` misuse, and support headless SSO logins.
- Discussed AWS resource scoping: single workload account for devs with per-dev naming (`CF_LOCAL_DEV_ID`), consistent tagging, and planned prompts for additional variables (artifact buckets, account IDs).
- Identified need for a dedicated AWS setup script that runs after base env hydration to create required infrastructure (e.g., CodeBuild artifact buckets) and eventual top-level `CF_BACKEND_PROVIDER` to support alternate clouds.
- Added `CF_LOCAL_ENV_ID`, `CF_LOCAL_AWS_ARTIFACT_BUCKET`, `CF_LOCAL_AWS_ACCOUNT_ID` prompts + auto-hydration; `codebuild-exec-permissions.json.in` now derives log/S3 ARNs from those values.
- Verified `.local` hydration + self-tests; next up is provisioning the real S3 artifact bucket and wiring CI/CD invocation.

## 2025-01-20 Session Notes
- Do not invoke build, deploy, or AWS CLI commands from the AI; those must be run manually by the user.
