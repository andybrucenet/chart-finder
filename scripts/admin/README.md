# README for scripts/admin

These scripts are for admin user to run to apply permissions correctly for a dev user. Using this approach ensures:
* Dev users have least-privileges for running commands.
* The process can reasonably be automated (e.g. dev user places a zip file in a shared folder; zip file is consumed automatically by the admin).

## Prerequisite
- From the payer/management account (Identity Center home region `us-east-2`), register the workload account (`<WORKLOAD_ACCOUNT_ID>`) as the delegated administrator for Identity Center so the automation can call `sso-admin` APIs:
  ```
  aws organizations register-delegated-administrator \
    --account-id <WORKLOAD_ACCOUNT_ID> \
    --service-principal sso.amazonaws.com
  ```
  Confirm with `aws organizations list-delegated-administrators`. Delegation grants sensitive SSO management rights to the workload account—ensure it’s monitored and reviewed via CloudTrail.

## Standard Flow

Flow is:
1. Dev user runs `scripts/setup-dev-env.sh`. This creates a local folder `.local` for that dev user with all policy files hydrated to provide permissions for that dev user to issue build commands.

1. Dev user zips `.local` folder and sends to admin.

1. Admin unzips `.local` folder to a location such as `/tmp/dev-user` and then runs:
    ```
    AWS_PROFILE=sab-u-admin ./scripts/admin/admin-setup-dev-env.sh /tmp/dev-user/.local
    ```

1. Admin notifies dev user that permissions are granted.

Note that on any change / update to permissions in source control this process must be repeated.

## Useful Recipes

For abruce macOS dev environment use this:
```
AWS_PROFILE=sab-u-admin ./scripts/admin/admin-setup-dev-env.sh ~/proj/git/src/github.com/andybrucenet/chart-finder/.local
```
