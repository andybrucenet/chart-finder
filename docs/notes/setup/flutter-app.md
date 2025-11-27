# Flutter App Setup

Project-scoped checklist for scaffolding Flutter platforms inside the Chart Finder repo.

> Forking this workflow for another product? Update `scripts/update-version.sh` (see `write_frontend_metadata`) so the generated `frontend/version.json` contains your new company/product names **before** running the steps below; everything downstream (slugs, bundle IDs, etc.) derives from that metadata.

## 1. Folder Name vs. Dart Package Name
- Flutter lets the **directory** use hyphens (e.g., `chart-finder-flutter`) but the **Dart package name** must use lowercase letters, numbers, and underscores (`chart_finder_flutter`).  
- We expose the normalized identifiers in the generated version metadata (`VersionInfo.companySnake`, `VersionInfo.productSnake`) and export them via `CF_GLOBAL_*_SLUG` so every stack can reuse the same naming rules at build time (the slug comes from `lcl_string_to_slug` in `scripts/lcl-os-checks.sh`).  
- When you run `flutter create` inside an existing folder, always pass `--project-name` (use `versionInfo.productSnake` if you want the normalized product name) so the generated platform code (Android package IDs, iOS bundle identifiers, etc.) reuses the underscore form:
  ```bash
  cd src/frontend/chart-finder-flutter
  # Derive the underscore-safe project name from the shared env helper.
  PRODUCT_SNAKE="$(../../../scripts/cf-env-vars.sh CF_GLOBAL_PRODUCT_SLUG)"
  fvm flutter create \
    --project-name "$PRODUCT_SNAKE" \
    --platforms android \
    .
  ```
- Reusing this pattern prevents the “`<name>` is not a valid Dart package name” error you hit when the folder contains dashes.

## 2. Adding Platforms to an Existing App
Run `flutter create` only once per platform; the command is idempotent and skips folders that already exist. Examples:

```bash
# Add Android support (Gradle project under android/)
PRODUCT_SNAKE="$(../../../scripts/cf-env-vars.sh CF_GLOBAL_PRODUCT_SLUG)"
fvm flutter create --project-name "$PRODUCT_SNAKE" --platforms android .

# Add the remaining desktop/Apple shells later
PRODUCT_SNAKE="$(../../../scripts/cf-env-vars.sh CF_GLOBAL_PRODUCT_SLUG)"
fvm flutter create --project-name "$PRODUCT_SNAKE" --platforms ios,macos,windows .
```

After each run:
1. Inspect the new platform folder (`android/`, `ios/`, etc.) and commit it if it belongs in source control.
2. Rerun the relevant Make target (`make frontend-build`, `make frontend-build-ios`, etc.) to ensure Flutter recognizes the scaffold.

## 3. Verification Steps
1. Hydrate toolchains: follow [`docs/notes/setup/flutter-fvm.md`](./flutter-fvm.md) to pin FVM/Flutter, then install Android Studio, Xcode, or Visual Studio depending on the platform.
2. Run `fvm flutter doctor` after each `flutter create …` call to confirm no new dependencies are missing.
3. Use the stack-specific Make targets:
   - `make frontend-build` → Android debug APK (host-agnostic)
   - `make frontend-build-ios` → iOS simulator build (macOS only)
   - `make frontend-build-macos` → macOS desktop app (macOS only)
   - `make frontend-build-windows` → Windows desktop app (Windows hosts)

Keep this guide handy when adding new Flutter apps or renaming folders; reusing the same `--project-name` convention keeps every downstream tool (Gradle, CocoaPods, FVM) aligned.***
