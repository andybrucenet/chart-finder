#!/bin/bash
# backend-env-metadata.sh, ABr
# Analyze computed environment metadata and update backend configs appropriately.

# locate script source directory
the_backend_env_metadata_source="${BASH_SOURCE[0]}"
while [ -h "$the_backend_env_metadata_source" ]; do
  the_backend_env_metadata_dir="$( cd -P "$( dirname "$the_backend_env_metadata_source" )" >/dev/null 2>&1 && pwd )"
  the_backend_env_metadata_source="$(readlink "$the_backend_env_metadata_source")"
  [[ $the_backend_env_metadata_source != /* ]] && the_backend_env_metadata_source="$the_backend_env_metadata_dir/$the_backend_env_metadata_source"
done
the_backend_env_metadata_script_dir="$( cd -P "$( dirname "$the_backend_env_metadata_source" )" >/dev/null 2>&1 && pwd )"
the_backend_env_metadata_root_dir="$( realpath "$the_backend_env_metadata_script_dir"/.. )"
source "$the_backend_env_metadata_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_backend_env_metadata_root_dir" || exit $?
#
# also source in all the local build version settings - this computes derived variables
source "$the_backend_env_metadata_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

# retrieve property from Directory.Build.props
backend_env_metadata_get_prop() {
  local file="$1"
  local prop="$2"
  sed -n "s|.*<${prop}[^>]*>\\(.*\\)</${prop}>.*|\\1|p" "$file" | head -n1
}

# update property in Directory.Build.props
backend_env_metadata_update_props() {
  local i_file="$1" ; shift
  local i_prop_name="$1" ; shift
  local i_prop_value="$1" ; shift

  NEW_value="$i_prop_value" \
  python3 - "$i_file" "$i_prop_name" "$i_prop_value" <<'PY'
import os
import re
import sys

path = sys.argv[1]
data = open(path, encoding="utf-8").read()

def replace(tag: str, value: str) -> None:
    global data
    pattern = rf"(<{tag}[^>]*>)(.*?)(</{tag}>)"
    data, count = re.subn(pattern, lambda m: f"{m.group(1)}{value}{m.group(3)}", data, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"Failed to update {tag} in {path}")

replace(sys.argv[2], os.environ["NEW_value"])

with open(path, "w", encoding="utf-8") as handle:
    handle.write(data)
PY
}

# entry point unless this script is simply being sourced
backend_env_metadata_main() {
  # get state directory
  local l_state_dir="$the_backend_env_metadata_root_dir/$g_DOT_LOCAL_DIR_NAME/state"
  [ ! -d "$l_state_dir" ] && mkdir -p "$l_state_dir"
  [ ! -d "$l_state_dir" ] && echo "MISSING_DIR: $the_backend_env_metadata_state_dir" && return 2

  # get location of source and destination Directory.Build.props
  local l_props_path_src="$the_cf_env_vars_backend_dirbuildprops_src_path"

  # get and update values
  local l_key l_current_value l_new_value
  l_key='ChartFinderBackendExposeOpenAPI'
  local l_current_value="$(backend_env_metadata_get_prop "$l_props_path_src" "$l_key")"
  local l_new_value="$CF_BACKEND_EXPOSE_OPENAPI"
  if [ x"$l_current_value" != x"$l_new_value" ] ; then
    echo "UPDATE: $l_key ('$l_current_value' -> '$l_new_value')"
    backend_env_metadata_update_props "$l_props_path_src" "$l_key" "$l_new_value" || return $?
  fi

  # force an auto-cache
  cf_env_vars_backend_dirbuildprops_auto_cache || return $?

  # all is well
  return 0
}

if [ "${1:-}" != "source-only" ]; then
  backend_env_metadata_main "$@"
else
  # no error
  true
fi
