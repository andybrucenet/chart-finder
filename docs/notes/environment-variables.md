# Environment Variables

These settings are hydrated by `./scripts/setup-dev-env.sh`, which writes `.local/local.env` and keeps every helper script sourced. Run the setup script instead of exporting values manually.

## Common ChartFinder Settings
- `CF_HOME` – absolute path to the local repository so multiple clones can coexist.
- `CF_LOCAL_PRJ_ID` – short project slug (policy value `cf`) prefixed to shared resource names.
- `CF_LOCAL_DOMAIN` – public domain for endpoints (policy value `chart-finder.app`).
- `CF_LOCAL_CLOUD_PROVIDER` – active cloud provider for the workspace (`aws` today; extend as new providers come online).
- `CF_LOCAL_TLS_CERT_PATH` – absolute path to the wildcard certificate (`cert.pem`).
- `CF_LOCAL_TLS_CHAIN_PATH` – absolute path to the wildcard certificate chain (`chain.pem`).
- `CF_LOCAL_TLS_KEY_PATH` – absolute path to the wildcard private key (`privkey.pem`).
- `CF_LOCAL_DEV_ID` – logical owner/persona (default `<login>-dev`) used in per-developer stacks.
- `CF_LOCAL_BILLING_ENV` – billing/tag value (default `dev`) for environment scoping.
- `CF_LOCAL_ENV_ID` – composite `${CF_LOCAL_PRJ_ID}-${CF_LOCAL_DEV_ID}` identifier reused across stacks.
- `CF_LOCAL_USEREMAIL` – reachable contact injected into tags and notifications.

## AWS-Specific Settings
- `CF_LOCAL_AWS_PROFILE` – default CLI profile (`${CF_LOCAL_DEV_ID}-${CF_LOCAL_PRJ_ID}-${CF_LOCAL_BILLING_ENV}`).
- `CF_LOCAL_AWS_REGION` – primary AWS region for the workspace.
- `CF_LOCAL_AWS_ARTIFACT_BUCKET` – S3 bucket for hydrated templates and build artifacts (`${CF_LOCAL_ENV_ID}-s3-artifacts` by default).
- `CF_LOCAL_AWS_SSO_ROLE` – resolved Identity Center role name backing the current session.

Treat this file as the canonical reference when new providers or scripts require additional environment variables.
