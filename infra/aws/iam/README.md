# AWS IAM Assets

- Prefix all identities and policies with `sab-chart-finder-` so they are easy to search for and avoid collisions.
- Store JSON policy documents under `policies/` and trust policies or other role metadata under `roles/`.
- Keep any helper notes or automation scripts in this directory so IAM changes remain versioned alongside application infrastructure.
- Hydrated copies live under `.local/infra/aws/iam/`; use those when applying updates with the AWS CLI or Console.
- Extend `policies/codebuild-exec-permissions.json.in` with additional statements (CloudFormation, Secrets Manager, etc.) as CI/CD capabilities expand.
