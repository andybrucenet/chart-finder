#!/bin/bash
# setup-dev-env.sh, ABr
#
# Initial dev setup for chart-finder project.

##############################################################
# OPTIONS
SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS="${SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS:-0}"
SETUP_DEV_ENV_OPTION_RESET_SAM_CONFIG="${SETUP_DEV_ENV_OPTION_RESET_SAM_CONFIG:-0}"
#
# inferred values
[ x"$SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS" = x1 ] && SETUP_DEV_ENV_OPTION_RESET_SAM_CONFIG=1

##############################################################
# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
#
# important locations
the_setup_dev_env_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_setup_dev_env_root_dir="$( realpath "$the_setup_dev_env_script_dir"/.. )"
#
# infra contains all the raw input cloud configuration files
the_setup_dev_env_infra_dir_name="infra"
the_setup_dev_env_infra_src_dir="$the_setup_dev_env_root_dir/$the_setup_dev_env_infra_dir_name"
#
# .local contains all user-local files not checked into git
# this includes hydrated infra files
the_setup_dev_env_local_dir="$the_setup_dev_env_root_dir/.local"
the_setup_dev_env_local_infra_dir="$the_setup_dev_env_local_dir/$the_setup_dev_env_infra_dir_name"
#
# local.env contains user-specific cloud settings (ex: AWS variables)
# this hides sensitive cloud tokens and information from src control
the_setup_dev_env_local_env_fname="local.env"
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
the_setup_dev_env_tmp_dir='/tmp'
the_setup_dev_env_tmp_fname_prefix='setup-dev-env-'
the_setup_dev_env_tmp_path_prefix="$the_setup_dev_env_tmp_dir/$the_setup_dev_env_tmp_fname_prefix"

##############################################################
# get user settings
echo 'USER SETTINGS...'
[ x"$SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS" = x1 ] && rm -fR "$the_setup_dev_env_local_dir"
mkdir -p "$the_setup_dev_env_local_dir"
if [ -s "$the_setup_dev_env_local_env_path" ] ; then
  # source it
  source "$the_setup_dev_env_local_env_path" 'source-only' || exit $?
else
  # create it
  echo "#/bin/bash" > "$the_setup_dev_env_local_env_path"
  echo "the_local_env_path_rc=0" >> "$the_setup_dev_env_local_env_path"
fi
#
# vars
if [ x"$AWS_PROFILE" = x ] ; then
  export AWS_PROFILE=sab-u-dev
  echo "[ x\"\$AWS_PROFILE\" = x ] && export AWS_PROFILE='$AWS_PROFILE'" >> "$the_setup_dev_env_local_env_path"
fi
if [ x"$AWS_SDK_LOAD_CONFIG" = x ] ; then
  export AWS_SDK_LOAD_CONFIG=1
  echo "[ x\"\$AWS_SDK_LOAD_CONFIG\" = x ] && export AWS_SDK_LOAD_CONFIG='$AWS_SDK_LOAD_CONFIG'" >> "$the_setup_dev_env_local_env_path"
fi
if [ x"$CF_LOCAL_DEV_ID" = x ] ; then
  the_default_value="$(whoami | sed -e 's/^l[\.\-]//')"
  read -p "  Enter value for CF_LOCAL_DEV_ID [$the_default_value]: " CF_LOCAL_DEV_ID
  CF_LOCAL_DEV_ID="${CF_LOCAL_DEV_ID:-$the_default_value}"
  echo "[ x\"\$CF_LOCAL_DEV_ID\" = x ] && export CF_LOCAL_DEV_ID='$CF_LOCAL_DEV_ID'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_DEV_ID
fi
echo "  CF_LOCAL_DEV_ID='$CF_LOCAL_DEV_ID'"
#
if [ x"$CF_LOCAL_USEREMAIL" = x ] ; then
  read -p "  Enter value for CF_LOCAL_USEREMAIL: " CF_LOCAL_USEREMAIL
  echo "[ x\"\$CF_LOCAL_USEREMAIL\" = x ] && export CF_LOCAL_USEREMAIL='$CF_LOCAL_USEREMAIL'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_USEREMAIL
fi
[ x"$CF_LOCAL_USEREMAIL" = x ] && echo 'Empty CF_LOCAL_USEREMAIL' && exit 1
echo "  CF_LOCAL_USEREMAIL='$CF_LOCAL_USEREMAIL'"
#
if [ x"$CF_LOCAL_AWS_PROFILE" = x ] ; then
  the_default_value='sab-u-dev'
  read -p "  Enter value for CF_LOCAL_AWS_PROFILE [$the_default_value]: " CF_LOCAL_AWS_PROFILE
  CF_LOCAL_AWS_PROFILE="${CF_LOCAL_AWS_PROFILE:-$the_default_value}"
  echo "[ x\"\$CF_LOCAL_AWS_PROFILE\" = x ] && export CF_LOCAL_AWS_PROFILE='$CF_LOCAL_AWS_PROFILE'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_AWS_PROFILE
fi
echo "  CF_LOCAL_AWS_PROFILE='$CF_LOCAL_AWS_PROFILE'"
#
if [ x"$CF_LOCAL_AWS_REGION" = x ] ; then
  the_default_value='us-east-2'
  read -p "  Enter value for CF_LOCAL_AWS_REGION [$the_default_value]: " CF_LOCAL_AWS_REGION
  CF_LOCAL_AWS_REGION="${CF_LOCAL_AWS_REGION:-$the_default_value}"
  echo "[ x\"\$CF_LOCAL_AWS_REGION\" = x ] && export CF_LOCAL_AWS_REGION='$CF_LOCAL_AWS_REGION'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_AWS_REGION
fi
echo "  CF_LOCAL_AWS_REGION='$CF_LOCAL_AWS_REGION'"
#
echo "[ \$the_local_env_path_rc -eq 0 ] && true || false" >> "$the_setup_dev_env_local_env_path"
#
echo '  OK'
echo ''

##############################################################
# hydrate samconfig.toml.in - special case that doesn't use
# scripts/sync-configs.sh because we must run a "fake" deploy
# to verify all variables.
#
# ensure aws login
echo 'CHECK AWS LOGIN...'
"$the_setup_dev_env_root_dir/scripts/aws-login.sh" || exit $?
echo ''
#
# setup vars and create directory
the_setup_dev_env_aws_src_dir="$the_setup_dev_env_infra_src_dir/aws"
the_setup_dev_env_aws_dst_dir="$the_setup_dev_env_local_infra_dir/aws"
the_setup_dev_env_sam_config_fname='samconfig.toml'
the_setup_dev_env_sam_config_src_path="$the_setup_dev_env_aws_src_dir/$the_setup_dev_env_sam_config_fname.in"
the_setup_dev_env_sam_config_dst_path="$the_setup_dev_env_aws_dst_dir/$the_setup_dev_env_sam_config_fname"
the_setup_dev_env_sam_config_wrk_path="$the_setup_dev_env_tmp_path_prefix$the_setup_dev_env_sam_config_fname"
mkdir -p "$the_setup_dev_env_aws_dst_dir"
#
# rebuild required?
the_setup_dev_env_sam_config_needs_rebuild=0
[ x"$SETUP_DEV_ENV_OPTION_RESET_SAM_CONFIG" = x1 ] && the_setup_dev_env_sam_config_needs_rebuild=1
if [ ! -s "$the_setup_dev_env_sam_config_dst_path" ] ; then
  the_setup_dev_env_sam_config_needs_rebuild=1
elif [[ "$the_setup_dev_env_sam_config_src_path" -nt "$the_setup_dev_env_sam_config_dst_path" ]] ; then
  the_setup_dev_env_sam_config_needs_rebuild=1
fi
[ $the_setup_dev_env_sam_config_needs_rebuild -eq 1 ] && rm -f "$the_setup_dev_env_sam_config_dst_path"
#
# rebuild the config file if necessary
echo 'CHECK AWS CONFIG...'
if [ -s "$the_setup_dev_env_sam_config_dst_path" ] ; then
  echo "  ALREADY_EXISTS: $the_setup_dev_env_sam_config_dst_path"
else
  echo "  CREATE: $the_setup_dev_env_sam_config_dst_path"
  set -x
  envsubst < "$the_setup_dev_env_sam_config_src_path" > "$the_setup_dev_env_sam_config_wrk_path" || exit $?
  set +x
  echo ''

  # initial setup creates a '.personal' section using defaults and non-interactive
  echo '  CREATE DEPLOYMENT...'
  set -x
  "$the_setup_dev_env_root_dir"/scripts/aws-run-cmd.sh sam deploy \
    --guided \
    --config-file "$the_setup_dev_env_sam_config_wrk_path" \
    --config-env dev \
    --no-execute-changeset \
    || exit $?
  set +x
  /bin/mv "$the_setup_dev_env_sam_config_wrk_path" "$the_setup_dev_env_sam_config_dst_path" || exit $?
fi
echo ''

##############################################################
# *now* we sync all configs except those processed explicitly
echo 'SYNC CONFIGS...'
the_setup_dev_env_tmp_sync_path="${the_setup_dev_env_tmp_path_prefix}tmp.txt"
"$the_setup_dev_env_root_dir/scripts/sync-configs.sh" >"$the_setup_dev_env_tmp_sync_path" 2>&1
the_rc=$?
cat "$the_setup_dev_env_tmp_sync_path" | sed -e 's/^\./  infra/'
rm -f "$the_setup_dev_env_tmp_sync_path"
[ $the_rc -ne 0 ] && exit $the_rc

# all good
true
 
