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

## Permission-Set + Inline Policy Bootstrap
Identity Center assignments alone are not enough—the stack deploy needs extra IAM actions (e.g., `iam:CreateRole`, `iam:TagRole`, `iam:PutRolePolicy`). Keep the long-form procedure here so every change is documented once.

### Developer Checklist
1. Run `make setup-dev-env` to hydrate `.local/` with your values (account ID, artifact bucket name, region, `CF_LOCAL_DEV_ID`, etc.).  
2. Verify `.local/local.env` contains:
   - `CF_LOCAL_BILLING_ENV`, `CF_LOCAL_ENV_ID`, `CF_LOCAL_AWS_REGION`, `CF_LOCAL_AWS_ACCOUNT_ID`
   - `CF_LOCAL_AWS_ARTIFACT_BUCKET` (usually `<env-id>-s3-artifacts`)
   - `CF_LOCAL_USEREMAIL`
3. Commit IAM template changes (if any) under `infra/aws/iam/**` so admins can regenerate their `.local` copies.
4. Share your hydrated `.local/` (or just the `infra/aws/iam` + `.local/local.env` payload) with the admin persona that owns the workload account. Never commit `.local/` to Git; hand the bundle to the admin over a secure channel.

### Admin Bootstrap Script
Admins run `scripts/admin/admin-setup-dev-env.sh /path/to/dev/.local` from the repo root *while authenticated as the AWS administrator persona* (the CLI profile must map to the workload account and have permission to write IAM, S3, and Identity Center resources). The script wraps `admin-setup-dev-env-aws.sh` and performs:

1. **Artifact bucket provisioning** – creates or updates `CF_LOCAL_AWS_ARTIFACT_BUCKET`, enables versioning + AES256 encryption, and tags it (`Project`, `Environment`, `Owner`).  
2. **CodeBuild execution policy** – hydrates `infra/aws/iam/policies/codebuild-exec-permissions.json` into an account-scoped managed policy (`${CF_LOCAL_ENV_ID}-codebuild-exec-policy`) and prunes stale versions so the IAM limit (5) isn’t exceeded.  
3. **CodeBuild role** – creates/updates `${CF_LOCAL_ENV_ID}-codebuild-exec-role`, applies the hydrated trust policy, and attaches the managed policy.  
4. **Identity Center inline policy** – reads `.local/infra/aws/iam/policies/dev-permission-set-inline-policy.json` and applies it via `aws sso-admin put-inline-policy-to-permission-set`, then triggers `provision-permission-set` so the changes replicate to the workload account. Use the environment variables below to override detection when multiple permission sets or Identity Center regions exist:
   - `ADMIN_SETUP_DEV_ENV_AWS_SSO_REGION`
   - `ADMIN_SETUP_DEV_ENV_AWS_SSO_INSTANCE_ARN`
   - `ADMIN_SETUP_DEV_ENV_AWS_PERMISSION_SET_ARN`
   - `ADMIN_SETUP_DEV_ENV_AWS_PERMISSION_SET_NAME`

The script requires `aws --profile <admin>` to resolve to the same account as `CF_LOCAL_AWS_ACCOUNT_ID`. If they differ, the script stops before creating resources.

### Common IAM Failures
- **CloudFormation can’t create roles/policies** – rerun the admin bootstrap so the inline policy grants `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:TagRole`, etc., scoped to `arn:aws:iam::<account>:role/cf-*-*`.  
- **`sso-admin` throttling or `AccessDenied`** – confirm the workload account was registered as the Identity Center delegated administrator (see earlier section).  
- **Artifact bucket access denied** – ensure the bucket exists in `CF_LOCAL_AWS_REGION` and the admin bootstrap tagged/encrypted it correctly; retry `admin-setup-dev-env-aws.sh` after fixing any naming mismatch.  

Document any new IAM action requirements in `infra/aws/iam/policies/*` and rerun the admin bootstrap so every developer inherits the change.

## Future Automation
- Identity Center SSO tokens are interactive; CI/CD needs a dedicated IAM role or access keys in the workload account (e.g., GitHub OIDC trust, service IAM user).
- Keep these URLs, profile names, and browser assignments documented to avoid repeating the multi-hour troubleshooting.
