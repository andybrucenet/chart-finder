#!/bin/bash
# frontend-android-versioning.sh
# Ensure the AndroidManifest.xml version metadata matches the frontend version settings.

the_frontend_android_versioning_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_android_versioning_source" ]; do
  the_frontend_android_versioning_dir="$( cd -P "$( dirname "$the_frontend_android_versioning_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_android_versioning_source="$(readlink "$the_frontend_android_versioning_source")"
  [[ $the_frontend_android_versioning_source != /* ]] && the_frontend_android_versioning_source="$the_frontend_android_versioning_dir/$the_frontend_android_versioning_source"
done
the_frontend_android_versioning_script_dir="$( cd -P "$( dirname "$the_frontend_android_versioning_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_android_versioning_root_dir="$( realpath "$the_frontend_android_versioning_script_dir"/.. )"

source "$the_frontend_android_versioning_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

the_frontend_android_versioning_default_manifest="$the_frontend_android_versioning_root_dir/src/frontend/chart-finder-flutter/android/app/src/main/AndroidManifest.xml"
the_frontend_android_versioning_helper_script="$the_frontend_android_versioning_root_dir/scripts/helpers/frontend-android-manifest-version-update.py"

frontend_android_versioning_log() {
  local i_message="$1"
  printf '[frontend-android-versioning] %s\n' "$i_message"
}

frontend_android_versioning_usage() {
  cat <<'USAGE'
Usage: ./scripts/frontend-android-versioning.sh [command]

Commands:
  run        Update AndroidManifest.xml version attributes (default)
  help       Show this help message

Environment:
  FRONTEND_ANDROID_VERSIONING_OPTION_MANIFEST_PATH
              Override the AndroidManifest.xml to update.
USAGE
}

frontend_android_versioning_update_manifest() {
  local i_manifest_path="$1"
  local i_version_code="$2"
  local i_version_name="$3"

  if [ ! -f "$the_frontend_android_versioning_helper_script" ]; then
    frontend_android_versioning_log "ERROR: missing helper $the_frontend_android_versioning_helper_script"
    return 1
  fi

  local l_tmp_output
  if ! l_tmp_output="$(python3 "$the_frontend_android_versioning_helper_script" "$i_manifest_path" "$i_version_code" "$i_version_name" 2>&1)"; then
    frontend_android_versioning_log "ERROR: helper failed to update manifest"
    printf '%s\n' "$l_tmp_output"
    return 1
  fi

  if printf '%s' "$l_tmp_output" | grep -qi 'updated'; then
    frontend_android_versioning_log "Updated $(realpath "$i_manifest_path")"
  else
    frontend_android_versioning_log "Manifest already up to date"
  fi
}

frontend_android_versioning_run() {
  local l_manifest_path="${FRONTEND_ANDROID_VERSIONING_OPTION_MANIFEST_PATH:-$the_frontend_android_versioning_default_manifest}"
  if [ ! -f "$l_manifest_path" ]; then
    frontend_android_versioning_log "ERROR: missing manifest at $l_manifest_path"
    return 1
  fi

  local l_version_name="${CF_FRONTEND_VERSION_SHORT:-}"
  local l_version_code="${CF_FRONTEND_VERSION_GLOBAL_RELEASE:-}"

  if [ -z "$l_version_name" ]; then
    frontend_android_versioning_log "ERROR: CF_FRONTEND_VERSION_SHORT is empty"
    return 1
  fi

  if [ -z "$l_version_code" ]; then
    frontend_android_versioning_log "ERROR: CF_FRONTEND_VERSION_GLOBAL_RELEASE is empty"
    return 1
  fi

  if printf '%s' "$l_version_code" | grep -q '[^0-9]'; then
    frontend_android_versioning_log "ERROR: CF_FRONTEND_VERSION_GLOBAL_RELEASE must be numeric (got '$l_version_code')"
    return 1
  fi

  frontend_android_versioning_log "Setting versionName=$l_version_name versionCode=$l_version_code"
  frontend_android_versioning_update_manifest "$l_manifest_path" "$l_version_code" "$l_version_name"
}

frontend_android_versioning_main() {
  local l_command="${1:-run}"
  case "$l_command" in
    run)
      frontend_android_versioning_run
      ;;
    help|-h|--help)
      frontend_android_versioning_usage
      ;;
    *)
      frontend_android_versioning_log "ERROR: unknown command '$l_command'"
      frontend_android_versioning_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" = "source-only" ]; then
  true
else
  frontend_android_versioning_main "$@"
fi
