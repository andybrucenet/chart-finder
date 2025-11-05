#!/bin/bash
# aws-logout.sh, ABr
#
# Logout from AWS

##############################################################
# OPTIONS
AWS_LOGOUT_OPTION_QUIET="${AWS_LOGOUT_OPTION_QUIET:-0}"

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_logout_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_logout_root_dir="$( realpath "$the_aws_logout_script_dir"/.. )"
source "$the_aws_logout_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?

##############################################################
# tmp is problematic on cygwin
the_aws_logout_tmp_dir="`lcl_os_tmp_dir`"
the_aws_logout_tmp_fname_prefix="aws-logout-$$-"
the_aws_logout_tmp_path_prefix="$the_aws_logout_tmp_dir/$the_aws_logout_tmp_fname_prefix"

# logged in?
the_aws_logout_wrk_path="${the_aws_logout_tmp_path_prefix}info.txt"
"$the_aws_logout_root_dir/scripts/aws-run-cmd.sh" aws sts get-caller-identity >"$the_aws_logout_wrk_path" 2>&1
the_rc=$?
if [ $the_rc -eq 0 ] ; then
  if [ x"$AWS_LOGOUT_OPTION_QUIET" = x1 ] ; then
    "$the_aws_logout_root_dir/scripts/aws-run-cmd.sh" ./scripts/aws-run-cmd.sh aws sso logout >"$the_aws_logout_wrk_path" 2>&1
    the_rc=$?
    [ $the_rc -ne 0 ] && cat "$the_aws_logout_wrk_path"
  else
    echo 'LOGGING_OUT'
    "$the_aws_logout_root_dir/scripts/aws-run-cmd.sh" ./scripts/aws-run-cmd.sh aws sso logout
    the_rc=$?
  fi
else
  [ x"$AWS_LOGOUT_OPTION_QUIET" != x1 ] && echo 'NOT_LOGGED_IN'
  the_rc=0
fi
rm -f "$the_aws_logout_wrk_path"

exit $the_rc
