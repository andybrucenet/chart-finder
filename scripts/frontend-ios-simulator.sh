#!/bin/bash
# frontend-ios-simulator.sh
# Ensure an iOS simulator is running (boot a preferred device if needed).

the_frontend_ios_sim_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_ios_sim_source" ]; do
  the_frontend_ios_sim_dir="$( cd -P "$( dirname "$the_frontend_ios_sim_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_ios_sim_source="$(readlink "$the_frontend_ios_sim_source")"
  [[ $the_frontend_ios_sim_source != /* ]] && the_frontend_ios_sim_source="$the_frontend_ios_sim_dir/$the_frontend_ios_sim_source"
done
the_frontend_ios_sim_script_dir="$( cd -P "$( dirname "$the_frontend_ios_sim_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_ios_sim_root_dir="$( realpath "$the_frontend_ios_sim_script_dir"/.. )"

SCRIPT_NAME='frontend-ios-simulator'
DEFAULT_SIMULATOR_NAME='iPhone 16'
frontend_ios_sim_helper_script="$the_frontend_ios_sim_root_dir/scripts/helpers/frontend-ios-simctl-utils.py"
the_frontend_ios_sim_state_dir="$the_frontend_ios_sim_root_dir/.local/state"
the_frontend_ios_sim_udid_file="$the_frontend_ios_sim_state_dir/frontend-ios-simulator.udid"

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

frontend_ios_sim_helper_script="$the_frontend_ios_sim_root_dir/scripts/helpers/frontend-ios-simctl-utils.py"

frontend_ios_sim_run_helper() {
  local i_command="$1"
  shift
  if [ ! -x "$frontend_ios_sim_helper_script" ]; then
    frontend_ios_sim_log "ERROR: Missing helper $frontend_ios_sim_helper_script"
    return 1
  fi

  local l_json_tmp l_err_tmp l_helper_err tmp_status l_output
  l_json_tmp="$(mktemp "${TMPDIR:-/tmp}/ios-simctl-json.XXXXXX")" || return 1
  l_err_tmp="$(mktemp "${TMPDIR:-/tmp}/ios-simctl-err.XXXXXX")" || {
    rm -f "$l_json_tmp"
    return 1
  }

set -x
  if ! xcrun simctl list devices --json >"$l_json_tmp" 2>"$l_err_tmp"; then
    frontend_ios_sim_log "ERROR: 'xcrun simctl list devices --json' failed (command=$i_command)"
    sed 's/^/  | /' "$l_err_tmp"
    rm -f "$l_json_tmp" "$l_err_tmp"
    return 1
  fi
  rm -f "$l_err_tmp"
set +x

  l_helper_err="$(mktemp "${TMPDIR:-/tmp}/ios-simctl-helper.XXXXXX")" || {
    rm -f "$l_json_tmp"
    return 1
  }
  if ! l_output="$(python3 "$frontend_ios_sim_helper_script" "$i_command" "$@" <"$l_json_tmp" 2>"$l_helper_err")"; then
    frontend_ios_sim_log "ERROR: Helper command '$i_command' failed to parse simctl output"
    frontend_ios_sim_log "Raw simctl JSON (truncated):"
    head -n 40 "$l_json_tmp" | sed 's/^/  | /'
    frontend_ios_sim_log "Helper stderr:"
    sed 's/^/  | /' "$l_helper_err"
    rm -f "$l_json_tmp" "$l_helper_err"
    return 1
  fi

  printf '%s' "$l_output"
  rm -f "$l_json_tmp" "$l_helper_err"
  return 0
}

frontend_ios_sim_find_booted_udid() {
  frontend_ios_sim_run_helper find-booted
}

frontend_ios_sim_list_available() {
  frontend_ios_sim_log "Available simulators (iOS only):"
  local l_output
  if ! l_output="$(frontend_ios_sim_run_helper list-available)"; then
    frontend_ios_sim_log "  (unable to list simulators)"
    return 1
  fi
  printf '%s\n' "$l_output" | sed 's/^/  - /'
}

frontend_ios_sim_find_udid_by_name() {
  local desired_name="$1"
  frontend_ios_sim_run_helper find-udid "$desired_name"
}

frontend_ios_sim_write_udid() {
  local i_udid="$1"
  [ -z "$i_udid" ] && return 0
  mkdir -p "$the_frontend_ios_sim_state_dir" || return 1
  {
    printf 'UDID=%s\n' "$i_udid"
    printf 'NAME=%s\n' "${CF_FRONTEND_IOS_SIMULATOR_NAME:-}"
  } >"$the_frontend_ios_sim_udid_file"
}

frontend_ios_sim_clear_udid() {
  rm -f "$the_frontend_ios_sim_udid_file"
}

frontend_ios_sim_target() {
  if [ -s "$the_frontend_ios_sim_udid_file" ]; then
    local l_udid
    l_udid="$(grep '^UDID=' "$the_frontend_ios_sim_udid_file" | head -n1 | cut -d= -f2-)"
    if [ -n "$l_udid" ]; then
      printf '%s\n' "$l_udid"
      return 0
    fi
  fi
  printf '%s\n' "${CF_FRONTEND_IOS_SIMULATOR_NAME:-ios}"
}

frontend_ios_sim_ensure() {
  if ! frontend_ios_sim_require_tools; then
    return 1
  fi

  local desired_name="${CF_FRONTEND_IOS_SIMULATOR_NAME:-$DEFAULT_SIMULATOR_NAME}"
  if [ -z "$desired_name" ]; then
    frontend_ios_sim_log "ERROR: CF_FRONTEND_IOS_SIMULATOR_NAME is empty and no default is set"
    return 1
  fi

  local booted_udid
  booted_udid="$(frontend_ios_sim_find_booted_udid)"
  if [ -n "$booted_udid" ]; then
    frontend_ios_sim_log "Simulator already booted (UDID: $booted_udid)"
    frontend_ios_sim_write_udid "$booted_udid"
    return 0
  fi

  frontend_ios_sim_log "No booted simulator detected; attempting to boot '$desired_name'"
  local target_udid
  target_udid="$(frontend_ios_sim_find_udid_by_name "$desired_name")"
  if [ -z "$target_udid" ]; then
    frontend_ios_sim_log "ERROR: Unable to find simulator named '$desired_name'."
    frontend_ios_sim_log "       Set CF_FRONTEND_IOS_SIMULATOR_NAME to a valid device (see 'xcrun simctl list devices')."
    frontend_ios_sim_list_available
    return 1
  fi

  if ! xcrun simctl boot "$target_udid" >/dev/null 2>&1; then
    frontend_ios_sim_log "ERROR: Failed to boot simulator '$desired_name' (UDID: $target_udid)."
    frontend_ios_sim_clear_udid
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
  frontend_ios_sim_write_udid "$target_udid"
}

frontend_ios_sim_main() {
  local cmd="${1:-ensure}"
  case "$cmd" in
    ensure)
      #set -x
      frontend_ios_sim_ensure
      set +x
      ;;
    target)
      frontend_ios_sim_target
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
