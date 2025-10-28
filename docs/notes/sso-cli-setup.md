# AWS SSO + CLI Setup Notes

## Account Structure
- sab-aws (payer) – root user `dbmail1771@gmail.com`
- sab-aws-workload (workload) – root user `dbmail1771+workload@gmail.com`
- IAM Identity Center users:
  - `sab-u-admin` (`dbmail1771+u-admin@gmail.com`)
  - `sab-u-dev` (`dbmail1771+u-dev@gmail.com`)
- Groups: `sab-g-admin` (contains `sab-u-admin`), `sab-g-dev` (contains `sab-u-dev`)
- Permission sets:
  - `sab-ps-chartfinder-admin` (AdministratorAccess)
  - `sab-ps-chartfinder-dev` (PowerUserAccess)
- Assignments (workload account `835972387595`):
  - `sab-g-admin` → `sab-ps-chartfinder-admin`
  - `sab-g-dev` → `sab-ps-chartfinder-dev`

## Access Portal Behavior
- Portal URL: `https://d-9a67513cd2.awsapps.com/start`
- Each browser session is effectively a singleton: once you sign in as a user, that browser profile keeps their SSO cookies. Even deleting cookies just for `d-9a67513cd2.awsapps.com`, `auth.awsapps.com`, and `portal.sso.us-east-2.amazonaws.com` wasn’t enough; wiping **all** site data/cookies in the browser finally forced a fresh login.
- Practical workaround: dedicate separate browsers—Firefox for the payer/root account, Safari for `sab-u-admin`, Chrome for `sab-u-dev`—to avoid cookie churn.
- To force sign-out, hit both:
  - `https://d-9a67513cd2.awsapps.com/start/#/logout`
  - `https://console.aws.amazon.com/console/logout!doLogout`

## CLI Configuration (`sab-u-dev`)
1. `aws configure sso`
   - SSO start URL: `https://d-9a67513cd2.awsapps.com/start`
   - SSO region: `us-east-2` (Identity Center home region—`us-east-1` was unavailable)
   - Registration scopes: press Enter for default `sso:account:access`
   - Account: `835972387595`
   - Permission set: `sab-ps-chartfinder-dev`
   - Default client region: `us-east-2`
   - Default output format: `json`
   - Profile name: `sab-u-dev`
   - During `aws configure sso` the CLI immediately tries to authenticate; use `AWS_SSO_BROWSER=chrome` or the `--no-browser` option so you can complete the sign-in in Chrome instead of Safari.
2. Ensure the CLI raises Chrome for future logins:
   - `export AWS_SSO_BROWSER=chrome` before `aws sso login`
   - If the env var isn’t honored, use `aws sso login --no-browser --profile sab-u-dev` and paste the provided URL/code into Chrome manually.
3. Authenticate: `aws sso login --profile sab-u-dev` (completes browser challenge, caches token)

## Verification
- Confirm caller: `aws sts get-caller-identity --profile sab-u-dev`
  - Expected output shows account `835972387595` and role `arn:aws:sts::835972387595:assumed-role/sab-ps-chartfinder-dev/...`
- After a successful login, subsequent CLI commands using `--profile sab-u-dev` reuse the cached SSO token until it expires (then rerun `aws sso login`).

## Future Automation
- Identity Center SSO tokens are interactive; CI/CD needs a dedicated IAM role or access keys in the workload account (e.g., GitHub OIDC trust, service IAM user).
- Keep these URLs, profile names, and browser assignments documented to avoid repeating the multi-hour troubleshooting.
