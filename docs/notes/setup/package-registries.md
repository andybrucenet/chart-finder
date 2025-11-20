# Package Registry Setup

Authoritative checklist for authenticating against each registry Chart Finder publishes to. Store tokens/keys outside the repo (password manager or OS keychain) and hydrate `.local/local.env` with any variables noted below.

## npm (TypeScript SDK)
> npm does **not** accept a custom API key for this workflow; you must perform an interactive `npm login` once per machine and let npm store the token in `~/.npmrc`.

1. Create / sign in to an npm account with 2FA enabled.  
2. Run `npm login --scope=@andybrucenet --registry=https://registry.npmjs.org` and complete the CLI prompts. npm writes the resulting auth token to `~/.npmrc` in plaintext, similar to how the AWS CLI caches tokens.  
3. Verify with `npm whoami`. There is no supported way (in this project) to inject an alternate token via env var; rely on npm’s own credential store.  
4. When rotating credentials, run `npm logout` followed by `npm login` again. Keep the `.npmrc` file out of Git—Git already ignores it by default.

## NuGet (.NET SDK)
1. Sign in to [nuget.org](https://www.nuget.org/) using a Microsoft account.  
2. Create an API key scoped to the `ChartFinder.Client` package with “Push” permission.  
3. Store the API key securely. When `make setup-dev-env` prompts for “NuGet API key,” supply the value so it’s written to `.local/local.env` automatically (never edit that file by hand). If you ever rotate the key, rerun `make setup-dev-env` and re-enter the new value.  
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
2. Create/transfer a publisher:
   - Sign in to <https://pub.dev/> with the Google account that owns the target domain.  
   - Follow pub.dev’s prompt to add a DNS TXT record proving domain ownership (we manage the record in Cloudflare).  
   - Once verified, assign maintainers (e.g., `sab.chartfinder@gmail.com`).  
3. Run `dart pub publish` the first time you push a new package. The CLI opens a browser, confirms the DNS TXT record, and returns a token that Dart stores under `$HOME/.pub-cache/credentials.json` automatically. No manual API key management is required after the initial verification.  
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
