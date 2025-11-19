# Chart Finder Flutter

Seed workspace for the future Flutter client. The goal is to keep a runnable
shell with zero product assumptions so we can layer in navigation, state
management, and backend integration later.

## Prerequisites

- Flutter 3.24+ with the stable channel selected.
- Dart SDK bundled with Flutter (no global installs needed beyond `flutter`).
- Xcode / Android Studio only if you plan to run the iOS or Android simulators.

## First Run

```bash
cd src/frontend/chart-finder-flutter
flutter pub get
flutter run -d chrome   # pick any device/simulator you prefer
```

The starter app renders a single screen that confirms the build is wired up.

## Next Steps

- Decide on the navigation pattern (GoRouter, Navigator 2.0, etc.).
- Wire the generated Dart client (`chart_finder_client`) once the backend API
  surface settles.
- Integrate shared version/build metadata so the Flutter app mirrors the Expo
  client’s `VersionScreen`.
