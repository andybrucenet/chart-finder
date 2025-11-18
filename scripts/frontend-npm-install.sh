#!/bin/bash
# frontend-npm-install.sh
# Ensure frontend node_modules matches the current lockfile hash.

# locate script source directory
the_frontend_npm_install_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_npm_install_source" ]; do
  the_frontend_npm_install_dir="$( cd -P "$( dirname "$the_frontend_npm_install_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_npm_install_source="$(readlink "$the_frontend_npm_install_source")"
  [[ $the_frontend_npm_install_source != /* ]] && the_frontend_npm_install_source="$the_frontend_npm_install_dir/$the_frontend_npm_install_source"
done
the_frontend_npm_install_script_dir="$( cd -P "$( dirname "$the_frontend_npm_install_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_npm_install_root_dir="$( realpath "$the_frontend_npm_install_script_dir"/.. )"
source "$the_frontend_npm_install_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_frontend_npm_install_root_dir" || exit $?
source "$the_frontend_npm_install_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

set -euo pipefail

the_frontend_npm_install_npm_bin="${NPM:-npm}"
the_frontend_npm_install_app_dir="${CF_FRONTEND_APP_DIR:-$the_frontend_npm_install_root_dir/src/frontend/chart-finder-react}"
the_frontend_npm_install_lock_file="${the_frontend_npm_install_app_dir}/package-lock.json"
the_frontend_npm_install_node_modules_dir="${the_frontend_npm_install_app_dir}/node_modules"
the_frontend_npm_install_state_dir="$the_frontend_npm_install_root_dir/$g_DOT_LOCAL_DIR_NAME/state"
the_frontend_npm_install_hash_file="${the_frontend_npm_install_state_dir}/frontend-node-modules.lockhash"
the_frontend_npm_install_mode="${FRONTEND_NPM_INSTALL_OPTION_MODE:-install}"
the_frontend_npm_install_force_install="${FRONTEND_NPM_INSTALL_OPTION_FORCE_INSTALL:-0}"

mkdir -p "$the_frontend_npm_install_state_dir"

case "$the_frontend_npm_install_mode" in
  install|ci) ;;
  *)
    echo "Unsupported FRONTEND_NPM_INSTALL_OPTION_MODE='$the_frontend_npm_install_mode' (expected 'install' or 'ci')" >&2
    exit 2
    ;;
esac

frontend_npm_install_calc_lock_hash() {
  if [ ! -f "$the_frontend_npm_install_lock_file" ]; then
    echo ""
    return 0
  fi
  shasum -a 256 "$the_frontend_npm_install_lock_file" | awk '{print $1}'
}

the_frontend_npm_install_hash_current="$(frontend_npm_install_calc_lock_hash)"
the_frontend_npm_install_hash_previous=''
[ -s "$the_frontend_npm_install_hash_file" ] && the_frontend_npm_install_hash_previous="$(cat "$the_frontend_npm_install_hash_file")"

the_frontend_npm_install_need_install_reason=''
if [ "$the_frontend_npm_install_force_install" = "1" ]; then
  the_frontend_npm_install_need_install_reason='forced via FRONTEND_NPM_INSTALL_OPTION_FORCE_INSTALL'
elif [ ! -d "$the_frontend_npm_install_node_modules_dir" ]; then
  the_frontend_npm_install_need_install_reason='node_modules directory missing'
elif [ -z "$the_frontend_npm_install_hash_previous" ]; then
  the_frontend_npm_install_need_install_reason='missing lock hash state'
elif [ "$the_frontend_npm_install_hash_current" != "$the_frontend_npm_install_hash_previous" ]; then
  the_frontend_npm_install_need_install_reason='package-lock hash changed'
fi

if [ -z "$the_frontend_npm_install_need_install_reason" ]; then
  echo "Frontend dependencies are up to date (lock hash $the_frontend_npm_install_hash_current)."
  exit 0
fi

echo "Frontend dependencies require install: $the_frontend_npm_install_need_install_reason"
if [ ! -f "$the_frontend_npm_install_lock_file" ]; then
  echo "  NOTE: $the_frontend_npm_install_lock_file not found; npm will recreate it."
fi

echo "  -> cd \"$the_frontend_npm_install_app_dir\" && $the_frontend_npm_install_npm_bin $the_frontend_npm_install_mode"
( cd "$the_frontend_npm_install_app_dir" && "$the_frontend_npm_install_npm_bin" "$the_frontend_npm_install_mode" )

the_frontend_npm_install_hash_current="$(frontend_npm_install_calc_lock_hash)"
if [ -z "$the_frontend_npm_install_hash_current" ]; then
  echo "WARNING: lock hash still empty after npm $the_frontend_npm_install_mode (expected $the_frontend_npm_install_lock_file)." >&2
else
  echo "$the_frontend_npm_install_hash_current" >"$the_frontend_npm_install_hash_file"
  echo "Stored lock hash $the_frontend_npm_install_hash_current in $the_frontend_npm_install_hash_file"
fi

echo "Frontend dependencies ready."
