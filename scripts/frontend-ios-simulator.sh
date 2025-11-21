#!/bin/bash
# frontend-ios-simulator.sh
# Ensure an iOS simulator is running (boot a preferred device if needed).

SCRIPT_NAME='frontend-ios-simulator'
DEFAULT_SIMULATOR_NAME='iPhone 16'

frontend_ios_sim_log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$1"
}

frontend_ios_sim_usage() {
  cat <<'USAGE'
Usage: ./scripts/frontend-ios-simulator.sh [command]

Commands:
  ensure      Ensure an iOS simulator is booted (default)
  help        Show this help message

Environment:
  CF_FRONTEND_IOS_SIMULATOR_NAME   Preferred simulator name (default: iPhone 18)
USAGE
}

frontend_ios_sim_require_tools() {
  local missing=0
  local tools="xcrun python3"
  for tool in $tools; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      frontend_ios_sim_log "ERROR: Missing required tool '$tool'"
      missing=1
    fi
  done
  return $missing
}

frontend_ios_sim_find_booted_udid() {
  xcrun simctl list devices --json 2>/dev/null | python3 - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for os_devices in data.get("devices", {}).values():
    for entry in os_devices:
        if entry.get("state") == "Booted":
            print(entry.get("udid", ""))
            sys.exit(0)
PY
}

frontend_ios_sim_find_udid_by_name() {
  local desired_name="$1"
  xcrun simctl list devices --json 2>/dev/null | python3 - "$desired_name" <<'PY'
import json, sys
name = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for os_name, os_devices in data.get("devices", {}).items():
    if "iOS" not in os_name and not os_name.lower().startswith("com.apple.core"):  # skip non-iOS
        continue
    for entry in os_devices:
        if entry.get("name") == name and entry.get("isAvailable"):
            print(entry.get("udid", ""))
            sys.exit(0)
PY
}

frontend_ios_sim_ensure() {
  if ! frontend_ios_sim_require_tools; then
    return 1
  fi

  local desired_name="${CF_FRONTEND_IOS_SIMULATOR_NAME:-$DEFAULT_SIMULATOR_NAME}"

  local booted_udid
  booted_udid="$(frontend_ios_sim_find_booted_udid)"
  if [ -n "$booted_udid" ]; then
    frontend_ios_sim_log "Simulator already booted (UDID: $booted_udid)"
    return 0
  fi

  frontend_ios_sim_log "No booted simulator detected; attempting to boot '$desired_name'"
  local target_udid
  target_udid="$(frontend_ios_sim_find_udid_by_name "$desired_name")"
  if [ -z "$target_udid" ]; then
    frontend_ios_sim_log "ERROR: Unable to find simulator named '$desired_name'."
    frontend_ios_sim_log "       Set CF_FRONTEND_IOS_SIMULATOR_NAME to a valid device (see 'xcrun simctl list devices')."
    return 1
  fi

  if ! xcrun simctl boot "$target_udid" >/dev/null 2>&1; then
    frontend_ios_sim_log "ERROR: Failed to boot simulator '$desired_name' (UDID: $target_udid)."
    return 1
  fi

  frontend_ios_sim_log "Booting simulator (UDID: $target_udid)..."
  if ! xcrun simctl bootstatus "$target_udid" -b >/dev/null 2>&1; then
    frontend_ios_sim_log "WARNING: bootstatus check failed; simulator might still be starting."
  fi

  if command -v open >/dev/null 2>&1; then
    open -a Simulator --args -CurrentDeviceUDID "$target_udid" >/dev/null 2>&1 &
  fi
  frontend_ios_sim_log "Simulator '$desired_name' is booting."
}

frontend_ios_sim_main() {
  local cmd="${1:-ensure}"
  case "$cmd" in
    ensure)
      #set -x
      frontend_ios_sim_ensure
      set +x
      ;;
    help|--help|-h)
      frontend_ios_sim_usage
      ;;
    *)
      frontend_ios_sim_log "ERROR: Unknown command '$cmd'"
      frontend_ios_sim_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" = "source-only" ]; then
  true
else
  frontend_ios_sim_main "$@"
fi
