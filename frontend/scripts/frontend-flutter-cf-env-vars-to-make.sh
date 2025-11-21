#!/bin/bash
# frontend-flutter-cf-env-vars-to-make.sh
# Frontend environment vars enhancements specifically for Flutter commands.

# resolve directories
the_frontend_flutter_cf_env_vars_to_make_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_flutter_cf_env_vars_to_make_source" ]; do
  the_frontend_flutter_cf_env_vars_to_make_dir="$( cd -P "$( dirname "$the_frontend_flutter_cf_env_vars_to_make_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_flutter_cf_env_vars_to_make_source="$(readlink "$the_frontend_flutter_cf_env_vars_to_make_source")"
  [[ $the_frontend_flutter_cf_env_vars_to_make_source != /* ]] && the_frontend_flutter_cf_env_vars_to_make_source="$the_frontend_flutter_cf_env_vars_to_make_dir/$the_frontend_flutter_cf_env_vars_to_make_source"
done
the_frontend_flutter_cf_env_vars_to_make_script_dir="$( cd -P "$( dirname "$the_frontend_flutter_cf_env_vars_to_make_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_flutter_cf_env_vars_to_make_root_dir="$( realpath "$the_frontend_flutter_cf_env_vars_to_make_script_dir"/../.. )"
#
# load in environment
source "$the_frontend_flutter_cf_env_vars_to_make_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?
the_frontend_flutter_cf_env_vars_to_make_original_path="$PATH"

frontend_flutter_cf_env_vars_to_make_run_fvm() {
  PATH="$the_frontend_flutter_cf_env_vars_to_make_original_path" fvm "$@"
}
#
# require CF_FRONTEND_FLUTTER_VER
[ x"$CF_FRONTEND_FLUTTER_VER" = x ] && echo "ERROR: MISSING CF_FRONTEND_FLUTTER_VER"
#
# require tools
the_frontend_flutter_cf_env_vars_to_make_tools_ok=1
the_frontend_flutter_cf_env_vars_to_make_tools='fvm'
for i in $the_frontend_flutter_cf_env_vars_to_make_tools ; do
  ! which $i >/dev/null 2>&1 && echo "ERROR: MISSING_REQUIRED_TOOL (FRONTEND) $i" && the_frontend_flutter_cf_env_vars_to_make_tools_ok=0
done
[ $the_frontend_flutter_cf_env_vars_to_make_tools_ok -ne 1 ] && exit 1
#
# auto-install flutter
the_frontend_flutter_cf_env_vars_to_make_app_dir="$the_frontend_flutter_cf_env_vars_to_make_root_dir/src/frontend/chart-finder-flutter"
cd "$the_frontend_flutter_cf_env_vars_to_make_app_dir" || exit $?
the_frontend_flutter_cf_env_vars_to_make_fvm_dir="$the_frontend_flutter_cf_env_vars_to_make_app_dir/.fvm"
the_frontend_flutter_cf_env_vars_to_make_fvm_config="$the_frontend_flutter_cf_env_vars_to_make_fvm_dir/fvm_config.json"
if [ ! -s "$the_frontend_flutter_cf_env_vars_to_make_fvm_config" ] ; then
  echo "AUTO_INSTALL: flutter v$CF_FRONTEND_FLUTTER_VER..."
  echo "fvm install $CF_FRONTEND_FLUTTER_VER"
  frontend_flutter_cf_env_vars_to_make_run_fvm install $CF_FRONTEND_FLUTTER_VER || exit $?
  echo "fvm use $CF_FRONTEND_FLUTTER_VER --force"
  frontend_flutter_cf_env_vars_to_make_run_fvm use $CF_FRONTEND_FLUTTER_VER --force || exit $?
fi
#
# finally - verify version
the_frontend_flutter_cf_env_vars_to_make_flutter_ver="`frontend_flutter_cf_env_vars_to_make_run_fvm flutter --version --machine | jq -r '.frameworkVersion'`"
if [ x"$the_frontend_flutter_cf_env_vars_to_make_flutter_ver" != x"$CF_FRONTEND_FLUTTER_VER" ] ; then
  echo "ERROR: FLUTTER_VERSION_MISMATCH: CF_FRONTEND_FLUTTER_VER='$CF_FRONTEND_FLUTTER_VER'; ACTUAL='$the_frontend_flutter_cf_env_vars_to_make_flutter_ver'"
  exit 1
fi
#
# now translate to make variables
"$the_frontend_flutter_cf_env_vars_to_make_root_dir/scripts/cf-env-vars-to-make.sh"
