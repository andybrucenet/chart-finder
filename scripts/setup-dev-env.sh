#!/bin/bash
# setup-dev-env.sh, ABr
#
# Initial dev setup for chart-finder project.

##############################################################
# OPTIONS
SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS="${SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS:-0}"
#
# known inferred values
if [ x"$SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS" = x1 ] ; then
  # add known cloud-specific settings as necessary
  export SETUP_DEV_ENV_AWS_OPTION_RESET_USER_SETTINGS=1
fi

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
the_setup_dev_env_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_setup_dev_env_root_dir="$( realpath "$the_setup_dev_env_script_dir"/.. )"
source "$the_setup_dev_env_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?

# infra contains all the raw input cloud configuration files
the_setup_dev_env_infra_dir_name="infra"
the_setup_dev_env_infra_src_dir="$the_setup_dev_env_root_dir/$the_setup_dev_env_infra_dir_name"

# .local contains all user-local files not checked into git
# this includes hydrated infra files
the_setup_dev_env_local_dir="$the_setup_dev_env_root_dir/$g_DOT_LOCAL_DIR_NAME"
the_setup_dev_env_local_infra_dir="$the_setup_dev_env_local_dir/$the_setup_dev_env_infra_dir_name"
#
# local.env contains user-specific cloud settings (ex: AWS variables)
# this hides sensitive cloud tokens and information from src control
the_setup_dev_env_local_env_fname="$g_DOT_LOCAL_SETTINGS_FNAME"
the_setup_dev_env_local_env_path="$the_setup_dev_env_local_dir/$the_setup_dev_env_local_env_fname"

# required tools
the_setup_dev_env_tools_ok=1
the_setup_dev_env_tools='which aws envsubst rsync sam jq'
for i in $the_setup_dev_env_tools ; do
  ! which $i >/dev/null 2>&1 && echo "ERROR: MISSING_REQUIRED_TOOL $i" && the_setup_dev_env_tools_ok=0
done
[ $the_setup_dev_env_tools_ok -ne 1 ] && exit 1

##############################################################
# tmp is problematic on cygwin
the_setup_dev_env_tmp_dir="`lcl_os_tmp_dir`"
the_setup_dev_env_tmp_fname_prefix='setup-dev-env-'
the_setup_dev_env_tmp_path_prefix="$the_setup_dev_env_tmp_dir/$the_setup_dev_env_tmp_fname_prefix"

##############################################################
# program start
echo '**DEV SETUP...'
echo ''

##############################################################
# get user settings
echo 'COMMON USER SETTINGS...'
if [ x"$SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS" = x1 ] ; then
  lcl_dot_local_settings_reset "$the_setup_dev_env_root_dir" || exit $?
  unset CF_LOCAL_DEV_ID CF_LOCAL_USEREMAIL CF_LOCAL_ENV_ID
fi
lcl_dot_local_settings_source "$the_setup_dev_env_root_dir"
#
if [ x"$CF_ROOT" = x ] ; then
  the_default_value="$the_setup_dev_env_root_dir"
  read -p "  Enter value for CF_ROOT [$the_default_value]: " CF_ROOT
  CF_ROOT="${CF_ROOT:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_ROOT "$CF_ROOT" || exit $?
  export CF_ROOT
fi
echo "  CF_ROOT='$CF_ROOT'"
#
if [ x"$CF_LOCAL_DEV_ID" = x ] ; then
  the_default_value="$(whoami | sed -e 's/^l[\.\-]//')"
  read -p "  Enter value for CF_LOCAL_DEV_ID [$the_default_value]: " CF_LOCAL_DEV_ID
  CF_LOCAL_DEV_ID="${CF_LOCAL_DEV_ID:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_DEV_ID "$CF_LOCAL_DEV_ID" || exit $?
  export CF_LOCAL_DEV_ID
fi
echo "  CF_LOCAL_DEV_ID='$CF_LOCAL_DEV_ID'"
#
if [ x"$CF_LOCAL_ENV_ID" = x ] ; then
  the_default_value="cf-$CF_LOCAL_DEV_ID"
  read -p "  Enter value for CF_LOCAL_ENV_ID [$the_default_value]: " CF_LOCAL_ENV_ID
  CF_LOCAL_ENV_ID="${CF_LOCAL_ENV_ID:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_ENV_ID "$CF_LOCAL_ENV_ID" || exit $?
  export CF_LOCAL_ENV_ID
fi
echo "  CF_LOCAL_ENV_ID='$CF_LOCAL_ENV_ID'"
#
if [ x"$CF_LOCAL_USEREMAIL" = x ] ; then
  read -p "  Enter value for CF_LOCAL_USEREMAIL: " CF_LOCAL_USEREMAIL
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_USEREMAIL "$CF_LOCAL_USEREMAIL" || exit $?
  export CF_LOCAL_USEREMAIL
fi
[ x"$CF_LOCAL_USEREMAIL" = x ] && echo 'Empty CF_LOCAL_USEREMAIL' && exit 1
echo "  CF_LOCAL_USEREMAIL='$CF_LOCAL_USEREMAIL'"
#
echo '  OK'
echo ''

##############################################################
# AWS settings
"$the_setup_dev_env_root_dir"/scripts/setup-dev-env-aws.sh || exit $?

# all good
true
 
