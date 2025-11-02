# Backend Configuration Notes

## DynamoDB Settings
- Configuration section: `Dynamo`
- Options bound to `ChartFinder.Api.Configuration.DynamoOptions`
- Keys:
  - `TableName` (required)
  - `Region` (optional override; defaults to process region)

## Local Development Workflow
1. Defaults live in `src/backend/ChartFinder.Api/appsettings.json` and `appsettings.Development.json`.
2. Override secrets locally with `dotnet user-secrets` so nothing sensitive lands in Git:
   ```bash
   cd <REPO_ROOT>
   dotnet user-secrets --project src/backend/ChartFinder.Api/ChartFinder.Api.csproj set "Dynamo:TableName" "ChartFinder-dev-yourname"
   dotnet user-secrets --project src/backend/ChartFinder.Api/ChartFinder.Api.csproj set "Dynamo:Region" "us-east-2"
   ```
3. To inspect current overrides:
   ```bash
   dotnet user-secrets --project src/backend/ChartFinder.Api/ChartFinder.Api.csproj list
   ```
4. When running locally, set `AWS_PROFILE=<DEV_PROFILE_NAME>` (or equivalent) so the SDK uses the Identity Center session.

## Deployment
- SAM template in `infra/aws/serverless.template` injects the table name via environment variable. Expand that template or Parameter Store later rather than editing committed settings.
