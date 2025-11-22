#!/bin/bash
# cf-env-vars-to-make.sh, ABr
#
# Helper script that sources cf-env-vars.sh and generates output
# to set vars for Makefile.
# Advantages:
# * Makefile immediately has access to CF env vars
# * CF_ENV_VARS_TO_MAKE_ALREADY_RUN is set, which optimizes
#   calls such that any other subcommand (including child Makefiles)
#   uses the cached/exported env vars set from the first call.

# function to load all files in and
cf_env_vars_to_make_main() {
  # work vars
  local l_rc=0
  local l_tmp_prefix="`lcl_os_tmp_dir`/cf-env-vars-to-make-$$-"

  # store the known global vars from lcl-os-checks.sh
  local l_tmp_var_names_path="${l_tmp_prefix}var-names.txt"
  cat <<EOS > "$l_tmp_var_names_path"
g_IS_LINUX
g_IS_MAC
g_IS_CYGWIN
g_IS_MINGW
g_UNAME
g_VALID_OS
g_UNAME_MACHINE
g_PATH_SEP
g_DOT_LOCAL_DIR_NAME
g_DOT_LOCAL_SETTINGS_FNAME
g_DOT_LOCAL_SETTINGS_TAG_LINE
g_VERSION_ENV_VARS_TO_CHECK
g_VERSION_NORMALIZE_DEFAULT_BUILD
EOS

  # we need to identify all env variables to export for Makefile.
  # these include all CF_ vars but also any explicit vars from the
  # individual .local scripts (such as AWS_SDK_LOAD_CONFIG).
  local l_local_dir="$the_cf_env_vars_to_make_root_dir/$g_DOT_LOCAL_DIR_NAME"
  local l_local_rel_paths_to_process="$g_DOT_LOCAL_SETTINGS_FNAME"
  local l_local_path=''
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
  local l_output_fname='cf-env-vars.mk'
  local l_tmp_output_path="${l_tmp_prefix}$l_output_fname"
  touch "$l_tmp_output_path"
  if [ $l_rc -eq 0 ] ; then
    while IFS= read -r line; do
      echo "$line := ${!line}" >>"$l_tmp_output_path"
      echo "export $line" >>"$l_tmp_output_path"
      #echo "\$(info $line=\$($line))" >>"$l_tmp_output_path"
    done < "$l_tmp_var_names_path"

    # NOTE: trying to cache appears to break things!
    ## end with control var
    #echo "CF_ENV_VARS_TO_MAKE_ALREADY_RUN := 1" >>"$l_tmp_output_path"
    #echo "export CF_ENV_VARS_TO_MAKE_ALREADY_RUN" >>"$l_tmp_output_path"
  fi

  # overwrite the "real" destination if different
  if [ $l_rc -eq 0 ] ; then
    #set -x
    local l_dest_dir="$the_cf_env_vars_to_make_root_dir/$g_DOT_LOCAL_DIR_NAME/state"
    [ ! -d "$l_dest_dir" ] && mkdir -p "$l_dest_dir"
    [ ! -d "$l_dest_dir" ] && echo "MISSING_DIR: '$l_dest_dir'" && l_rc=2
    if [ $l_rc -eq 0 ] ; then
      local l_dest_path="$l_dest_dir/$l_output_fname"
      #touch "$l_dest_path"
      #diff "$l_dest_path" "$l_tmp_output_path"
      if ! diff "$l_dest_path" "$l_tmp_output_path" >/dev/null 2>&1 ; then
        /bin/cp "$l_tmp_output_path" "$l_dest_path"
        l_rc=$?
      fi
    fi
    set +x
  fi

  # cleanup
  rm -f "$l_tmp_output_path" "$l_tmp_var_names_path"
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

