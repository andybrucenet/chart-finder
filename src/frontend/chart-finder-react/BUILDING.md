# Building

Note: typically you will *not* build from here. Instead, move to the `frontend` folder directly under the project root and there is a `Makefile` with all the expected lifecycle targets. Review that folder for more information.

For historical purposes we document some basic install / build steps here.

1. Install dependencies:
   ```bash
   cd src/frontend/chart-finder-react
   npm install
   ```
2. Launch Expo with the calculator API base URL (custom domain or gateway output):
   ```bash
   EXPO_PUBLIC_API_BASE_URL="https://<api-host>" npx expo start --localhost
   ```
3. From the Expo CLI prompt:
   - Press `i` to boot the iOS simulator, or
   - Press `a` for Android (requires Android Studio/emulator).
4. If the simulator prompts to open Expo Go, accept it; you should see the “Chart Finder Mobile” screen.

Use the Expo Dev Menu (shake simulator or press `Cmd+D`) to reload or clear cache when testing API changes.
