#!/bin/bash
# cf-env-vars-to-make.sh, ABr
#
# Helper script that sources cf-env-vars.sh and generates output
# to set vars for Makefile

# function to load all files in and
cf_env_vars_to_make_main() {
  # work vars
  local l_rc=0
  local l_tmp_prefix="`lcl_os_tmp_dir`/cf-env-vars-to-make-$$-"

  # we need to identify all env variables to export for Makefile.
  # these include all CF_ vars but also any explicit vars from the
  # individual .local scripts (such as AWS_SDK_LOAD_CONFIG).
  local l_tmp_var_names_path="${l_tmp_prefix}var-names.txt"
  local l_local_dir="$the_cf_env_vars_to_make_root_dir/$g_DOT_LOCAL_DIR_NAME"
  local l_local_rel_paths_to_process="$g_DOT_LOCAL_SETTINGS_FNAME"
  local l_local_path=''
  touch "$l_tmp_var_names_path"
  for i in $l_local_rel_paths_to_process ; do
    l_local_path="$l_local_dir/$i"
    [ ! -s "$l_local_path" ] && continue

    # append all non-CF vars to tmp names to get explicitly
    cat "$l_local_path" \
      | grep -v '^#' \
      | grep -e ' export ' \
      | sed -e 's/^.* export \([^=]*\).*/\1/' \
      | grep -v '^CF_' \
      >>"$l_tmp_var_names_path"
    l_rc=$?
    [ $l_rc -ne 0 ] && break
  done

  # output all CF variables
  if [ $l_rc -eq 0 ] ; then
    set | grep -e '^CF_' | sed -e 's/^\([^=]*\).*/\1/' >>"$l_tmp_var_names_path"
    l_rc=$?
  fi

  # also output cf-env-vars.sh local vars...otherwise if
  # dependent scripts leverage them then those scripts
  # will not work.
  if [ $l_rc -eq 0 ] ; then
    set | grep -e '^the_cf_env_vars_' | sed -e 's/^\([^=]*\).*/\1/' >>"$l_tmp_var_names_path"
    l_rc=$?
  fi

  # process all variables
  if [ $l_rc -eq 0 ] ; then
    while IFS= read -r line; do
      echo "$line := ${!line}"
      echo "export $line"
    done < "$l_tmp_var_names_path"

    # end with control var
    echo "CF_ENV_VARS_TO_MAKE_ALREADY_RUN := 1"
    echo "export CF_ENV_VARS_TO_MAKE_ALREADY_RUN"
  fi

  # cleanup
  rm -f "$l_tmp_var_names_path"
  return $l_rc
}

# already called? then nothing to do
if [ x"$CF_ENV_VARS_TO_MAKE_ALREADY_RUN" = x ] ; then
  # locate script source directory
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  the_cf_env_vars_to_make_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  the_cf_env_vars_to_make_root_dir="$( realpath "$the_cf_env_vars_to_make_script_dir"/.. )"
  source "$the_cf_env_vars_to_make_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

  # expensive worker function
  cf_env_vars_to_make_main
fi

