#!/bin/bash
# android-run.sh
# Detect ANDROID_SDK_ROOT if missing, update PATH, then run the requested command.

# resolve directories
android_run_source="${BASH_SOURCE[0]}"
while [ -h "$android_run_source" ]; do
  android_run_dir="$( cd -P "$( dirname "$android_run_source" )" >/dev/null 2>&1 && pwd )"
  android_run_source="$(readlink "$android_run_source")"
  [[ $android_run_source != /* ]] && android_run_source="$android_run_dir/$android_run_source"
done
android_run_script_dir="$( cd -P "$( dirname "$android_run_source" )" >/dev/null 2>&1 && pwd )"
android_run_root_dir="$( realpath "$android_run_script_dir"/.. )"

# load shared environment (g_* globals, CF_* vars, etc.)
source "$android_run_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

ANDROID_RUN_SCRIPT_NAME='android-run'
ANDROID_RUN_DEFAULT_MAC_SDK="$HOME/Library/Android/sdk"
ANDROID_RUN_DEFAULT_MAC_XAMARIN_SDK="$HOME/Library/Developer/Xamarin/android-sdk-macos"
ANDROID_RUN_DEFAULT_LINUX_SDK="$HOME/Android/Sdk"
ANDROID_RUN_DEFAULT_WINDOWS_SDK="${USERPROFILE:-}/AppData/Local/Android/Sdk"

android_run_log() {
  local i_message="$1"
  printf '[%s] %s\n' "$ANDROID_RUN_SCRIPT_NAME" "$i_message"
}

android_run_usage() {
  cat <<'USAGE'
Usage: ./scripts/android-run.sh <command> [args...]

Detects the Android SDK location when ANDROID_SDK_ROOT is unset (prefers the standard per-OS path),
prepends the relevant SDK bin folders to PATH, and then execs the given command.
Special handling ensures:
  * `emulator` uses $ANDROID_SDK_ROOT/emulator/emulator when available.
  * `adb` uses $ANDROID_SDK_ROOT/platform-tools/adb when available.

Examples:
  ./scripts/android-run.sh emulator -list-avds
  ./scripts/android-run.sh adb devices
USAGE
}

android_run_detect_sdk() {
  if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
    return 0
  fi
  if [ -n "${ANDROID_HOME:-}" ]; then
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    return 0
  fi

  local l_candidates=()
  if [ "${g_IS_MAC:-0}" -eq 1 ]; then
    l_candidates+=("$ANDROID_RUN_DEFAULT_MAC_SDK")
    l_candidates+=("$ANDROID_RUN_DEFAULT_MAC_XAMARIN_SDK")
  elif [ "${g_IS_LINUX:-0}" -eq 1 ]; then
    l_candidates+=("$ANDROID_RUN_DEFAULT_LINUX_SDK")
  elif [ "${g_IS_CYGWIN:-0}" -eq 1 ] || [ "${g_IS_MINGW:-0}" -eq 1 ]; then
    l_candidates+=("$ANDROID_RUN_DEFAULT_WINDOWS_SDK")
    l_candidates+=("${ANDROID_RUN_DEFAULT_WINDOWS_SDK/android-sdk/Sdk}")
  fi

  local l_path
  for l_path in "${l_candidates[@]}"; do
    if [ -n "$l_path" ] && [ -d "$l_path" ]; then
      export ANDROID_SDK_ROOT="$l_path"
      return 0
    fi
  done

  android_run_log "ERROR: ANDROID_SDK_ROOT is not set and no SDK directory was found."
  android_run_log "       Install the Android SDK or export ANDROID_SDK_ROOT explicitly."
  return 1
}

android_run_update_path() {
  local l_sdk="$ANDROID_SDK_ROOT"
  [ -d "$l_sdk/emulator" ] && PATH="$l_sdk/emulator:$PATH"
  [ -d "$l_sdk/platform-tools" ] && PATH="$l_sdk/platform-tools:$PATH"
  [ -d "$l_sdk/tools" ] && PATH="$l_sdk/tools:$PATH"
  [ -d "$l_sdk/tools/bin" ] && PATH="$l_sdk/tools/bin:$PATH"
  export PATH
}

android_run_exec() {
  local i_cmd="$1"; shift || true
  case "$i_cmd" in
    emulator)
      if [ -x "$ANDROID_SDK_ROOT/emulator/emulator" ]; then
        exec "$ANDROID_SDK_ROOT/emulator/emulator" "$@"
      fi
      ;;
    adb)
      if [ -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]; then
        exec "$ANDROID_SDK_ROOT/platform-tools/adb" "$@"
      fi
      ;;
  esac
  exec "$i_cmd" "$@"
}

android_run_main() {
  if [ $# -lt 1 ]; then
    android_run_usage
    return 1
  fi

  local l_cmd="$1"
  shift

  if ! android_run_detect_sdk; then
    return 1
  fi

  if [ "$l_cmd" = "status" ] || [ "$l_cmd" = "info" ]; then
    android_run_log "ANDROID_SDK_ROOT='${ANDROID_SDK_ROOT}'"
    android_run_update_path
    local l_emulator="$ANDROID_SDK_ROOT/emulator/emulator"
    local l_adb="$ANDROID_SDK_ROOT/platform-tools/adb"
    [ -x "$l_emulator" ] && android_run_log "emulator binary: $l_emulator" || android_run_log "emulator binary not found under SDK"
    [ -x "$l_adb" ] && android_run_log "adb binary: $l_adb" || android_run_log "adb binary not found under SDK"
    return 0
  fi

  android_run_update_path
  android_run_exec "$l_cmd" "$@"
}

if [ "${1:-}" != "source-only" ]; then
  android_run_main "$@"
else
  true
fi
