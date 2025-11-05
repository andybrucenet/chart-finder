#!/bin/bash
# aws-is-logged-in.sh, ABr
#
# Check if user is logged-in to AWS

##############################################################
# OPTIONS
AWS_IS_LOGGED_IN_OPTION_SHOW_LOGIN_INFO="${AWS_IS_LOGGED_IN_OPTION_SHOW_LOGIN_INFO:-0}"

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_is_logged_in_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_is_logged_in_root_dir="$( realpath "$the_aws_is_logged_in_script_dir"/.. )"
source "$the_aws_is_logged_in_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?

##############################################################
# tmp is problematic on cygwin
the_aws_is_logged_in_tmp_dir="`lcl_os_tmp_dir`"
the_aws_is_logged_in_tmp_fname_prefix="aws-is-logged-in-$$-"
the_aws_is_logged_in_tmp_path_prefix="$the_aws_is_logged_in_tmp_dir/$the_aws_is_logged_in_tmp_fname_prefix"

# logged in?
the_aws_is_logged_in_wrk_path="${the_aws_is_logged_in_tmp_path_prefix}info.txt"
"$the_aws_is_logged_in_root_dir/scripts/aws-run-cmd.sh" aws sts get-caller-identity >"$the_aws_is_logged_in_wrk_path" 2>&1
the_rc=$?
if [ $the_rc -eq 0 ] ; then
  [ x"$AWS_IS_LOGGED_IN_OPTION_SHOW_LOGIN_INFO" = x1 ] && cat "$the_aws_is_logged_in_wrk_path"
  exit 0
fi
[ x"$AWS_IS_LOGGED_IN_OPTION_SHOW_LOGIN_INFO" = x1 ] && cat "$the_aws_is_logged_in_wrk_path"
rm -f "$the_aws_is_logged_in_wrk_path"

# not logged-in
exit 1

