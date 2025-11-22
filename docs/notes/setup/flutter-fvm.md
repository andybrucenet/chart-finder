# Flutter + FVM Setup

Chart Finder pins Flutter via [FVM](https://fvm.app/) so every developer, CI run, and IDE shares the same SDK bits. Follow these steps per machine.

## Install Dart + FVM
1. Ensure Dart is available (`brew install dart`, `choco install dart-sdk`, or install Flutter which bundles Dart).  
2. Activate FVM globally **using the system Dart you want future shells to prefer** (e.g., Homebrew’s `/usr/local/bin/dart` on macOS) so the generated snapshot matches that runtime:
   ```bash
   env PATH="/usr/local/bin:$PATH" /usr/local/bin/dart pub global deactivate fvm || true
   env PATH="/usr/local/bin:$PATH" /usr/local/bin/dart pub global activate fvm
   ```
   If you ever see kernel-format or “fvm … doesn’t support Dart X.Y” errors, make sure the wrapper is pointing at a snapshot built by your preferred Dart. The snapshots live under `~/.pub-cache/global_packages/fvm/bin/`; deleting the incompatible one is safe as long as you re-run the `dart pub global activate fvm` command above immediately afterward.
3. Add FVM to your PATH if needed (macOS/Linux) **after** higher-priority toolchains (e.g., keep `/usr/local/bin` ahead of any Flutter SDK bins so `dart pub …` keeps using the Homebrew SDK):
   ```bash
   export PATH="$HOME/.pub-cache/bin:$PATH"
   ```
   If you temporarily prepend `.fvm/flutter_sdk/bin` to PATH for Flutter builds, make sure you drop it (or re-order PATH) before running `dart pub global activate …` again; otherwise FVM may reactivate under Flutter’s bundled Dart and reintroduce the kernel-format mismatch.

## Pin the Project Version
1. Change into the Flutter app:
   ```bash
   cd src/frontend/chart-finder-flutter
   ```
2. Install the version recorded in `.fvm/fvm_config.json` (create the file if it doesn’t exist yet):  
   ```bash
   # Example version; replace with the value agreed on by the team.
   fvm install 3.24.0
   fvm use 3.24.0 --force
   ```
   This generates `.fvm/fvm_config.json`:
   ```json
   {
     "flutterSdkVersion": "3.24.0",
     "flavors": {}
   }
   ```
   Commit the config (and `.fvm/fvm_config.json`) so teammates automatically pick up the pinned SDK. The actual Flutter SDK sits under `.fvm/flutter_sdk/` and is ignored by Git.

## Run Commands via FVM
- Replace `flutter ...` with `fvm flutter ...` (or `fvm dart ...`) so the pinned SDK is always used:  
  ```bash
  fvm flutter doctor
  fvm flutter pub get
  fvm flutter run -d chrome
  ```
- If you need to call Flutter without `fvm`, export the shimmed SDK path:
  ```bash
  export FLUTTER_ROOT="$(pwd)/.fvm/flutter_sdk"
  export PATH="$FLUTTER_ROOT/bin:$PATH"
  ```

## IDE Integration
- **VS Code** – add this to `.vscode/settings.json` inside `chart-finder-flutter`:
  ```json
  {
    "dart.flutterSdkPath": ".fvm/flutter_sdk"
  }
  ```
- **Android Studio / IntelliJ** – open *Preferences → Languages & Frameworks → Flutter* and point to `<repo>/src/frontend/chart-finder-flutter/.fvm/flutter_sdk`.

## Verifying the Setup
```bash
cd src/frontend/chart-finder-flutter
fvm flutter doctor
fvm flutter pub get
fvm flutter run -d chrome
```

Document any SDK upgrades (and update `.fvm/fvm_config.json`) in `docs/notes/current-chat.md` or a dedicated changelog before committing.
