#!/bin/bash
# admin-setup-dev-env.sh, ABr
#
# Admin script to run against a provided ".local" folder

##############################################################
# the single argument is optional folder to .local
#
# permit to be sent from environment rather than command line
ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR_FROM_ENV="${ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR:-}"
#
# but also permit command line (overrides environment)
ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR="$1" ; shift
#
# set to env value if command line empty
[ x"$ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR" = x ] && ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR="$ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR_FROM_ENV"

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
the_admin_setup_dev_env_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_admin_setup_dev_env_root_dir="$( realpath "$the_admin_setup_dev_env_script_dir"/../.. )"
source "$the_admin_setup_dev_env_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?

##############################################################
# tmp is problematic on cygwin
the_admin_setup_dev_env_tmp_dir="`lcl_os_tmp_dir`"
the_admin_setup_dev_env_tmp_fname_prefix='admin-setup-dev-env-'
the_admin_setup_dev_env_tmp_path_prefix="$the_admin_setup_dev_env_tmp_dir/$the_admin_setup_dev_env_tmp_fname_prefix"

##############################################################
# program start

echo '**ONE TIME ADMIN SETUP...'
echo ''

# if no .local folder passed - default to ours
[ x"$ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR" = x ] && ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR="$the_admin_setup_dev_env_root_dir/.local"
#
# must exist
[ ! -d "$ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR" ] && echo "ERROR: INVALID_DIR:'$ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR'" && exit 1

# TODO: as multiple clouds get added we must add more specific scripts
"$the_admin_setup_dev_env_script_dir"/admin-setup-dev-env-aws.sh "$ADMIN_SETUP_DEV_ENV_OPTION_LOCAL_DIR"

