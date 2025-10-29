#!/bin/bash
# setup-dev-env.sh, ABr
#
# Initial dev setup for chart-finder project.

##############################################################
# OPTIONS
SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS="${SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS:-0}"

# locate script source directory
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

# required tools
the_setup_dev_env_tools_ok=1
the_setup_dev_env_tools='which sam aws jq'
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
the_setup_dev_env_local_dir="$the_setup_dev_env_root_dir/.local"
the_setup_dev_env_local_env_path="$the_setup_dev_env_local_dir/local.env"
echo 'USER SETTINGS...'
[ x"$SETUP_DEV_ENV_OPTION_RESET_USER_SETTINGS" = x1 ] && rm -fR "$the_setup_dev_env_local_dir"
mkdir -p "$the_setup_dev_env_local_dir"
if [ -s "$the_setup_dev_env_local_env_path" ] ; then
  # source it
  source "$the_setup_dev_env_local_env_path" 'source-only' || exit $?
else
  # create it
  echo "#/bin/bash" > "$the_setup_dev_env_local_env_path"
fi
#
# vars
if [ x"$CF_LOCAL_DEV_ID" = x ] ; then
  the_default_value="$(whoami | sed -e 's/^l[\.\-]//')"
  read -p "  Enter value for CF_LOCAL_DEV_ID [$the_default_value]: " CF_LOCAL_DEV_ID
  CF_LOCAL_DEV_ID="${CF_LOCAL_DEV_ID:-$the_default_value}"
  echo "export CF_LOCAL_DEV_ID='$CF_LOCAL_DEV_ID'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_DEV_ID
fi
echo "  CF_LOCAL_DEV_ID='$CF_LOCAL_DEV_ID'"
#
if [ x"$CF_LOCAL_USEREMAIL" = x ] ; then
  read -p "  Enter value for CF_LOCAL_USEREMAIL: " CF_LOCAL_USEREMAIL
  echo "export CF_LOCAL_USEREMAIL='$CF_LOCAL_USEREMAIL'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_USEREMAIL
fi
[ x"$CF_LOCAL_USEREMAIL" = x ] && echo 'Empty CF_LOCAL_USEREMAIL' && exit 1
echo "  CF_LOCAL_USEREMAIL='$CF_LOCAL_USEREMAIL'"
#
if [ x"$CF_LOCAL_AWS_PROFILE" = x ] ; then
  the_default_value='sab-u-dev'
  read -p "  Enter value for CF_LOCAL_AWS_PROFILE [$the_default_value]: " CF_LOCAL_AWS_PROFILE
  CF_LOCAL_AWS_PROFILE="${CF_LOCAL_AWS_PROFILE:-$the_default_value}"
  echo "export CF_LOCAL_AWS_PROFILE='$CF_LOCAL_AWS_PROFILE'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_AWS_PROFILE
fi
echo "  CF_LOCAL_AWS_PROFILE='$CF_LOCAL_AWS_PROFILE'"
#
if [ x"$CF_LOCAL_AWS_REGION" = x ] ; then
  the_default_value='us-east-2'
  read -p "  Enter value for CF_LOCAL_AWS_REGION [$the_default_value]: " CF_LOCAL_AWS_REGION
  CF_LOCAL_AWS_REGION="${CF_LOCAL_AWS_REGION:-$the_default_value}"
  echo "export CF_LOCAL_AWS_REGION='$CF_LOCAL_AWS_REGION'" >> "$the_setup_dev_env_local_env_path"
  export CF_LOCAL_AWS_REGION
fi
echo "  CF_LOCAL_AWS_REGION='$CF_LOCAL_AWS_REGION'"
#
echo '  OK'
echo ''

##############################################################
# samconfig.toml - ensure that local is created
the_setup_dev_env_sam_config_dir="$the_setup_dev_env_root_dir/infra/aws"
the_setup_dev_env_sam_config_base_fname='samconfig.toml'
the_setup_dev_env_sam_config_local_fname='samconfig.local.toml'
the_setup_dev_env_sam_config_base_path="$the_setup_dev_env_sam_config_dir/$the_setup_dev_env_sam_config_base_fname"
the_setup_dev_env_sam_config_local_path="$the_setup_dev_env_sam_config_dir/$the_setup_dev_env_sam_config_local_fname"
the_setup_dev_env_sam_config_work_path="${the_setup_dev_env_tmp_path_prefix}$the_setup_dev_env_sam_config_local_fname"
if [ -s "$the_setup_dev_env_sam_config_local_path" ] ; then
  echo "ALREADY_EXISTS: $the_setup_dev_env_sam_config_local_fname"
else
  echo "CREATE: $the_setup_dev_env_sam_config_local_fname"
  set -x
  /bin/cp "$the_setup_dev_env_sam_config_base_path" "$the_setup_dev_env_sam_config_work_path" || exit $?
  set +x
  echo ''

  echo "HYDRATE: $the_setup_dev_env_sam_config_local_fname"
  for i in CF_LOCAL_DEV_ID CF_LOCAL_USEREMAIL CF_LOCAL_AWS_PROFILE CF_LOCAL_AWS_REGION ; do
    the_env_var_value="${!i}"
    sed -i -e 's/'"$i"'/'"$the_env_var_value"'/g' "$the_setup_dev_env_sam_config_work_path"
  done
  echo ''

  # initial setup creates a '.personal' section using defaults and non-interactive
  echo 'CREATE DEPLOYMENT...'
  set -x
  sam deploy \
    --guided \
    --config-file "$the_setup_dev_env_sam_config_work_path" \
    --config-env dev \
    --no-execute-changeset \
    || exit $?
  set +x
  /bin/mv "$the_setup_dev_env_sam_config_work_path" "$the_setup_dev_env_sam_config_local_path" || exit $?
fi
 
