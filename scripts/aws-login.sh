#!/bin/bash
# aws-login.sh, ABr
#
# Check if user is logged-in to AWS and login if necessary

##############################################################
# OPTIONS
AWS_LOGIN_OPTION_SHOW_LOGIN_INFO="${AWS_LOGIN_OPTION_SHOW_LOGIN_INFO:-1}"

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_login_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_login_root_dir="$( realpath "$the_aws_login_script_dir"/.. )"
source "$the_aws_login_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?

##############################################################
# tmp is problematic on cygwin
the_aws_login_tmp_dir="`lcl_os_tmp_dir`"
the_aws_login_tmp_fname_prefix="aws-login-$$-"
the_aws_login_tmp_path_prefix="$the_aws_login_tmp_dir/$the_aws_login_tmp_fname_prefix"

# logged in? (note - on error do *not show* problems)
the_aws_login_wrk_path="${the_aws_login_tmp_path_prefix}info.txt"
"$the_aws_login_root_dir/scripts/cf-run-cmd.sh" aws sts get-caller-identity --no-cli-pager >"$the_aws_login_wrk_path" 2>&1
the_rc=$?
if [ $the_rc -eq 0 ] ; then
  [ x"$AWS_LOGIN_OPTION_SHOW_LOGIN_INFO" = x1 ] && cat "$the_aws_login_wrk_path"
  exit 0
fi
rm -f "$the_aws_login_wrk_path"

# perform a login without launching browser against the current profile
"$the_aws_login_root_dir/scripts/cf-run-cmd.sh" aws sso login --no-browser --no-cli-pager

# run again to show the login info
[ x"$AWS_LOGIN_OPTION_SHOW_LOGIN_INFO" = x1 ] && "$the_aws_login_root_dir/scripts/cf-run-cmd.sh" aws sts get-caller-identity --no-cli-pager
