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

##############################################################
# required tools (global)
the_setup_dev_env_tools_ok=1
the_setup_dev_env_tools='which envsubst jq npm rsync'
for i in $the_setup_dev_env_tools ; do
	! which $i >/dev/null 2>&1 && echo "ERROR: MISSING_REQUIRED_TOOL (GLOBAL) $i" && the_setup_dev_env_tools_ok=0
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
  unset CF_HOME CF_LOCAL_PRJ_ID CF_LOCAL_DOMAIN CF_LOCAL_TLS_CERT_PATH CF_LOCAL_TLS_CHAIN_PATH CF_LOCAL_TLS_KEY_PATH CF_LOCAL_DEV_ID CF_LOCAL_BILLING_ENV CF_LOCAL_ENV_ID CF_LOCAL_USEREMAIL
fi
lcl_dot_local_settings_source "$the_setup_dev_env_root_dir"
#
if [ x"$CF_HOME" = x ] ; then
  the_default_value="$the_setup_dev_env_root_dir"
  read -p "  Enter value for CF_HOME [$the_default_value]: " CF_HOME
  CF_HOME="${CF_HOME:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_HOME "$CF_HOME" || exit $?
  export CF_HOME
fi
echo "  CF_HOME='$CF_HOME'"
#
lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_PRJ_ID 'cf' || exit $?
export CF_LOCAL_PRJ_ID
echo "  CF_LOCAL_PRJ_ID='$CF_LOCAL_PRJ_ID' (abbreviation for 'chart-finder')"
#
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_DOMAIN 'chart-finder.app' || exit $?
  export CF_LOCAL_DOMAIN
  echo "  CF_LOCAL_DOMAIN='$CF_LOCAL_DOMAIN'"
#
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_CLOUD_PROVIDER 'aws' || exit $?
  export CF_LOCAL_CLOUD_PROVIDER
  echo "  CF_LOCAL_CLOUD_PROVIDER='$CF_LOCAL_CLOUD_PROVIDER'"
#
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_TLS_CERT_PATH "$HOME/Documents/Personal/andy/certs/ssl/chart-finder/config/live/$CF_LOCAL_DOMAIN/cert.pem" || exit $?
  export CF_LOCAL_TLS_CERT_PATH
  echo "  CF_LOCAL_TLS_CERT_PATH='$CF_LOCAL_TLS_CERT_PATH'"
#
lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_TLS_CHAIN_PATH "$HOME/Documents/Personal/andy/certs/ssl/chart-finder/config/live/$CF_LOCAL_DOMAIN/chain.pem" || exit $?
export CF_LOCAL_TLS_CHAIN_PATH
echo "  CF_LOCAL_TLS_CHAIN_PATH='$CF_LOCAL_TLS_CHAIN_PATH'"
#
lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_TLS_KEY_PATH "$HOME/Documents/Personal/andy/certs/ssl/chart-finder/config/live/$CF_LOCAL_DOMAIN/privkey.pem" || exit $?
export CF_LOCAL_TLS_KEY_PATH
echo "  CF_LOCAL_TLS_KEY_PATH='$CF_LOCAL_TLS_KEY_PATH'"
#
if [ x"$CF_LOCAL_DEV_ID" = x ] ; then
  the_default_value="$(whoami | sed -e 's/^l[\.\-]//')-dev"
  read -p "  Enter value for CF_LOCAL_DEV_ID [$the_default_value]: " CF_LOCAL_DEV_ID
  CF_LOCAL_DEV_ID="${CF_LOCAL_DEV_ID:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_DEV_ID "$CF_LOCAL_DEV_ID" || exit $?
  export CF_LOCAL_DEV_ID
fi
echo "  CF_LOCAL_DEV_ID='$CF_LOCAL_DEV_ID'"
#
if [ x"$CF_LOCAL_BILLING_ENV" = x ] ; then
  the_default_value='dev'
  read -p "  Enter value for CF_LOCAL_BILLING_ENV [$the_default_value]: " CF_LOCAL_BILLING_ENV
  CF_LOCAL_BILLING_ENV="${CF_LOCAL_BILLING_ENV:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_BILLING_ENV "$CF_LOCAL_BILLING_ENV" || exit $?
  export CF_LOCAL_BILLING_ENV
fi
echo "  CF_LOCAL_BILLING_ENV='$CF_LOCAL_BILLING_ENV'"
#
if [ x"$CF_LOCAL_ENV_ID" = x ] ; then
  the_default_value="$CF_LOCAL_PRJ_ID-$CF_LOCAL_DEV_ID"
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
if [ x"$CF_LOCAL_BACKEND_API_KEY_NUGET_ORG" = x ] ; then
  read -p "  Enter value for CF_LOCAL_BACKEND_API_KEY_NUGET_ORG (nuget.org ChartFinder.Client push key): " CF_LOCAL_BACKEND_API_KEY_NUGET_ORG
  lcl_dot_local_settings_update "$the_setup_dev_env_root_dir" CF_LOCAL_BACKEND_API_KEY_NUGET_ORG "$CF_LOCAL_BACKEND_API_KEY_NUGET_ORG" || exit $?
  export CF_LOCAL_BACKEND_API_KEY_NUGET_ORG
fi
echo "  CF_LOCAL_BACKEND_API_KEY_NUGET_ORG set"
#
echo '  OK'
echo ''

##############################################################
# AWS settings
"$the_setup_dev_env_root_dir"/scripts/setup-dev-env-aws.sh || exit $?
# all good
true
 
