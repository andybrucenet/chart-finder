#!/bin/bash
# sync-configs.sh, ABr
#
# Synchronize all configuration files from source to "hydrated" form under .local folder.
# In this context: "hydration" means that env references are resolved.
# This ensures we do not check in sensitive information such as cloud account numbers.

##############################################################
# OPTIONS

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
the_sync_configs_local_dir="$the_sync_configs_root_dir/.local"

##############################################################
# temp and user settings
#
# tmp is problematic on cygwin
the_sync_configs_tmp_dir='/tmp'
the_sync_configs_tmp_fname_prefix="sync-configs-$$-"
the_sync_configs_tmp_path_prefix="$the_sync_configs_tmp_dir/$the_sync_configs_tmp_fname_prefix"
#
# get user settings
if [ -s "$the_sync_configs_local_dir/local.env" ] ; then
  source "$the_sync_configs_local_dir/local.env" || exit $?
fi

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
  local i_local_dir="$1" ; shift
  local i_src_dir="$1" ; shift
  local i_tmp_path_prefix="$1" ; shift

  # local manifest name (optional file)
  local l_manifest_fname='sync-manifest.txt'
  local l_manifest_src_path="$i_src_dir/$l_manifest_fname"

  # locals
  local l_rc=0
  local l_rc_cmd=0
  local l_tmp_path_error="${i_tmp_path_prefix}error.txt"
  local l_tmp_path_rsync="${i_tmp_path_prefix}rsync.out"
  local l_tmp_path_excluded="${i_tmp_path_prefix}excluded.txt"
  local l_tmp_path_work_1="${i_tmp_path_prefix}work1.txt"
  local l_tmp_path_work_2="${i_tmp_path_prefix}work2.txt"
	local l_fname=''
	local l_disposition=''
	local l_src_path=''

  /bin/echo -n "$i_local_dir: "
  cd "$i_local_dir"

  # simplest case: no manifest (all files linked)
  if [ ! -s "$l_manifest_src_path" ] ; then
    rsync -a --delete --link-dest "$i_local_dir/$i_src_dir" >"$l_tmp_path_rsync" 2>&1
    l_rc=$?
    [ $l_rc -eq 0 ] && echo 'OK' && return 0
    cat "$l_tmp_pth" | sed -e 's/^/  /'
    return $l_rc
  fi

	# read each file from manifest with its disposition
  rm -f "$l_tmp_path_error"
	local l_line=''
  while IFS= read -r l_line; do
		# ignore if empty or begins with '#'
		grep -e '^[ \t]*$' >/dev/null 2>&1 && continue
		grep -e '^[ \t]*#' >/dev/null 2>&1 && continue

		# split into fname and disposition
		l_fname="`echo "$l_line" | awk -F':' '{print $1}' | dos2unix`"
		l_disposition="`echo "$l_line" | awk -F':' '{print $2}' | dos2unix`"

		# missing file?
		if [ ! -f "$l_fname" ] ; then
			echo "Missing '$l_fname'" >> "$l_tmp_path_error"
			continue
		fi

		# add name to exclusion
		echo "$l_fname" >> "$l_tmp_path_excluded"

		# initial copy from source to work1
		/bin/cp "$l_fname" "$l_tmp_path_work_1" >>"$l_tmp_path_error" 2>&1
		l_rc_cmd=$? ; [ $l_rc -eq 0 ] && l_rc=$l_rc_cmd
		[ $l_rc_cmd -ne 0 ] && continue

		# step over every variable to process


  local l_tmp_path_work_2=''

		# hydrate as necessary
		[ x"$l_disposition" = x ] && l_disposition='hydrate'
		if [ x"$l_disposition" = x'hydrate' ] ; then
			sed


		# 
    sync_config_process_dir "$the_sync_configs_local_dir" "$line" "$the_sync_configs_tmp_path_prefix"
    the_rc=$?
    [ $the_rc_final -eq 0 ] && the_rc_final=$the_rc
  done < "$l_manifest_src_path"


  # all is well
  return 0
}

##############################################################
# program
#
# ensure cleanup on exit
trap cleanup_function EXIT ERR INT TERM
#
# read the list of dirs to process (relative paths)
the_sync_configs_dirs_path="${the_sync_configs_tmp_path_prefix}dirs.txt"
cd "$the_sync_configs_root_dir"/infra
find . -type d >"$the_sync_configs_dirs_path"
#
# get the list of variables to hydrate
#
# process each dir
the_sync_configs_local_dir="$the_sync_configs_root_dir/.local"
the_rc=0
the_rc_final=0
while IFS= read -r line; do
  sync_config_process_dir "$the_sync_configs_local_dir" "$line" "$the_sync_configs_tmp_path_prefix"
  the_rc=$?
  [ $the_rc_final -eq 0 ] && the_rc_final=$the_rc
done < "$the_sync_configs_dirs_path"
#
# all done
sync_configs_exit $the_rc_final

