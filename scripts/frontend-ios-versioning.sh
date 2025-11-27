#!/bin/bash
# frontend-ios-versioning.sh
# Ensure the iOS Info.plist version metadata matches the frontend version settings.

the_frontend_ios_versioning_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_ios_versioning_source" ]; do
  the_frontend_ios_versioning_dir="$( cd -P "$( dirname "$the_frontend_ios_versioning_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_ios_versioning_source="$(readlink "$the_frontend_ios_versioning_source")"
  [[ $the_frontend_ios_versioning_source != /* ]] && the_frontend_ios_versioning_source="$the_frontend_ios_versioning_dir/$the_frontend_ios_versioning_source"
done
the_frontend_ios_versioning_script_dir="$( cd -P "$( dirname "$the_frontend_ios_versioning_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_ios_versioning_root_dir="$( realpath "$the_frontend_ios_versioning_script_dir"/.. )"

source "$the_frontend_ios_versioning_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

the_frontend_ios_versioning_default_plist="$the_frontend_ios_versioning_root_dir/src/frontend/chart-finder-flutter/ios/Runner/Info.plist"
the_frontend_ios_versioning_helper_script="$the_frontend_ios_versioning_root_dir/scripts/helpers/frontend-ios-info-plist-update.py"

frontend_ios_versioning_log() {
  local i_message="$1"
  printf '[frontend-ios-versioning] %s\n' "$i_message"
}

frontend_ios_versioning_usage() {
  cat <<'USAGE'
Usage: ./scripts/frontend-ios-versioning.sh [command]

Commands:
  run        Update Info.plist version attributes (default)
  help       Show this help message

Environment:
  FRONTEND_IOS_VERSIONING_OPTION_PLIST_PATH
              Override the Info.plist to update.
USAGE
}

frontend_ios_versioning_update_plist() {
  local i_plist_path="$1"
  local i_short_version="$2"
  local i_build_version="$3"

  if [ ! -f "$the_frontend_ios_versioning_helper_script" ]; then
    frontend_ios_versioning_log "ERROR: missing helper $the_frontend_ios_versioning_helper_script"
    return 1
  fi

  local l_tmp_output
  if ! l_tmp_output="$(python3 "$the_frontend_ios_versioning_helper_script" "$i_plist_path" "$i_short_version" "$i_build_version" 2>&1)"; then
    frontend_ios_versioning_log "ERROR: helper failed to update Info.plist"
    printf '%s\n' "$l_tmp_output"
    return 1
  fi

  if printf '%s' "$l_tmp_output" | grep -qi 'updated'; then
    frontend_ios_versioning_log "Updated $(realpath "$i_plist_path")"
  else
    frontend_ios_versioning_log "Info.plist already up to date"
  fi
}

frontend_ios_versioning_run() {
  local l_plist_path="${FRONTEND_IOS_VERSIONING_OPTION_PLIST_PATH:-$the_frontend_ios_versioning_default_plist}"
  if [ ! -f "$l_plist_path" ]; then
    frontend_ios_versioning_log "WARN: missing Info.plist at $l_plist_path; skipping iOS versioning"
    return 0
  fi

  local l_version_name="${CF_FRONTEND_VERSION_SHORT:-}"
  local l_version_code="${CF_FRONTEND_VERSION_GLOBAL_RELEASE:-}"

  if [ -z "$l_version_name" ]; then
    frontend_ios_versioning_log "ERROR: CF_FRONTEND_VERSION_SHORT is empty"
    return 1
  fi

  if [ -z "$l_version_code" ]; then
    frontend_ios_versioning_log "ERROR: CF_FRONTEND_VERSION_GLOBAL_RELEASE is empty"
    return 1
  fi

  if printf '%s' "$l_version_code" | grep -q '[^0-9.]'; then
    frontend_ios_versioning_log "ERROR: CF_FRONTEND_VERSION_GLOBAL_RELEASE must be numeric/dot (got '$l_version_code')"
    return 1
  fi

  frontend_ios_versioning_log "Setting CFBundleShortVersionString=$l_version_name CFBundleVersion=$l_version_code"
  frontend_ios_versioning_update_plist "$l_plist_path" "$l_version_name" "$l_version_code"
}

frontend_ios_versioning_main() {
  local l_command="${1:-run}"
  case "$l_command" in
    run)
      frontend_ios_versioning_run
      ;;
    help|-h|--help)
      frontend_ios_versioning_usage
      ;;
    *)
      frontend_ios_versioning_log "ERROR: unknown command '$l_command'"
      frontend_ios_versioning_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" = "source-only" ]; then
  true
else
  frontend_ios_versioning_main "$@"
fi
