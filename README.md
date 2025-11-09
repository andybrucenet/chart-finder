This is the chart-finder repository.

Designed for musicians - play a tune, get the name, find the best charts available.

## Developer Cookbooks
- Backend (AWS): see `docs/cookbooks/backend/aws.md` for daily commands and troubleshooting.

## Environment Variables
These values are populated automatically by `./scripts/setup-dev-env.sh`, which writes `.local/local.env` and ensures every helper script sources it. Just run the setup script—do not add these variables to your shell profile or export them manually.

### Common ChartFinder Settings
- `CF_HOME` – absolute path to the local chart-finder repository; lets one workstation host multiple clones side by side.
- `CF_LOCAL_PRJ_ID` – short project slug (policy-set to `cf`) prepended to cloud resource names for easy console filtering.
- `CF_LOCAL_DEV_ID` – logical owner or persona (default `<login>-dev`); used in resource names to group per-developer stacks. For shared stacks, use values such as `stage`, `test`, or `prod` to mirror the target environment.
- `CF_LOCAL_BILLING_ENV` – billing/tag value (default `dev`) stored on resources so cost and health dashboards can filter by environment.
- `CF_LOCAL_ENV_ID` – stack and storage prefix (default `${CF_LOCAL_PRJ_ID}-${CF_LOCAL_DEV_ID}`) that threads through CloudFormation stacks, S3 buckets, and ARNs.
- `CF_LOCAL_USEREMAIL` – owner contact injected into tags and parameters (no default; must be a reachable email address).

### AWS-Specific ChartFinder Settings
- `CF_LOCAL_AWS_PROFILE` – default CLI profile (default `${CF_LOCAL_DEV_ID}-${CF_LOCAL_PRJ_ID}-${CF_LOCAL_BILLING_ENV}`); applied whenever `AWS_PROFILE` is unset so SAM/AWS CLI commands pick the right credentials.
- `CF_LOCAL_AWS_REGION` – default AWS region for the workspace; same precedence rules as the profile.
- `CF_LOCAL_AWS_ARTIFACT_BUCKET` – S3 bucket for hydrated templates and build artifacts (default `${CF_LOCAL_ENV_ID}-s3-artifacts`) created during setup.
- `CF_LOCAL_AWS_SSO_ROLE` – resolved automatically from the current SSO session; names the shadow IAM role backing the user’s Identity Center permission set so IAM policies can reference the correct principal.

## One-Time AWS Setup
- Before running any scripts, read `docs/notes/sso-cli-setup.md` for Identity Center guidance (browser isolation, delegated admin registration, CLI profiles).
- Admins should complete the delegated-admin step in that note from the payer account, then follow `scripts/admin/README.md` for the dev bootstrap flow.
