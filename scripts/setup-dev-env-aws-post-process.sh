#!/bin/bash
# setup-dev-env-aws-post-process.sh, ABr
#
# Post-process AWS-specific hydrated files

##############################################################
# locate script source directory and source OS tools
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_setup_env_dev_aws_post_process_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_setup_env_dev_aws_post_process_root_dir="$( realpath "$the_setup_env_dev_aws_post_process_script_dir"/.. )"
source "$the_setup_env_dev_aws_post_process_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?
#
# infra contains all the raw input cloud configuration files
the_setup_env_dev_aws_post_process_infra_dir_name="infra"
the_setup_env_dev_aws_post_process_infra_src_dir="$the_setup_env_dev_aws_post_process_root_dir/$the_setup_env_dev_aws_post_process_infra_dir_name"
#
# .local contains all user-local files not checked into git
# this includes hydrated infra files
the_setup_env_dev_aws_post_process_local_dir="$the_setup_env_dev_aws_post_process_root_dir/$g_DOT_LOCAL_DIR_NAME"
the_setup_env_dev_aws_post_process_local_infra_dir="$the_setup_env_dev_aws_post_process_local_dir/$the_setup_env_dev_aws_post_process_infra_dir_name"
#
# local.env contains user-specific cloud settings (ex: AWS variables)
# this hides sensitive cloud tokens and information from src control
the_setup_env_dev_aws_post_process_local_env_fname="$g_DOT_LOCAL_SETTINGS_FNAME"
the_setup_env_dev_aws_post_process_local_env_path="$the_setup_env_dev_aws_post_process_local_dir/$the_setup_env_dev_aws_post_process_local_env_fname"

##############################################################
# tmp is problematic on cygwin
the_setup_env_dev_aws_post_process_tmp_dir="`lcl_os_tmp_dir`"
the_setup_env_dev_aws_post_process_tmp_fname_prefix='setup-dev-env-aws-'
the_setup_env_dev_aws_post_process_tmp_path_prefix="$the_setup_env_dev_aws_post_process_tmp_dir/$the_setup_env_dev_aws_post_process_tmp_fname_prefix"

##############################################################
# program start
echo '**AWS POST-PROCESS'
echo ''

##############################################################
# get user settings
echo 'AWS USER SETTINGS...'
lcl_dot_local_settings_source "$the_setup_env_dev_aws_post_process_root_dir"
echo '  OK'
echo ''

##############################################################
# toggle generated samconfig.toml
#
# ensure aws login
echo 'CHECK AWS LOGIN...'
"$the_setup_env_dev_aws_post_process_root_dir/scripts/aws-login.sh" || exit $?
echo ''

#
# setup vars and verify destination actually exists
the_setup_env_dev_aws_post_process_aws_dst_dir="$the_setup_env_dev_aws_post_process_local_infra_dir/aws"
the_setup_env_dev_aws_post_process_sam_config_fname='samconfig.toml'
the_setup_env_dev_aws_post_process_sam_config_dst_path="$the_setup_env_dev_aws_post_process_aws_dst_dir/$the_setup_env_dev_aws_post_process_sam_config_fname"
the_setup_env_dev_aws_post_process_sam_config_wrk_path="$the_setup_env_dev_aws_post_process_tmp_path_prefix$the_setup_env_dev_aws_post_process_sam_config_fname"
the_setup_env_dev_aws_post_process_sam_config_wrk_path2="$the_setup_env_dev_aws_post_process_tmp_path_prefix$the_setup_env_dev_aws_post_process_sam_config_fname-2"
if [ ! -s "$the_setup_env_dev_aws_post_process_sam_config_dst_path" ] ; then
  echo "ERROR: MISSING: '$the_setup_env_dev_aws_post_process_sam_config_dst_path'"
  exit 2
fi
#
# extract value
the_setup_env_dev_aws_post_process_sam_config_dst_section_name="$CF_LOCAL_BILLING_ENV.deploy.parameters"
the_setup_env_dev_aws_post_process_sam_config_dst_var_name='template_file'
the_setup_env_dev_aws_post_process_sam_config_post_var_name='template_file_post'
the_setup_env_dev_aws_post_process_sam_config_post_var_value="`\
  cat "$the_setup_env_dev_aws_post_process_sam_config_dst_path" \
  | grep -e "^#$the_setup_env_dev_aws_post_process_sam_config_post_var_name[ \t][ \t]*" \
  | awk -F'=' '{print $2}' \
  | sed -e 's/"//g' \
  | xargs \
  | dos2unix`"
if [ x"$the_setup_env_dev_aws_post_process_sam_config_post_var_value" = x ] ; then
  echo "ERROR: MISSING '$the_setup_env_dev_aws_post_process_sam_config_post_var_name' from '$the_setup_env_dev_aws_post_process_sam_config_dst_path'"
  exit 1
fi
echo "CHECK: '$the_setup_env_dev_aws_post_process_sam_config_dst_path'"
echo "  FOUND: $the_setup_env_dev_aws_post_process_sam_config_post_var_name='$the_setup_env_dev_aws_post_process_sam_config_post_var_value'"
#
# extract the section we want and modify it
cat "$the_setup_env_dev_aws_post_process_sam_config_dst_path" \
  | awk '
    /^\['"$the_setup_env_dev_aws_post_process_sam_config_dst_section_name"'\]$/ { print; flag=1; next }
    /^\[/ { flag=0 }
    flag { print }
  ' \
  > "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" || exit $?
the_rc=0
if [ $the_rc -eq 0 ] ; then
  cat "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" \
    | sed -n "/^$the_setup_env_dev_aws_post_process_sam_config_dst_var_name /q; p" \
    > "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2"
  the_rc_local=$? ; [ $the_rc -eq 0 ] && the_rc=$the_rc_local
fi
if [ $the_rc -eq 0 ] ; then
  echo 'template_file = "'"$the_setup_env_dev_aws_post_process_sam_config_post_var_value"'"' \
    >> "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2"
  the_rc_local=$? ; [ $the_rc -eq 0 ] && the_rc=$the_rc_local
fi
if [ $the_rc -eq 0 ] ; then
  cat "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" \
    | sed -n "1,/^$the_setup_env_dev_aws_post_process_sam_config_dst_var_name /d; p" \
    >> "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2"
  the_rc_local=$? ; [ $the_rc -eq 0 ] && the_rc=$the_rc_local
fi
if [ $the_rc -ne 0 ] ; then
  rm -f "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2"
  exit $the_rc
fi
#
# extract from the original file up to the section, then the modified section, then the remainder
the_rc=0
if [ $the_rc -eq 0 ] ; then
  cat "$the_setup_env_dev_aws_post_process_sam_config_dst_path" \
    | sed -n '/^\['"$CF_LOCAL_BILLING_ENV"'\.deploy\.parameters\]/q; p' \
    > "$the_setup_env_dev_aws_post_process_sam_config_wrk_path"
  the_rc_local=$? ; [ $the_rc -eq 0 ] && the_rc=$the_rc_local
fi
if [ $the_rc -eq 0 ] ; then
  cat "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2" \
    >> "$the_setup_env_dev_aws_post_process_sam_config_wrk_path"
  the_rc_local=$? ; [ $the_rc -eq 0 ] && the_rc=$the_rc_local
fi
if [ $the_rc -eq 0 ] ; then
  cat "$the_setup_env_dev_aws_post_process_sam_config_dst_path" \
    | awk '
      flag == 2 { print; next }
      /^\['"$the_setup_env_dev_aws_post_process_sam_config_dst_section_name"'\]$/ { flag=1; next }
      flag == 1 {
        if ($0 ~ /^\[/) {
          flag = 2
          print
        }
        next
      }
    ' \
    >> "$the_setup_env_dev_aws_post_process_sam_config_wrk_path"
  the_rc_local=$? ; [ $the_rc -eq 0 ] && the_rc=$the_rc_local
fi
if [ $the_rc -ne 0 ] ; then
  rm -f "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2"
  exit $the_rc
fi

# early exit if necessary to eyeball the result
#cat "$the_setup_env_dev_aws_post_process_sam_config_wrk_path"
#exit 0

# update the file on disk
the_rc=0
if ! diff "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" "$the_setup_env_dev_aws_post_process_sam_config_dst_path" >/dev/null 2>&1 ; then
  cat "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" > "$the_setup_env_dev_aws_post_process_sam_config_dst_path"
  the_rc=$?
  [ $the_rc -eq 0 ] && echo '  OK (UPDATED)'
else
  echo '  OK (UNCHANGED)'
fi
rm -f "$the_setup_env_dev_aws_post_process_sam_config_wrk_path" "$the_setup_env_dev_aws_post_process_sam_config_wrk_path2"
[ $the_rc -ne 0 ] && exit $the_rc

# all good
true
