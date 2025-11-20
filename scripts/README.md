# scripts/

## Overview

Home for the repo’s helper scripts. They keep per-stack logic out of the Makefiles so we can reuse the same entrypoints locally, in CI, and from ad-hoc shells.

## Adding New Scripts

1. Use `sample-reusable.sh` as a template (it is the house style).
1. Ensure that you have it documented in the reference section below.
1. Normally, will be wrapped by one or more commands in `../Makefile`

## Reference Section

The table below highlights each script, when to use it, and which top-level Make targets already call it. (Scripts under `scripts/admin/` have their own README—refer there for the per-admin bootstrap flow.)

| Script | Purpose | When to use it directly | Make targets / flows that already call it |
| --- | --- | --- | --- |
| `setup-dev-env.sh` | Hydrates `.local/` (env vars, hydrated templates, cached metadata) by prompting for per-dev inputs, then fans out to cloud-specific hydrators. | First-time setup or whenever `.local/local.env` values change. | `make setup-dev-env` |
| `setup-dev-env-aws.sh` | AWS hydration pass: copies `infra/aws/**/*.in` into `.local/infra/aws`, resolves env vars, and prepares SAM templates. | Rare—only when you want to rehydrate AWS bits without re-running the full wizard. | Called from `setup-dev-env.sh` / `sync-configs.sh` |
| `setup-dev-env-aws-post-process.sh` | Fixups after AWS hydration (e.g., rewrite `samconfig.toml` to point at `.aws-sam/build/template.yaml`). | Only if you hand-edit the hydrated files and need to reapply the patch. | Invoked automatically by `setup-dev-env-aws.sh` |
| `sync-configs.sh` | Re-hydrates `.local/infra/**` from the checked-in `.in` templates using the current `.local/local.env`. | After editing any template or when you need to refresh `.local/infra`. | `make infra configs`, `make stack-refresh` (via infra Makefile) |
| `cf-env-vars.sh` | Loads `.local/local.env`, derived metadata, and helper functions (OS detection, version info) into the current shell. | Source it before running ad-hoc scripts/commands outside Make. | Every script that begins with `source scripts/cf-env-vars.sh` |
| `cf-env-vars-to-make.sh` | Emits Makefile-friendly exports so each Makefile inherits the same env without re-sourcing. | Usually never—automatically evaluated at the top of every Makefile. | All repo Makefiles |
| `cf-run-cmd.sh` | Wrapper that sources `cf-env-vars.sh` and then execs the provided command (optionally via `--eval`). | Use it to run AWS CLI / SAM / dotnet commands with the hydrated env. | Used by `aws-*` scripts; can wrap manual commands |
| `aws-login.sh` / `aws-logout.sh` / `aws-is-logged-in.sh` | Helpers to check SSO state, trigger `aws sso login --no-browser`, or clear cached tokens. | Whenever you need to refresh SSO credentials or confirm which persona is active. | Manual |
| `aws-sam-preflight.sh` | Runs validation + `sam build` so templates and compiled assets are ready before deploy. | When iterating on templates or debugging failed builds. | `make infra build`, backend deploy flow, `make stack-refresh` |
| `aws-sam-deploy.sh` | High-level SAM wrapper (`build`, `status`, `uri`, `clean`, etc.) that honors `CF_STACK_DEPLOYMENT_MODE`. | Direct deploy/delete/status operations without invoking Make. | `make infra publish`, `make stack-refresh`, backend deploy |
| `aws-sam-stack-state.sh` | Calls `aws cloudformation describe-stacks` for `CF_LOCAL_ENV_ID` and prints the JSON (used to locate API outputs). | When you need raw stack outputs for scripting. | `make infra smoke` |
| `backend-env-metadata.sh` | Extracts backend version info from `Directory.Build.props` and caches it under `.local/state`. | Rare—run if version metadata gets out of sync. | `make backend configs` |
| `backend-src-sig.sh` | Hashes backend source and bumps `CF_BACKEND_BUILD_NUMBER` whenever code changes. | Debug unexpected build-number bumps. | `make backend build-number` (`backend/Makefile`) |
| `backend-openapi-annotate.sh` | Injects `x-chartfinder-backend-*` metadata into a downloaded OpenAPI file (in-place or stdout). | To re-tag existing specs without re-downloading. | `make backend swagger`, `make backend swagger-metadata` |
| `frontend-npm-install.sh` | Keeps the React app’s `node_modules` in sync with `package-lock.json` (hash tracked under `.local/state`). | After lockfile changes or when forcing clean installs; supports `FRONTEND_NPM_INSTALL_OPTION_MODE=ci`. | `frontend/Makefile-react` install targets |
| `frontend-src-sig.sh` | Hashes React and/or Flutter sources (respecting `CF_LOCAL_FRONTEND_ENV`) and bumps the shared frontend build number when code changes. | Investigate build-number churn; force-run before version bumps. | Frontend Make targets that refresh version/build metadata |
| `frontend-version-artifacts.sh` | Generates `versionInfo.ts` (and future equivalents) from `frontend/version.json`. | After editing `frontend/version.json` or when automation fails. | `make frontend-version`, `scripts/update-version.sh frontend` |
| `lcl-os-checks.sh` | Shared helper functions for OS detection, temp-dir allocation, and `.local` sourcing. Almost every script imports it first. | Source it if you are writing a new script under `scripts/`. | Used by nearly every shell helper |
| `sample-reusable.sh` | Demonstrates the house style for reusable scripts (functions + `source-only` guard). | Copy/paste template when authoring new helpers. | none |
| `tls-status.sh` | Reads `CF_LOCAL_TLS_CERT_PATH`, prints cert subject/issuer/expiry so you can monitor TTL. | `make tls-status` or whenever rotating TLS assets. | `make tls-status` |
| `tls-renew.sh` | Automates Let’s Encrypt renewal/import flow for the wildcard cert (pulls env from `.local`). | When certificates approach expiry; run before `make tls-status` raises alarms. | `make tls-renew` |
| `update-version.sh` | Interactive/non-interactive version bumper for backend (Directory.Build.props) and frontend (`frontend/version.json` + artifacts). | When incrementing versions prior to releases. | Invoked manually; downstream `make backend build` / `make frontend-version` consume the outputs |
