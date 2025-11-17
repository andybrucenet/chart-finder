#!/bin/bash
# lcl-os-checks.sh, ABr
# Common OS / .local utility script functions

######################################################################
# globals
#
# OS identification
[ x"$g_IS_LINUX" = x ] && export g_IS_LINUX=0
[ x"$g_IS_MAC" = x ] && export g_IS_MAC=0
[ x"$g_IS_CYGWIN" = x ] && export g_IS_CYGWIN=0
[ x"$g_IS_MINGW" = x ] && export g_IS_MINGW=0
[ x"$g_UNAME" = x ] && export g_UNAME=''
[ x"$g_VALID_OS" = x ] && export g_VALID_OS=0
[ x"$g_UNAME_MACHINE" = x ] && export g_UNAME_MACHINE=''
[ x"$g_PATH_SEP" = x ] && export g_PATH_SEP=':'
#
# .local values
export g_DOT_LOCAL_DIR_NAME='.local'
export g_DOT_LOCAL_SETTINGS_FNAME='local.env'
export g_DOT_LOCAL_SETTINGS_TAG_LINE='## TAG: DO_NOT_EDIT_BELOW_HERE'
#
# version values to check
export g_VERSION_ENV_VARS_TO_CHECK='CF_BACKEND_VERSION_FULL CF_BACKEND_BUILD_NUMBER'
export g_VERSION_NORMALIZE_DEFAULT_BUILD='0'

######################################################################
# functions
#
# is current OS linux?
function lcl_is_os_linux {
  [ x"$g_UNAME_MACHINE" = xLinux ] && true || false
}
#
# is current OS mac?
function lcl_is_os_mac {
  [ x"$g_UNAME_MACHINE" = xMac ] && true || false
}
#
# is current OS cygwin?
function lcl_is_os_cygwin {
  [ x"$g_UNAME_MACHINE" = xCygwin ] && true || false
}
#
# is current OS mingw?
function lcl_is_os_mingw {
  [ x"$g_UNAME_MACHINE" = xMinGw ] && true || false
}
#
# is current OS cygwin-ish?
function lcl_is_os_cygwinish {
  if lcl_is_os_cygwin || lcl_is_os_mingw ; then
    return 0
  fi
  false
}
#
# is current OS windows?
function lcl_is_os_windows {
  lcl_is_os_cygwinish && true || false
}
#
# is current OS unix-ish?
function lcl_is_os_unixish {
  if lcl_is_os_linux || lcl_is_os_mac ; then
    return 0
  fi
  false
}
#
# tmp
function lcl_os_tmp_dir {
  local l_tmp=${TMP:-/tmp}
  if lcl_is_os_cygwin ; then
    # '/tmp' is weird under windows / cygwin :)
    l_tmp="`cygpath -am $l_tmp | dos2unix`"
  fi
  echo "$l_tmp"
}
#
# get proper pwd
function lcl_os_pwd {
  local l_tmp="$PWD"
  if lcl_is_os_cygwin ; then
    # return mixed case *without* cygpath
    l_tmp="`cygpath -am "$PWD" | dos2unix`"
  fi
  echo "$l_tmp"
}
#
# get safe path from input
function lcl_os_safepath {
  local l_path="$1" ; shift
  if lcl_is_os_cygwin ; then
    cygpath -am "$l_path"
  else
    echo "$l_path"
  fi
}
#
# return an os-specific path
function lcl_os_path_specific {
  local i_path="$1" ; shift

  # if not cygwin nothing to do :)
  if ! lcl_is_os_cygwin ; then
    echo "$i_path"
    return 0
  fi

  # convert to absolute
  cygpath -aw "$i_path"
}
#
# return an os-neutral path
function lcl_os_path_neutral {
  local i_path="$1" ; shift

  # if not cygwin nothing to do :)
  if ! lcl_is_os_cygwin ; then
    echo "$i_path"
    return 0
  fi

  # convert to mixed
  cygpath -am "$i_path"
}
#
# construct an "os-identifier" from environment (example: 'apple-macos' / 'win-x64')
function lcl_os_id {
  local i_result=''
  if lcl_is_os_mac ; then
    i_result='apple-macos'
  elif lcl_is_os_windows ; then
    i_result='win-x64'
  elif lcl_is_os_linux ; then
    # tc3 platform vars must be loaded separately
    if [ x"$TC3_PLATFORM_TARGET_LINUX_GLIBC_VER" = x ] ; then
      echo 'MISSING: TC3_PLATFORM_TARGET_LINUX_GLIBC_VER'
      return 1
    fi
    i_result="linux-x86_64-glibc-$TC3_PLATFORM_TARGET_LINUX_GLIBC_VER"
  else
    echo '[unsupported-os]'
    return 1
  fi
  echo $i_result
  return 0
}
#
# OS identifiers
function lcl_os_print_var {
  eval echo "\$$1"
}
#
# git branch
function lcl_git_branch() {
  local branch
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null | dos2unix || echo "")"
    if [[ "$branch" == "HEAD" || -z "$branch" ]]; then
      branch="$(git rev-parse --short HEAD 2>/dev/null | dos2unix || echo "")"
    fi
  else
    branch=""
  fi
  echo "$branch"
}
#
# full directory path to '.local'
function lcl_dot_local_dir {
  local i_root_path="$1" ; shift
  echo "$i_root_path/$g_DOT_LOCAL_DIR_NAME"
}
#
# full directory path to 'local.env'
function lcl_dot_local_settings_path {
  local l_dir="`lcl_dot_local_dir "$1"`"
  echo "$l_dir/$g_DOT_LOCAL_SETTINGS_FNAME"
}
#
# return prefix used in local.env for a variable name;
# not escaped
function lcl_dot_local_matching_var_name_prefix {
  local i_var_name="$1" ; shift
  echo '[ x"$'"$i_var_name"'" = x ] && '
}
#
# construct value used to match to a variable defined in local.env;
# note that this value is escaped for feeding into standard grep
function lcl_dot_local_matching_var_name {
  local i_var_name="$1" ; shift
  echo "^.* export $i_var_name="
}
#
# auto-create .local settings if necessary
function lcl_dot_local_settings_auto_create {
  local l_dir="`lcl_dot_local_dir "$1"`"
  local l_path="`lcl_dot_local_settings_path "$1"`"

  # verify directory
  [ ! -d "$l_dir" ] && mkdir -p "$l_dir"
  [ ! -d "$l_dir" ] && echo "ERROR: '$l_dir' NOT_CREATED" && return 2

  # verify source file
  if [ ! -s "$l_path" ] ; then
    # auto-create
    echo "#/bin/bash" >> "$l_path"
    echo "$g_DOT_LOCAL_SETTINGS_TAG_LINE" >> "$l_path"
    echo "the_local_env_path_rc=0" >> "$l_path"
    chmod +x "$l_path"
  elif [ ! -x "$l_path" ] ; then
    chmod +x "$l_path"
  fi
  [ ! -s "$l_path" ] && echo "ERROR: '$l_path' NOT_CREATED" && return 2
  [ ! -x "$l_path" ] && echo "ERROR: '$l_path' NOT_EXECUTABLE" && return 1

  # the tag line must exist
  if ! grep -e "^$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_path" >/dev/null 2>&1 ; then
    echo "ERROR: '$l_path' MISSING_TAG_LINE (delete and recreate)"
    return 1
  fi

  # all good
  return 0
}
#
# reset (delete) the entire .local settings
function lcl_dot_local_settings_reset {
  local l_dir="`lcl_dot_local_dir "$1"`"
  rm -fR "$l_dir" || return $?
  lcl_dot_local_settings_auto_create "$1"
}
#
# source .local settings (auto-create if necessary)
function lcl_dot_local_settings_source {
  # auto-create if necessary
  lcl_dot_local_settings_auto_create "$1" || return $?

  # source (updates caller's environment)
  local l_path="`lcl_dot_local_settings_path "$1"`"
  source "$l_path" 'source-only' || return $?

  # all good
  return 0
}
#
# remove .local settings entry
function lcl_dot_local_settings_delete {
  local i_root_path="$1" ; shift
  local i_var_name="$1" ; shift

  # auto-create local.env
  local l_path="`lcl_dot_local_settings_path "$i_root_path"`"
  lcl_dot_local_settings_auto_create "$i_root_path" || return $?

  # does value exist?
  #set -x
  local l_match_text="`lcl_dot_local_matching_var_name "$i_var_name"`"
  if ! grep -e "$l_match_text" "$l_path" >/dev/null 2>&1 ; then
    # does not exist - nothing to do
    return 0
  fi

  # delete line
  l_tmp_path="`lcl_os_tmp_dir`/lcl-os-checks-dot-settings-update-$$"
  l_line_prefix="`lcl_dot_local_matching_var_name_prefix "$i_var_name"`"
  cat "$l_path"  | sed "/^\(.* export $i_var_name=\).*/d" >"$l_tmp_path" 2>&1
  local l_rc=$?
  if [ $l_rc -ne 0 ] ; then
    # error during sed - show error and auto-cleanup tmp file
    cat "$l_tmp_path"
    rm -f "$l_tmp_path"
    return $l_rc
  fi

  # copy back to original (auto-cleanup tmp file)
  /bin/cp "$l_tmp_path" "$l_path"
  l_rc=$?
  rm -f "$l_tmp_path"
  [ $l_rc -ne 0 ] && return $l_rc

  # set executable - function result is zero on success
  chmod +x "$l_path"
  return $?
}
#
# modify .local settings entry with a new value (auto-create if necessary)
# does *not* honor local environment value
function lcl_dot_local_settings_update {
  local i_root_path="$1" ; shift
  local i_var_name="$1" ; shift
  local i_var_new_value="$1" ; shift

  # auto-create local.env
  local l_path="`lcl_dot_local_settings_path "$i_root_path"`"
  lcl_dot_local_settings_auto_create "$i_root_path" || return $?

  # does value exist?
  local l_tmp_path=''
  local l_line_prefix=''
  #set -x
  local l_match_text="`lcl_dot_local_matching_var_name "$i_var_name"`"
  if grep -e "$l_match_text" "$l_path" >/dev/null 2>&1 ; then
    # extract value
    local l_var_existing_value="`cat "$l_path" | sed -e "s/$l_match_text'\([^']*\).*/\1/" | dos2unix`"
    if [ x"$l_var_existing_value" = x"$i_var_new_value" ] ; then
      # short-circuit - value exists and matches
      return 0
    fi

    # modify (simple)
    l_tmp_path="`lcl_os_tmp_dir`/lcl-os-checks-dot-settings-update-$$"
    cat "$l_path" \
      | sed "s|^\(.* export $i_var_name=\).*|\1'$i_var_new_value'|" \
      >"$l_tmp_path" 2>&1
  else
    # insert (more complex; not using sed as it is different on different platforms)
    l_tmp_path="`lcl_os_tmp_dir`/lcl-os-checks-dot-settings-update-$$"
    l_line_prefix="`lcl_dot_local_matching_var_name_prefix "$i_var_name"`"

    # insert all lines up to tag, then the line, then the tag, then all lines after tag
    grep -B999999 "$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_path" | grep -vE "$g_DOT_LOCAL_SETTINGS_TAG_LINE|^--$" >"$l_tmp_path"
    echo "${l_line_prefix}export $i_var_name='$i_var_new_value'" >> "$l_tmp_path"
    echo "$g_DOT_LOCAL_SETTINGS_TAG_LINE" >>"$l_tmp_path"
    grep -A999999 "$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_path" | grep -vE "$g_DOT_LOCAL_SETTINGS_TAG_LINE|^--$" >>"$l_tmp_path"
  fi
  local l_rc=$?
  if [ $l_rc -ne 0 ] ; then
    # error during sed - show error and auto-cleanup tmp file
    cat "$l_tmp_path"
    rm -f "$l_tmp_path"
    return $l_rc
  fi

  # copy back to original (auto-cleanup tmp file)
  /bin/cp "$l_tmp_path" "$l_path"
  l_rc=$?
  rm -f "$l_tmp_path"
  [ $l_rc -ne 0 ] && return $l_rc

  # set executable - function result is zero on success
  chmod +x "$l_path"
  return $?
}
#
# read .local settings entry with a default value if not exists
# rules:
# * does *not* honor local environment value - only the setting from local.env
# * if set in local.env - return that as-is
# * else:
#   * if auto-update set then update local.env with default_value
#   * always return the passed default_value
# * 
function lcl_dot_local_settings_get {
  local i_root_path="$1" ; shift
  local i_var_name="$1" ; shift
  local i_var_default_value="$1" ; shift
  local i_auto_update="$1" ; shift

  # auto-create if necessary
  local l_path="`lcl_dot_local_settings_path "$i_root_path"`"
  lcl_dot_local_settings_auto_create "$i_root_path" || return $?

  # if value exists in local settings - return it as-is
  local l_match_text="`lcl_dot_local_matching_var_name "$i_var_name"`"
  if grep -e "$l_match_text" "$l_path" >/dev/null 2>&1 ; then
    # echo it back out
    #set -x
    cat "$l_path" \
      | grep -e "$l_match_text" \
      | sed -e "s/$l_match_text'\([^']*\).*/\1/" \
      | dos2unix
    return $?
  fi

  # is auto_update requested?
  [ x"$i_auto_update" = x ] && i_auto_update=1
  if [ x"$i_auto_update" != x1 ] ; then
    # just echo the default - no update desired
    echo "$i_var_default_value"
    return 0
  fi

  # attempt auto-update to settings file
  lcl_dot_local_settings_update "$i_root_path" "$i_var_name" "$i_var_default_value" || return $?

  # return the updated value
  echo "$i_var_default_value"
}
#
# read .local settings entry with a default value if not exists
# rules:
# * if local env var is set - return that (never checks local.env)
# * else:
#   * check local.env and if value exists - return it
#   * else: return default value (conditionally auto-update local.env)
function lcl_dot_local_settings_get_env {
  local i_root_path="$1" ; shift
  local i_var_name="$1" ; shift
  local i_var_default_value="$1" ; shift
  local i_auto_update="$1" ; shift

  # if local env variable exists and is not empty - return it
  local l_var_existing_value="${!i_var_name}"
  if [ x"$l_var_existing_value" != x ] ; then
    echo "$l_var_existing_value"
    return 0
  fi

  # auto-create if necessary
  local l_path="`lcl_dot_local_settings_path "$i_root_path"`"
  lcl_dot_local_settings_auto_create "$i_root_path" || return $?

  # if value exists in local settings - return it as-is (no auto-update)
  local l_match_text="`lcl_dot_local_matching_var_name "$i_var_name"`"
  if grep -e "$l_match_text" "$l_path" >/dev/null 2>&1 ; then
    # echo it back out
    #set -x
    cat "$l_path" \
      | grep -e "$l_match_text" \
      | sed -e "s/$l_match_text'\([^']*\).*/\1/" \
      | dos2unix
    return $?
  fi

  # assume auto-update is *not* desired
  [ x"$i_auto_update" = x ] && i_auto_update=0

  # use standard worker to get the value with auto-update
  lcl_dot_local_settings_get "$i_root_path" "$i_var_name" "$i_var_default_value" "$i_auto_update"
}

#
# self-test the .local settings helpers. Usage:
#   source scripts/lcl-os-checks.sh && lcl_dot_local_settings_self_test
#
function lcl_dot_local_settings_self_test {
  (
    local l_tmp_root="`lcl_os_tmp_dir`/lcl-os-checks-self-test-$$"
    local l_settings_path=''
    local l_value=''
    local l_prefix=''
    local l_match_text=''

    fail() {
      echo "lcl_dot_local_settings_self_test: $*" >&2
      exit 1
    }

    rm -fR "$l_tmp_root"
    mkdir -p "$l_tmp_root" || fail "unable to create temp root '$l_tmp_root'"
    trap 'rm -fR "$l_tmp_root"' EXIT

    lcl_dot_local_settings_auto_create "$l_tmp_root" || fail "auto-create failed"
    l_settings_path="`lcl_dot_local_settings_path "$l_tmp_root"`"
    [ -s "$l_settings_path" ] || fail "settings file missing after auto-create"
    grep -q "^$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_settings_path" || fail "tag line missing"
    if [ "$(grep -c "^$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_settings_path")" != "1" ] ; then
      fail "unexpected tag line count"
    fi

    # add new variable
    lcl_dot_local_settings_update "$l_tmp_root" TEST_VAR 'initial-value' || fail "initial update failed"
    l_prefix="`lcl_dot_local_matching_var_name_prefix TEST_VAR`"
    l_match_text="`lcl_dot_local_matching_var_name TEST_VAR`"
    if ! grep -q "${l_match_text}'initial-value'" "$l_settings_path" ; then
      fail "initial insert mismatch"
    fi
    if ! l_value="$(lcl_dot_local_settings_get "$l_tmp_root" TEST_VAR 'unused' 0)" ; then
      fail "get existing value failed"
    fi
    [ x"$l_value" = x'initial-value' ] || fail "get returned '$l_value' (expected 'initial-value')"

    # update existing variable
    lcl_dot_local_settings_update "$l_tmp_root" TEST_VAR 'next-value' || fail "update existing failed"
    if ! grep -q "${l_match_text}'next-value'" "$l_settings_path" ; then
      fail "update did not replace value"
    fi
    if ! l_value="$(lcl_dot_local_settings_get "$l_tmp_root" TEST_VAR 'unused' 0)" ; then
      fail "get after update failed"
    fi
    [ x"$l_value" = x'next-value' ] || fail "get after update returned '$l_value'"

    # get_env favors environment variable when present
    unset TEST_VAR
    if ! l_value="$(lcl_dot_local_settings_get_env "$l_tmp_root" TEST_VAR 'fallback' 0)" ; then
      fail "get_env without env failed"
    fi
    [ x"$l_value" = x'next-value' ] || fail "get_env should return stored value, saw '$l_value'"

    TEST_VAR='env-value'
    if ! l_value="$(lcl_dot_local_settings_get_env "$l_tmp_root" TEST_VAR 'fallback' 0)" ; then
      fail "get_env with env failed"
    fi
    [ x"$l_value" = x'env-value' ] || fail "get_env ignored environment value (got '$l_value')"
    unset TEST_VAR

    # get without auto-update should not add a new entry
    lcl_dot_local_settings_delete "$l_tmp_root" TEMP_VAR || fail "pre-clean delete failed"
    if ! l_value="$(lcl_dot_local_settings_get "$l_tmp_root" TEMP_VAR 'default-temporary' 0)" ; then
      fail "get without auto-update failed"
    fi
    [ x"$l_value" = x'default-temporary' ] || fail "get without auto-update returned '$l_value'"
    l_match_text="`lcl_dot_local_matching_var_name TEMP_VAR`"
    if grep -q "$l_match_text" "$l_settings_path" ; then
      fail "get without auto-update unexpectedly added value"
    fi

    # auto-update path should append entry before the tag
    if ! l_value="$(lcl_dot_local_settings_get "$l_tmp_root" TEMP_VAR 'default-temporary' 1)" ; then
      fail "get with auto-update failed"
    fi
    [ x"$l_value" = x'default-temporary' ] || fail "get with auto-update returned '$l_value'"
    l_prefix="`lcl_dot_local_matching_var_name_prefix TEMP_VAR`"
    l_match_text="`lcl_dot_local_matching_var_name TEMP_VAR`"
    if ! grep -q "${l_match_text}'default-temporary'" "$l_settings_path" ; then
      fail "auto-update did not append value"
    fi
    if [ "$(grep -c "^$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_settings_path")" != "1" ] ; then
      fail "tag line duplicated during auto-update"
    fi

    # delete should remove entry and keep tag intact
    lcl_dot_local_settings_delete "$l_tmp_root" TEMP_VAR || fail "delete existing failed"
    if grep -q "${l_match_text}" "$l_settings_path" ; then
      fail "delete did not remove TEMP_VAR"
    fi
    if [ "$(grep -c "^$g_DOT_LOCAL_SETTINGS_TAG_LINE" "$l_settings_path")" != "1" ] ; then
      fail "tag line missing after delete"
    fi

    echo "lcl_dot_local_settings_self_test: OK"
  )
}
#
# versioning - return directory to local cached version folder
# usage: [cf-home]
function lcl_version_dir {
  local i_cf_home="$1" ; shift
  local l_local_dir="`lcl_dot_local_dir "$i_cf_home"`"
  local l_local_version_dir="$l_local_dir/version"
  echo "$l_local_version_dir"
}
#
# versioning - require that directory to local cached version folder exists
# usage: [cf-home]
function lcl_version_dir_require {
  local i_cf_home="$1" ; shift

  # get version and auto-create dir
  local l_local_version_dir="`lcl_version_dir "$i_cf_home"`"
  [ -d "$l_local_version_dir" ] && return 0
  mkdir -p "$l_local_version_dir" && return 0

  # show error and exit
  echo "MISSING: '$l_local_version_dir'"
  exit 2
}
#
# versioning - given [cf-home] and [filepath] return name of local versioned cache file
function lcl_version_file_fname {
  local i_cf_home="$1" ; shift
  local i_filepath="$1" ; shift

  # get sha256 from filepath to avoid duplicates on same fname in different folders
  # that require version caching
  local l_fname="`echo "$i_filepath" | shasum -a 256 | cut -d' ' -f1 | dos2unix`"
  echo "$l_fname"
}
#
# versioning - given [cf-home] and [filepath] return path to local versioned cache file
function lcl_version_file_path {
  local i_cf_home="$1" ; shift
  local i_filepath="$1" ; shift

  # extract just fname from input filepath
  local l_fname="`lcl_version_file_fname "$i_cf_home" "$i_filepath"`"

  # get full path to cached file
  local l_local_version_dir="`lcl_version_dir "$i_cf_home"`"
  local l_local_version_fpath="$l_local_version_dir/$l_fname"
  echo "$l_local_version_fpath"
}
#
# versioning - given an input global env var, return a localized name
# usage: [cf-home] [filepath] [env-var]
function lcl_version_var_name {
  local i_cf_home="$1" ; shift
  local i_filepath="$1" ; shift
  local i_envvar="$1" ; shift

  # extract just fname from input filepath
  local l_fname="`lcl_version_file_fname "$i_cf_home" "$i_filepath"`"

  # normalize and lcase
  local l_fname_normalized="`echo "$l_fname" | sed -e 's/[^A-Za-z0-9_]/_/g' | tr '[A-Z]' '[a-z]'`"

  # return 
  echo "lcl_version_var_$l_fname_normalized_$i_envvar"
}
#
# versioning - given an input global env var, return its value.
# usage: [cf-home] [filepath] [env-var]
#
# note: this method does *not* source any files; it checks only current env
function lcl_version_var_value {
  local i_cf_home="$1" ; shift
  local i_filepath="$1" ; shift
  local i_envvar="$1" ; shift

  # get var name
  local l_var_name="`lcl_version_var_name "$i_cf_home" "$i_filepath" "$i_envvar"`"

  # return indirect value
  echo "${!l_var_name}"
}
#
# versioning - detect if a file is changed based on version number / global-release
# usage: [cf-home] [filepath]
function lcl_version_is_file_changed {
  local i_cf_home="$1" ; shift
  local i_filepath="$1" ; shift

  # setup
  lcl_version_dir_require "$i_cf_home"
  local l_local_version_fpath="`lcl_version_file_path "$i_cf_home" "$i_filepath"`"

  # if not exists - file is changed
  [ ! -s "$l_local_version_fpath" ] && return 0

  # note: we do *not* check date/time - just what the cached version info is

  # source in the *current* backend variables to get version
  source "$i_cf_home"/scripts/cf-env-vars.sh 'source-only' || exit $?

  # get the cached file version variables
  source "$l_local_version_fpath" || exit $?

  # iterate over env vars to check
  local l_envvar=''
  local l_cur_value=''
  local l_cached_value=''
  for i in $g_VERSION_ENV_VARS_TO_CHECK ; do
    #set -x
    l_envvar="$i"
    l_cur_value="${!l_envvar}"
    l_cached_value="`lcl_version_var_value "$i_cf_home" "$i_filepath" "$l_envvar"`"
    [ x"$l_cached_value" != x"$l_cur_value" ] && return 0
    set +x
  done

  # unchanged
  return 1
}
#
# versioning - update cache file with all cached information
# usage: [cf-home] [filepath]
function lcl_version_update {
  local i_cf_home="$1" ; shift
  local i_filepath="$1" ; shift

  # setup
  lcl_version_dir_require "$i_cf_home"
  local l_local_version_fpath="`lcl_version_file_path "$i_cf_home" "$i_filepath"`"

  # source in the *current* backend variables to get version
  #set -x
  source "$i_cf_home"/scripts/cf-env-vars.sh 'source-only' || exit $?
  set +x

  # iterate over all variables, updating the target
  echo "#!/bin/bash" > "$l_local_version_fpath" || exit $?
  echo "# Version Cache: $i_filepath" >> "$l_local_version_fpath" || exit $?
  echo "# Last Generated: `date`" >> "$l_local_version_fpath" || exit $?
  echo '' >> "$l_local_version_fpath" || exit $?

  # we may want to cache everything but for now we just cache 
  # FULL / BUILD_NUMBER for backend
  local l_envvar=''
  local l_envvar_name=''
  local l_envvar_value=''
  for i in $g_VERSION_ENV_VARS_TO_CHECK ; do
    l_envvar="$i"
    l_envvar_name="`lcl_version_var_name "$i_cf_home" "$i_filepath" "$l_envvar"`"
    l_envvar_value="${!l_envvar}"
    echo "export $l_envvar_name='$l_envvar_value'" >> "$l_local_version_fpath" || exit $?
  done

  # make executable
  chmod +x "$l_local_version_fpath" || exit $?
  return 0
}
#
# normalize version for package managers (SemVer-compatible)
#
# npm accepts SemVer with optional prerelease tags. We normalize the backend
# version (expected format A.B.C) into `A.B.C-build.<build>` so each generated
# package remains unique per build.
function lcl_version_normalize_npm {
  local i_short="${1:-}"
  local i_build_raw="${2:-$g_VERSION_NORMALIZE_DEFAULT_BUILD}"

  if [ x"$i_short" = x ]; then
    echo "lcl_version_normalize_npm: missing short version" >&2
    return 1
  fi

  local i_build="$(echo "$i_build_raw" | tr -cd '0-9')"
  if [ x"$i_build" = x ]; then
    i_build="$g_VERSION_NORMALIZE_DEFAULT_BUILD"
  fi

  echo "${i_short}-build.$i_build"
}
#
# NuGet also supports SemVer 2.0.0, so we reuse the `-build.<build>` pattern.
function lcl_version_normalize_nuget {
  local i_short="${1:-}"
  local i_build_raw="${2:-$g_VERSION_NORMALIZE_DEFAULT_BUILD}"

  if [ x"$i_short" = x ]; then
    echo "lcl_version_normalize_nuget: missing short version" >&2
    return 1
  fi

  local i_build="$(echo "$i_build_raw" | tr -cd '0-9')"
  if [ x"$i_build" = x ]; then
    i_build="$g_VERSION_NORMALIZE_DEFAULT_BUILD"
  fi

  echo "${i_short}-build.$i_build"
}
#
# versioning - self test helper to validate version cache behavior
# usage: [cf-home]
function lcl_version_self_test {
  (
    local l_cf_home="${1:-`lcl_os_pwd`}"
    local l_targets
    l_targets=("$l_cf_home/infra/README.md" "$l_cf_home/infra/aws/README.md")
    local l_cache_paths=()
    local l_backup_paths=()
    local l_had_original=()
    local l_backup_root="`lcl_os_tmp_dir`/lcl-version-self-test-$$"

    fail() {
      echo "$*" >&2
      exit 1
    }

    rm -fR "$l_backup_root"
    mkdir -p "$l_backup_root" || fail "unable to create backup dir '$l_backup_root'"

    cleanup() {
      local l_idx=''
      #set -x
      for l_idx in "${!l_cache_paths[@]}"; do
        rm -f "${l_cache_paths[$l_idx]}"
        if [ x"${l_had_original[$l_idx]}" = x1 ] && [ -s "${l_backup_paths[$l_idx]}" ] ; then
          /bin/cp "${l_backup_paths[$l_idx]}" "${l_cache_paths[$l_idx]}"
        fi
      done
      rm -fR "$l_backup_root"
      set +x
    }
    trap cleanup EXIT

    lcl_version_dir_require "$l_cf_home"

    local l_idx=''
    for l_idx in "${!l_targets[@]}"; do
      local l_file="${l_targets[$l_idx]}"
      [ -f "$l_file" ] || fail "missing target '$l_file'"
      local l_cache_path="`lcl_version_file_path "$l_cf_home" "$l_file"`"
      l_cache_paths[$l_idx]="$l_cache_path"
      if [ -e "$l_cache_path" ] ; then
        local l_backup_path="$l_backup_root/backup-$l_idx"
        /bin/cp "$l_cache_path" "$l_backup_path" || fail "unable to backup '$l_cache_path'"
        l_backup_paths[$l_idx]="$l_backup_path"
        l_had_original[$l_idx]=1
      else
        l_backup_paths[$l_idx]=''
        l_had_original[$l_idx]=0
      fi
    done

    if [ "${l_cache_paths[0]}" = "${l_cache_paths[1]}" ] ; then
      fail "cache paths collided for README targets"
    fi

    export CF_BACKEND_VERSION_FULL='9.9.9.0'
    export CF_BACKEND_BUILD_NUMBER='20250101000000'
    echo "lcl_version_self_test: priming caches"
    for l_idx in "${!l_targets[@]}"; do
      echo "  ${l_targets[$l_idx]}"
      lcl_version_update "$l_cf_home" "${l_targets[$l_idx]}" || fail "initial update failed"
    done

    echo "lcl_version_self_test: validating unchanged state"
    for l_idx in "${!l_targets[@]}"; do
      echo "  ${l_targets[$l_idx]}"
      if lcl_version_is_file_changed "$l_cf_home" "${l_targets[$l_idx]}"; then
        fail "    unexpected change flagged for ${l_targets[$l_idx]}"
      fi
    done

    export CF_BACKEND_BUILD_NUMBER='20250102000000'
    echo "lcl_version_self_test: validating changed state"
    for l_idx in "${!l_targets[@]}"; do
      echo "  ${l_targets[$l_idx]}"
      if ! lcl_version_is_file_changed "$l_cf_home" "${l_targets[$l_idx]}"; then
        fail "    change not detected for ${l_targets[$l_idx]}"
      fi
    done

    echo "lcl_version_self_test: refreshing caches post-change"
    for l_idx in "${!l_targets[@]}"; do
      echo "  ${l_targets[$l_idx]}"
      lcl_version_update "$l_cf_home" "${l_targets[$l_idx]}" || fail "    refresh update failed"
    done

    echo "lcl_version_self_test: verifying clean state"
    for l_idx in "${!l_targets[@]}"; do
      echo "  ${l_targets[$l_idx]}"
      if lcl_version_is_file_changed "$l_cf_home" "${l_targets[$l_idx]}"; then
        fail "    unexpected change after refresh for ${l_targets[$l_idx]}"
      fi
    done

    echo "lcl_version_self_test: OK"
  )
}

######################################################################
# PEP
#
# id the os (once per run)
if [ x"$g_UNAME" = x ] ; then
  g_UNAME="`uname -s`"
  g_VALID_OS=1
  case "${g_UNAME}" in
    Linux*)     g_UNAME_MACHINE=Linux; g_IS_LINUX=1;;
    Darwin*)    g_UNAME_MACHINE=Mac; g_IS_MAC=1;;
    CYGWIN*)    g_UNAME_MACHINE=Cygwin; g_IS_CYGWIN=1; g_JAVA_BINARY='java.exe';;
    MINGW*)     g_UNAME_MACHINE=MinGw; g_IS_CYGWIN=1; g_IS_MINGW=1;;
    *)          g_UNAME_MACHINE="UNKNOWN:${g_UNAME}" ; g_VALID_OS=0 ;;
  esac
fi

# indicate no error
true
