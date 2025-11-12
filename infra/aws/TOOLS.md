# AWS Tooling

Install these locally before running the AWS setup scripts:
- `aws` CLI – authenticated via Identity Center (`scripts/aws-login.sh`).
- `sam` CLI – builds and deploys the Lambda stack.
- `jq` – parses CLI responses inside helper scripts.
- `dos2unix` – tidies hydrated policy files before hashing or uploads.

All commands should be wrapped with `scripts/aws-run-cmd.sh` so the hydrated `.local` environment is respected.
