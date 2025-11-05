# AWS SSO + CLI Setup Notes

> Replace placeholders (`<PLACEHOLDER_NAME>`) with your environment-specific values when hydrating a private copy of this document.

## Account Structure
- `<PAYER_ACCOUNT_ALIAS>` (payer) – root user `<PAYER_ROOT_EMAIL>`
- `<WORKLOAD_ACCOUNT_ALIAS>` (workload) – root user `<WORKLOAD_ROOT_EMAIL>`
- IAM Identity Center users:
  - `<SSO_ADMIN_USERNAME>` (`<SSO_ADMIN_EMAIL>`)
  - `<SSO_DEV_USERNAME>` (`<SSO_DEV_EMAIL>`)
- Groups: `<SSO_ADMIN_GROUP_NAME>` (contains `<SSO_ADMIN_USERNAME>`), `<SSO_DEV_GROUP_NAME>` (contains `<SSO_DEV_USERNAME>`)
- Permission sets:
  - `<SSO_ADMIN_PERMISSION_SET>` (AdministratorAccess)
  - `<SSO_DEV_PERMISSION_SET>` (PowerUserAccess)
- Assignments (workload account `<WORKLOAD_ACCOUNT_ID>`):
  - `<SSO_ADMIN_GROUP_NAME>` → `<SSO_ADMIN_PERMISSION_SET>`
  - `<SSO_DEV_GROUP_NAME>` → `<SSO_DEV_PERMISSION_SET>`

## Identity Center Delegated Admin (One-Time)
- Identity Center APIs (e.g., `sso-admin list-permission-sets`) only operate from the home region (`us-east-2`) and require the calling account to be registered as an Identity Center delegated administrator.
- During initial project bootstrap, sign in to the **payer/management account** with credentials that can run AWS Organizations commands (root or equivalent) and execute:
  ```bash
  aws organizations register-delegated-administrator \
    --account-id <WORKLOAD_ACCOUNT_ID> \
    --service-principal sso.amazonaws.com
  ```
- Verify the registration: `aws organizations list-delegated-administrators`.
- Security note: delegating Identity Center grants the workload account authority to manage SSO permission sets. Only perform this for accounts you monitor closely, and review CloudTrail regularly for `sso-admin` activity.
- Without this delegation, workload-account admins (e.g., `<SSO_ADMIN_PERMISSION_SET>`) receive `AccessDeniedException` when the automation tries to push inline policies to Identity Center.

## Access Portal Behavior
- Portal URL: `<SSO_START_URL>`
- Each browser session is effectively a singleton: once you sign in as a user, that browser profile keeps their SSO cookies. Even deleting cookies just for the domains behind `<SSO_START_URL>` (start portal, `auth.awsapps.com`, and the regional Identity Center endpoint) wasn’t enough; wiping **all** site data/cookies in the browser finally forced a fresh login.
- Practical workaround: dedicate separate browsers—Firefox for the payer/root account, Safari for `<SSO_DEV_USERNAME>`, Chrome for `<SSO_ADMIN_USERNAME>`—so CLI login links land in the account they’re meant for.
- To force sign-out, hit both:
  - `<SSO_START_URL>/#/logout`
  - `https://console.aws.amazon.com/console/logout!doLogout`
- One-person shops still need the separation; when the CLI prompts for SSO login, paste the URL into the browser tied to that persona. If the wrong browser holds an active session, the CLI inherits that account’s permission set.

## CLI Configuration (`<DEV_PROFILE_NAME>`)
1. `aws configure sso`
   - SSO start URL: `<SSO_START_URL>`
   - SSO region: `us-east-2` (Identity Center home region—`us-east-1` was unavailable)
   - Registration scopes: press Enter for default `sso:account:access`
   - Account: `<WORKLOAD_ACCOUNT_ID>`
   - Permission set: `<SSO_DEV_PERMISSION_SET>`
   - Default client region: `us-east-2`
   - Default output format: `json`
   - Profile name: `<DEV_PROFILE_NAME>`
   - During `aws configure sso` the CLI immediately tries to authenticate; use `AWS_SSO_BROWSER=chrome` or the `--no-browser` option so you can complete the sign-in in Chrome instead of Safari.
2. Ensure the CLI raises Chrome for future logins:
   - `export AWS_SSO_BROWSER=chrome` before `aws sso login`
   - If the env var isn’t honored, use `aws sso login --no-browser --profile <DEV_PROFILE_NAME>` and paste the provided URL/code into Chrome manually.
3. Authenticate: `aws sso login --profile <DEV_PROFILE_NAME>` (completes browser challenge, caches token)

## Verification
- Confirm caller: `aws sts get-caller-identity --profile <DEV_PROFILE_NAME>`
  - Expected output shows account `<WORKLOAD_ACCOUNT_ID>` and role `arn:aws:sts::<WORKLOAD_ACCOUNT_ID>:assumed-role/<SSO_DEV_PERMISSION_SET_ROLE>/...`
- After a successful login, subsequent CLI commands using `--profile <DEV_PROFILE_NAME>` reuse the cached SSO token until it expires (then rerun `aws sso login`).

## Future Automation
- Identity Center SSO tokens are interactive; CI/CD needs a dedicated IAM role or access keys in the workload account (e.g., GitHub OIDC trust, service IAM user).
- Keep these URLs, profile names, and browser assignments documented to avoid repeating the multi-hour troubleshooting.
