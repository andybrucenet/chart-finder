# AWS Backend Cookbook

## Scope
- Backend workflows when targeting AWS infrastructure.
- Assumes AWS remains the active provider and `.local` files are hydrated.
- Complements infrastructure notes in `infra/aws/` and Identity Center setup docs.

## Daily Flow
- `./scripts/setup-dev-env-aws.sh` (or `./scripts/sync-configs.sh`) to refresh hydrated config.
- `./scripts/aws-sam-preflight.sh` whenever application code or template changes require a rebuild.
- `./scripts/aws-sam-deploy.sh build` for deploys (uses `.local/infra/aws/samconfig.toml` and the current billing env).
- Invoke the deployed API Gateway endpoint (e.g., `/calculator/v1/add/{x}/{y}`) to confirm success.

## IAM & Access
- Ensure the admin bootstrap (`scripts/admin/admin-setup-dev-env.sh`) has been run after any policy edits under `infra/aws/iam/`.
- IAM errors during deploys usually indicate the permission set needs to be rehydrated from `.local/infra/aws/iam/policies/`.

## Troubleshooting
- CloudFormation stack events identify missing IAM actions or resource name conflicts.
- Re-run SAM build before deploy if templates or compiled assets drift.
- Capture persistent issues in `docs/notes/` with timestamps for auditability.
