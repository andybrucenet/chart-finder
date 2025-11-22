#!/bin/bash
# frontend-android-emulator.sh
# Ensure an Android emulator (AVD) is running so Flutter can target `-d android`.

SCRIPT_NAME='frontend-android-emulator'
DEFAULT_ANDROID_EMULATOR_NAME='pixel_2_pie_9_0_-_api_28'
BOOT_TIMEOUT_SECONDS=180
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ANDROID_RUN_SCRIPT="$SCRIPT_DIR/android-run.sh"

frontend_android_emulator_log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$1"
}

frontend_android_emulator_usage() {
  cat <<'USAGE'
Usage: ./scripts/frontend-android-emulator.sh [command]

Commands:
  ensure      Ensure an Android device/emulator is available (default)
  list-avds   Print the available Android Virtual Devices
  help        Show this help message

Environment:
  ANDROID_SDK_ROOT                    Location of the Android SDK (auto-detected when possible)
  CF_FRONTEND_ANDROID_EMULATOR_NAME   Preferred AVD name (default: Pixel_8_Pro_API_35)
USAGE
}

frontend_android_emulator_require_tools() {
  if [ ! -x "$ANDROID_RUN_SCRIPT" ]; then
    frontend_android_emulator_log "ERROR: Missing helper script '$ANDROID_RUN_SCRIPT'"
    return 1
  fi
  if ! "$ANDROID_RUN_SCRIPT" true >/dev/null 2>&1; then
    frontend_android_emulator_log "ERROR: Unable to locate the Android SDK. Install it or set ANDROID_SDK_ROOT."
    return 1
  fi
  return 0
}

frontend_android_emulator_first_ready_device() {
  "$ANDROID_RUN_SCRIPT" adb devices 2>/dev/null | awk '/\tdevice$/ {print $1; exit 0}'
}

frontend_android_emulator_avd_exists() {
  local name="$1"
  "$ANDROID_RUN_SCRIPT" emulator -list-avds 2>/dev/null | grep -Fxq "$name"
}

frontend_android_emulator_start() {
  local name="$1"
  frontend_android_emulator_log "Starting emulator '$name'..."
  nohup "$ANDROID_RUN_SCRIPT" emulator -avd "$name" -netdelay none -netspeed full >/dev/null 2>&1 &
}

frontend_android_emulator_wait_for_boot() {
  local waited=0
  "$ANDROID_RUN_SCRIPT" adb start-server >/dev/null 2>&1
  while [ $waited -lt $BOOT_TIMEOUT_SECONDS ]; do
    local device_id
    device_id="$(frontend_android_emulator_first_ready_device)"
    if [ -n "$device_id" ]; then
      if "$ANDROID_RUN_SCRIPT" adb -s "$device_id" shell getprop sys.boot_completed 2>/dev/null | grep -q '1'; then
        frontend_android_emulator_log "Device '$device_id' is ready."
        return 0
      fi
    fi
    sleep 5
    waited=$((waited + 5))
  done
  frontend_android_emulator_log "WARNING: Timed out waiting for emulator to boot."
  return 0
}

frontend_android_emulator_ensure() {
  if ! frontend_android_emulator_require_tools; then
    return 1
  fi

  local existing_device
  existing_device="$(frontend_android_emulator_first_ready_device)"
  if [ -n "$existing_device" ]; then
    frontend_android_emulator_log "Android device already available (ID: $existing_device)"
    return 0
  fi

  local desired_name="${CF_FRONTEND_ANDROID_EMULATOR_NAME:-$DEFAULT_ANDROID_EMULATOR_NAME}"
  if ! frontend_android_emulator_avd_exists "$desired_name"; then
    frontend_android_emulator_log "ERROR: No AVD named '$desired_name'."
    frontend_android_emulator_log "       Run 'make frontend-emulators' to list valid names."
    return 1
  fi

  frontend_android_emulator_start "$desired_name"
  frontend_android_emulator_wait_for_boot
}

frontend_android_emulator_list_avds() {
  if ! frontend_android_emulator_require_tools; then
    return 1
  fi
  "$ANDROID_RUN_SCRIPT" emulator -list-avds
}

frontend_android_emulator_main() {
  local cmd="${1:-ensure}"
  case "$cmd" in
    ensure)
      frontend_android_emulator_ensure
      ;;
    list-avds)
      frontend_android_emulator_list_avds
      ;;
    help|--help|-h)
      frontend_android_emulator_usage
      ;;
    *)
      frontend_android_emulator_log "ERROR: Unknown command '$cmd'"
      frontend_android_emulator_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" = "source-only" ]; then
  true
else
  frontend_android_emulator_main "$@"
fi
