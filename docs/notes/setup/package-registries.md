# Package Registry Setup

Authoritative checklist for authenticating against each registry Chart Finder publishes to. Store tokens/keys outside the repo (password manager or OS keychain) and hydrate `.local/local.env` with any variables noted below.

## npm (TypeScript SDK)
1. Create / sign in to an npm account with 2FA enabled.  
2. Run `npm login --scope=@andybrucenet --registry=https://registry.npmjs.org` so the scoped token lands in `~/.npmrc`.  
3. Verify with `npm whoami` and `npm config get //registry.npmjs.org/:_authToken` (should return a masked value).  
4. Optional: create an automation token (`npm token create --read-only=false`) and store it in a password manager.  
5. To reuse the token on new machines, add the line below to `~/.npmrc` (do **not** commit it):  
   ```
   //registry.npmjs.org/:_authToken=${NPM_PUBLISH_TOKEN}
   ```  
   Then export `NPM_PUBLISH_TOKEN` in your shell or secrets manager before running publishes.

## NuGet (.NET SDK)
1. Sign in to [nuget.org](https://www.nuget.org/) using a Microsoft account.  
2. Create an API key scoped to the `ChartFinder.Client` package with “Push” permission.  
3. Store the API key securely and add it to your local env by editing `.local/local.env` (or rerun `scripts/setup-dev-env.sh` when prompts exist) so it contains:  
   ```
   CF_LOCAL_BACKEND_API_KEY_NUGET_ORG=<nuget-api-key>
   ```  
4. Validate access:
   ```bash
   dotnet nuget list source
   dotnet nuget push /path/to/pkg.nupkg \
     --source https://api.nuget.org/v3/index.json \
     --api-key "$CF_LOCAL_BACKEND_API_KEY_NUGET_ORG" \
     --skip-duplicate
   ```
5. The backend client publish scripts (`backend/clients/scripts/clients-publish-all.sh`) read `CF_LOCAL_BACKEND_API_KEY_NUGET_ORG`; runs fail fast if it is missing.

## pub.dev (Dart SDK)
1. Install Dart (bundled with Flutter or via `brew install dart`).  
2. Run `dart pub token add https://pub.dev` (or the interactive `dart pub publish` flow) to authenticate; this stores credentials under `$HOME/.pub-cache/credentials.json`.  
3. To create/transfer a publisher:
   - Sign in to <https://pub.dev/> with the account owning the DNS domain.  
   - Add the TXT record that pub.dev prompts for (we use Cloudflare).  
   - Approve the verification email and assign maintainers (e.g., `sab.chartfinder@gmail.com`).  
4. Before publishing the generated client, dry-run the package:
   ```bash
   cd .local/backend/clients/dart
   dart pub publish --dry-run
   dart pub publish --force
   ```
5. If the CLI prompts for login again, complete it in the browser; the cached credentials refresh automatically.

## Next Steps
- Whenever tokens rotate or new registries come online, update this doc first, then refresh any references (e.g., `backend/clients/README.md`, onboarding playbooks).  
- Keep `.local/local.env` in sync so build automation consistently reads the latest secrets without checking them into Git.
