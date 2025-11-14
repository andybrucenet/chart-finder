#!/bin/bash
# sync-configs.sh, ABr
#
# Synchronize all configuration files from source to "hydrated" form under .local folder.
# In this context: "hydration" means that env references are resolved.
# This ensures we do not check in sensitive information such as cloud account numbers.

##############################################################
# OPTIONS
#
# known list of filenames to ignore because they are handled independently
SYNC_CONFIG_OPTION_FNAMES_TO_IGNORE="${SYNC_CONFIG_OPTION_FNAMES_TO_IGNORE:-samconfig.toml.in}"

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_sync_configs_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_sync_configs_root_dir="$( realpath "$the_sync_configs_script_dir"/.. )"
source "$the_sync_configs_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_sync_configs_root_dir" || exit $?
#
# we also need all standard env vars including version information for proper config hydration
the_sync_configs_local_dir="$the_sync_configs_root_dir/$g_DOT_LOCAL_DIR_NAME"
source "$the_sync_configs_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

##############################################################
# temp and user settings
#
# tmp is problematic on cygwin
the_sync_configs_tmp_dir="`lcl_os_tmp_dir`"
the_sync_configs_tmp_fname_prefix="sync-configs-$$-"
the_sync_configs_tmp_path_prefix="$the_sync_configs_tmp_dir/$the_sync_configs_tmp_fname_prefix"

##############################################################
# functions
#
# automatic cleanup on exit
sync_configs_cleanup() {
  rm -fR "$the_sync_configs_tmp_path_prefix"*
}
#
# exit with return code
sync_configs_exit() {
  local i_rc="$1" ; shift
  [ x"$i_rc" = x ] && i_rc=0
  exit $i_rc
}
#
# exit on error
sync_configs_error_exit() {
  local i_rc="$1" ; shift
  echo "ERROR: $@"
  sync_configs_exit "$i_rc"
}
#
# exit on error
sync_configs_cond_exit() {
  local i_rc="$1" ; shift
  [ x"$i_rc" = x ] && return 0
  [ x"$i_rc" = x0 ] && return 0
  sync_configs_error_exit "$i_rc" "$@"
}
#
# process one directory
sync_configs_process_dir() {
  local i_infra_dir="$1" ; shift
  local i_local_dir="$1" ; shift
  local i_dir_to_process="$1" ; shift
  local i_tmp_path_prefix="$1" ; shift

  # locals
  local l_rc=0
  local l_rc_cmd=0
  local l_src_dir="$i_infra_dir/$i_dir_to_process"
  local l_dst_dir="$i_local_dir/infra/$i_dir_to_process"
  local l_tmp_path_error="${i_tmp_path_prefix}error.txt"
  local l_src_path=''
  local l_dst_path=''
  local l_dst_path_exists=0
  local l_tmp_path="${i_tmp_path_prefix}tmp.txt"
  local l_src_requires_hydration=0
  local l_ignore_fname=0

  # normalize i_dir_to_process
  i_dir_to_process="`echo "$i_dir_to_process" | sed -e 's/^\.\///'`"
  if echo "$i_dir_to_process" | grep -e '^\.' >/dev/null 2>&1 ; then
    # ignore . (dot) directory
    return 0
  fi

  /bin/echo -n "$i_dir_to_process: "

  # create target
  [ ! -d "$l_dst_dir" ] && mkdir -p "$l_dst_dir"
  [ ! -d "$l_dst_dir" ] && echo "ERROR" && return 1

  # read each source file
  cd "$l_src_dir"
  for i in * ; do
    # ignore directory fname and empty directory
    [ x"$i" = x'*' ] && continue
    [ -d "$i" ] && continue

    # ignore if fname is handled independently of this script
    l_ignore_fname=0
    for j in $SYNC_CONFIG_OPTION_FNAMES_TO_IGNORE ; do
      [ "$i" = "$j" ] && l_ignore_fname=1 && break
    done
    [ $l_ignore_fname -eq 1 ] && continue

    # process
    l_src_path="$l_src_dir/$i"
    l_dst_path="$l_dst_dir/${i%.in}"

    # check if hydration required
    l_src_requires_hydration=0
    l_rc_cmd=0
    if echo "$l_src_path" | grep -e '\.in$' >/dev/null 2>&1 ; then
      l_src_requires_hydration=1
    fi
    if [ $l_src_requires_hydration -eq 0 ] ; then
      if [ -L "$l_dst_path" ]; then
        current_target="$(readlink "$l_dst_path")"
        if [ "$current_target" = "$l_src_path" ]; then
          # already pointing at the right file; leave timestamps alone
          continue
        fi
      fi

      # simple link
      ln -sfn "$l_src_path" "$l_dst_path" >>"$l_tmp_path_error" 2>&1
      l_rc_cmd=$?
    else
      # detect if destination was a softlink - if so, delete it
      [ -L "$l_dst_path" ] && rm -f "$l_dst_path"

      # hydrate to tmp (always)
      DOLLAR='$' envsubst <"$l_src_path" >"$l_tmp_path" 2>>"$l_tmp_path_error"
      l_rc_cmd=$?

      # compare hydrated to dst
      if [ $l_rc_cmd -eq 0 ] ; then
        l_dst_path_exists=0
        [ -s "$l_dst_path" ] && l_dst_path_exists=1
        if [ $l_dst_path_exists -eq 0 ] ; then
          # create the dest file from the source file to preserve attrs / perms
          /bin/cp "$l_src_path" "$l_dst_path" 2>>"$l_tmp_path_error"
          l_rc_cmd=$?
        fi

        # now update the guaranteed-existing file only if contents change
        if ! cmp -s "$l_tmp_path" "$l_dst_path" ; then
          # reset existing dst (saves perms / attrs)
          truncate -s 0 "$l_dst_path" 2>>"$l_tmp_path_error"
          l_rc_cmd=$?
          if [ $l_rc_cmd -eq 0 ] ; then
            # and replace contents
            cat "$l_tmp_path" >> "$l_dst_path" 2>>"$l_tmp_path_error"
            l_rc_cmd=$?
          fi
        fi
      fi

      # always done with tmp file here
      rm -f "$l_tmp_path"
    fi
    [ $l_rc -eq 0 ] && l_rc=$l_rc_cmd
  done
  
  # handle error
  if [ $l_rc -eq 0 ] ; then
    echo 'OK'
  else
    echo 'ERROR'
    cat "$l_tmp_path_error" | sed -e 's/^/  /'
  fi

  # function result (zero for success)
  return $l_rc
}

##############################################################
# program
#
# ensure cleanup on exit
trap sync_configs_cleanup EXIT ERR INT TERM
#
# read the list of dirs to process (relative paths)
the_sync_configs_dirs_path="${the_sync_configs_tmp_path_prefix}dirs.txt"
the_sync_configs_dirs_infra_dir="$the_sync_configs_root_dir"/infra
cd "$the_sync_configs_dirs_infra_dir"
find . -type d >"$the_sync_configs_dirs_path"
#
# process each dir
the_sync_configs_local_dir="$the_sync_configs_root_dir/$g_DOT_LOCAL_DIR_NAME"
the_rc=0
the_rc_final=0
while IFS= read -r line; do
  sync_configs_process_dir "$the_sync_configs_dirs_infra_dir" "$the_sync_configs_local_dir" "$line" "$the_sync_configs_tmp_path_prefix"
  the_rc=$?
  [ $the_rc_final -eq 0 ] && the_rc_final=$the_rc
done < "$the_sync_configs_dirs_path"

# warn about files that require manual hydration
for ignore_fname in $SYNC_CONFIG_OPTION_FNAMES_TO_IGNORE; do
  while IFS= read -r src_path; do
    [ -z "$src_path" ] && continue
    dst_rel="${src_path#$the_sync_configs_dirs_infra_dir/}"
    dst_path="$the_sync_configs_local_dir/infra/${dst_rel%.in}"
    the_rc=0
    if [ ! -f "$dst_path" ]; then
      echo "WARN: missing hydrated copy for $dst_path; run ./scripts/setup-dev-env.sh"
      the_rc=99
    elif [ "$src_path" -nt "$dst_path" ]; then
      echo "WARN: template updated for $src_path; rerun ./scripts/setup-dev-env.sh to refresh $dst_path"
      the_rc=1
    fi
    [ $the_rc_final -eq 0 ] && the_rc_final=$the_rc
  done < <(find "$the_sync_configs_dirs_infra_dir" -name "$ignore_fname" -print)
done
#
# all done
sync_configs_exit $the_rc_final
