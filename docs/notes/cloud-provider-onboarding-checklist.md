# Cloud Provider Onboarding Checklist

Use this list whenever we add a new cloud backend (Azure, Google, etc.). Adapt or expand per provider.

1. **Accounts & Access**
   - Confirm project-owned account/subscription exists (or create one).
   - Assign per-developer access model (SSO, service principal, etc.).
   - Document login workflow and required tooling (CLI, SDKs).

2. **Environment Naming & Config**
   - Pick environment prefix/suffix convention (parallel to `CF_LOCAL_ENV_ID`).
   - Define required env vars and add prompts to `setup-dev-env.sh` + provider-specific setup script.
   - Use `docs/notes/environment-variables.md` as the single source of truth; new providers should extend that list rather than duplicating descriptions elsewhere.
   - Capture region/location defaults and limits.

3. **Permissions & IAM**
   - Identify required build/deploy roles.
   - Author policy templates (`.in` files) with variable placeholders.
   - Ensure setup scripts hydrate & link policies into `.local`.

4. **Storage & Artifacts**
   - Decide artifact bucket/container naming.
   - Provision backing storage (S3, Blob, GCS) with locking & encryption settings.
   - Update CI tooling to use the new artifact location.

5. **CI/CD Tooling**
   - Map existing pipelines (CodeBuild/SAM) to provider equivalents.
   - Update buildspec/deploy scripts with conditional logic on `CF_BACKEND_PROVIDER`.
   - Verify required CLIs are available in `setup-dev-env` checks.

6. **Infrastructure Hydration**
   - Add `.in` templates for templates/configs (SAM, ARM/Bicep, Terraform, etc.).
   - Extend `sync-configs.sh` or create provider-specific hydrators.

7. **Local Tooling & Scripts**
   - Add login helpers (mirroring `aws-login.sh` / `aws-logout.sh`).
   - Document local testing strategy (emulators, local stacks).

8. **Validation**
   - Run end-to-end smoke test (provision artifact store, dry-run deploy).
   - Capture troubleshooting notes and update checklist with new gotchas.

Keep this file updated as new providers reveal extra steps.
