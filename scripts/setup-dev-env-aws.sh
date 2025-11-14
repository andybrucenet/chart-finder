#!/bin/bash
# setup-dev-env-aws.sh, ABr
#
# Initial env setup (driven from CF_LOCAL_BILLING_ENV) for chart-finder project - AWS backend.

##############################################################
# OPTIONS
SETUP_DEV_ENV_AWS_OPTION_RESET_USER_SETTINGS="${SETUP_DEV_ENV_AWS_OPTION_RESET_USER_SETTINGS:-0}"
SETUP_DEV_ENV_AWS_OPTION_RESET_SAM_CONFIG="${SETUP_DEV_ENV_AWS_OPTION_RESET_SAM_CONFIG:-0}"
#
# inferred values
if [ x"$SETUP_DEV_ENV_AWS_OPTION_RESET_USER_SETTINGS" = x1 ] ; then
  export SETUP_DEV_ENV_AWS_OPTION_RESET_SAM_CONFIG=1
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
the_setup_env_dev_aws_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_setup_env_dev_aws_root_dir="$( realpath "$the_setup_env_dev_aws_script_dir"/.. )"
source "$the_setup_env_dev_aws_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?
#
# infra contains all the raw input cloud configuration files
the_setup_env_dev_aws_infra_dir_name="infra"
the_setup_env_dev_aws_infra_src_dir="$the_setup_env_dev_aws_root_dir/$the_setup_env_dev_aws_infra_dir_name"
#
# .local contains all user-local files not checked into git
# this includes hydrated infra files
the_setup_env_dev_aws_local_dir="$the_setup_env_dev_aws_root_dir/$g_DOT_LOCAL_DIR_NAME"
the_setup_env_dev_aws_local_infra_dir="$the_setup_env_dev_aws_local_dir/$the_setup_env_dev_aws_infra_dir_name"
#
# local.env contains user-specific cloud settings (ex: AWS variables)
# this hides sensitive cloud tokens and information from src control
the_setup_env_dev_aws_local_env_fname="$g_DOT_LOCAL_SETTINGS_FNAME"
the_setup_env_dev_aws_local_env_path="$the_setup_env_dev_aws_local_dir/$the_setup_env_dev_aws_local_env_fname"

##############################################################
# required tools (aws-specific)
the_setup_dev_env_aws_tools_ok=1
the_setup_dev_env_aws_tools='aws sam'
for i in $the_setup_dev_env_aws_tools ; do
  ! which $i >/dev/null 2>&1 && echo "ERROR: MISSING_REQUIRED_TOOL (AWS) $i" && the_setup_dev_env_aws_tools_ok=0
done
[ $the_setup_dev_env_aws_tools_ok -ne 1 ] && exit 1

##############################################################
# tmp is problematic on cygwin
the_setup_env_dev_aws_tmp_dir="`lcl_os_tmp_dir`"
the_setup_env_dev_aws_tmp_fname_prefix='setup-dev-env-aws-'
the_setup_env_dev_aws_tmp_path_prefix="$the_setup_env_dev_aws_tmp_dir/$the_setup_env_dev_aws_tmp_fname_prefix"

##############################################################
# program start
echo '**AWS SETUP'
echo ''

##############################################################
# get user settings
echo 'AWS USER SETTINGS...'
if [ x"$SETUP_DEV_ENV_AWS_OPTION_RESET_USER_SETTINGS" = x1 ] ; then
  the_setup_env_dev_aws_var_names='AWS_PROFILE AWS_SDK_LOAD_CONFIG CF_LOCAL_AWS_PROFILE CF_LOCAL_AWS_REGION CF_LOCAL_AWS_ARTIFACT_BUCKET'
  for i in $the_setup_env_dev_aws_var_names ; do
    lcl_dot_local_settings_delete "$the_setup_env_dev_aws_root_dir" $i || exit $?
    unset $i
  done
fi
#
# source after performing all updates
lcl_dot_local_settings_source "$the_setup_env_dev_aws_root_dir"
#
# vars
#
if [ x"$CF_LOCAL_AWS_PROFILE" = x ] ; then
  the_default_value="$CF_LOCAL_DEV_ID-$CF_LOCAL_PRJ_ID-$CF_LOCAL_BILLING_ENV"
  read -p "  Enter value for CF_LOCAL_AWS_PROFILE [$the_default_value]: " CF_LOCAL_AWS_PROFILE
  CF_LOCAL_AWS_PROFILE="${CF_LOCAL_AWS_PROFILE:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_AWS_PROFILE "$CF_LOCAL_AWS_PROFILE" || exit $?
  export CF_LOCAL_AWS_PROFILE
fi
echo "  CF_LOCAL_AWS_PROFILE='$CF_LOCAL_AWS_PROFILE'"
#
if [ x"$CF_LOCAL_AWS_REGION" = x ] ; then
  the_default_value='us-east-2'
  read -p "  Enter value for CF_LOCAL_AWS_REGION [$the_default_value]: " CF_LOCAL_AWS_REGION
  CF_LOCAL_AWS_REGION="${CF_LOCAL_AWS_REGION:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_AWS_REGION "$CF_LOCAL_AWS_REGION" || exit $?
  export CF_LOCAL_AWS_REGION
fi
echo "  CF_LOCAL_AWS_REGION='$CF_LOCAL_AWS_REGION'"
#
if [ x"$CF_LOCAL_AWS_ARTIFACT_BUCKET" = x ] ; then
  the_default_value="$CF_LOCAL_ENV_ID-s3-artifacts"
  read -p "  Enter value for CF_LOCAL_AWS_ARTIFACT_BUCKET [$the_default_value]: " CF_LOCAL_AWS_ARTIFACT_BUCKET
  CF_LOCAL_AWS_ARTIFACT_BUCKET="${CF_LOCAL_AWS_ARTIFACT_BUCKET:-$the_default_value}"
  lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_AWS_ARTIFACT_BUCKET "$CF_LOCAL_AWS_ARTIFACT_BUCKET" || exit $?
  export CF_LOCAL_AWS_ARTIFACT_BUCKET
fi
echo "  CF_LOCAL_AWS_ARTIFACT_BUCKET='$CF_LOCAL_AWS_ARTIFACT_BUCKET'"
#
# ensure TLS certificate ARN (used by custom domains) exists
setup_dev_env_aws_ensure_tls_certificate() {
  local cert_path="${CF_LOCAL_TLS_CERT_PATH:-}"
  local chain_path="${CF_LOCAL_TLS_CHAIN_PATH:-}"
  local key_path="${CF_LOCAL_TLS_KEY_PATH:-}"

  if [ x"$cert_path" = x ] || [ x"$key_path" = x ] || [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
    echo "  WARN: TLS certificate or key not found; skipping ACM import for setup."
    return 0
  fi

  local state_dir="$the_setup_env_dev_aws_root_dir/.local/state"
  local state_file="$state_dir/tls-cert.state"
  mkdir -p "$state_dir"

  local cert_hash
  if [ -f "$chain_path" ]; then
    cert_hash="$(cat "$cert_path" "$chain_path" "$key_path" | shasum -a 256 | awk '{print $1}')"
  else
    cert_hash="$(cat "$cert_path" "$key_path" | shasum -a 256 | awk '{print $1}')"
  fi

  local stored_hash=''
  local stored_arn=''
  if [ -f "$state_file" ]; then
    stored_hash="$(grep '^HASH=' "$state_file" | head -1 | cut -d= -f2-)"
    stored_arn="$(grep '^ARN=' "$state_file" | head -1 | cut -d= -f2-)"
  fi

  if [ x"$stored_hash" = x"$cert_hash" ] && [ -n "$stored_arn" ]; then
    export CF_LOCAL_TLS_CERT_ARN="$stored_arn"
    lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_TLS_CERT_ARN "$CF_LOCAL_TLS_CERT_ARN" >/dev/null 2>&1 || true
    echo "  Existing ACM certificate ARN found: $CF_LOCAL_TLS_CERT_ARN"
    return 0
  fi

  local region="${CF_LOCAL_AWS_REGION:-us-east-2}"
  local import_args=(
    aws acm import-certificate
    --region "$region"
    --certificate "fileb://$cert_path"
    --private-key "fileb://$key_path"
    --certificate-chain "fileb://${chain_path:-$cert_path}"
    --output text
    --query CertificateArn
  )

  if [ -n "$stored_arn" ]; then
    import_args+=(--certificate-arn "$stored_arn")
  fi

  echo "  Import TLS certificate into ACM..."
  echo "    aws ${import_args[*]}"
  local import_output
  import_output="$("$the_setup_env_dev_aws_root_dir/scripts/aws-run-cmd.sh" "${import_args[@]}")"
  local import_rc=$?
  local certificate_arn
  certificate_arn="$(printf '%s\n' "$import_output" | tail -n1 | tr -d '[:space:]')"

  if [ $import_rc -ne 0 ] || [ -z "$certificate_arn" ]; then
    echo 'ERROR: ACM certificate import failed during setup.' >&2
    return ${import_rc:-1}
  fi

  {
    echo "HASH=$cert_hash"
    echo "ARN=$certificate_arn"
  } > "$state_file"

  export CF_LOCAL_TLS_CERT_ARN="$certificate_arn"
  lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_TLS_CERT_ARN "$CF_LOCAL_TLS_CERT_ARN" >/dev/null 2>&1 || true
  echo "  ACM certificate ARN: $CF_LOCAL_TLS_CERT_ARN"
}

setup_dev_env_aws_ensure_tls_certificate || exit $?
#
# always update CF_LOCAL_AWS_SSO_ROLE as it is driven through login - but we need it for hydration
CF_LOCAL_AWS_SSO_ROLE="`"$the_setup_env_dev_aws_root_dir"/scripts/aws-run-cmd.sh \
  aws sts get-caller-identity --output json --no-cli-pager \
  | jq -r '.Arn' \
  | awk -F':' '{print $6}' | awk -F'/' '{print $2}' \
  | xargs | dos2unix`"
lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_AWS_SSO_ROLE "$CF_LOCAL_AWS_SSO_ROLE" || exit $?
export CF_LOCAL_AWS_SSO_ROLE
echo "  CF_LOCAL_AWS_SSO_ROLE='$CF_LOCAL_AWS_SSO_ROLE'"
#
# always check AWS_PROFILE in the local.env file for a match to CF_LOCAL_AWS_PROFILE
the_actual_value="`lcl_dot_local_settings_get "$the_setup_env_dev_aws_root_dir" AWS_PROFILE '' '0'`"
wants_new_value=0 ; [ x"$the_actual_value" = x ] && wants_new_value=1
if [ $wants_new_value -eq 0 ] ; then
  if [ x"$the_actual_value" != x"$CF_LOCAL_AWS_PROFILE" ] ; then
    echo "  Warning: AWS_PROFILE ($the_actual_value) differs from CF_LOCAL_AWS_PROFILE ($CF_LOCAL_AWS_PROFILE)"
    read -p "  Update to have them match [y/N]: " the_enter_response
    [ x"$the_enter_response" = x ] && the_enter_response="n"
    if echo "$the_enter_response" | grep -ie '^[y]' >/dev/null 2>&1 ; then
      wants_new_value=1
    fi
  fi
fi
if [ $wants_new_value -eq 1 ] ; then
  export AWS_PROFILE="$CF_LOCAL_AWS_PROFILE"
  lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" AWS_PROFILE "$AWS_PROFILE" || exit $?
fi
if [ x"$AWS_SDK_LOAD_CONFIG" = x ] ; then
  export AWS_SDK_LOAD_CONFIG=1
  lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" AWS_SDK_LOAD_CONFIG "$AWS_SDK_LOAD_CONFIG" || exit $?
fi
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
"$the_setup_env_dev_aws_root_dir/scripts/aws-login.sh" || exit $?
echo ''
#
# get the region
CF_LOCAL_AWS_ACCOUNT_ID="`"$the_setup_env_dev_aws_root_dir/scripts/aws-run-cmd.sh" aws sts get-caller-identity --output json --no-cli-pager | jq -r '.Account' | dos2unix`"
lcl_dot_local_settings_update "$the_setup_env_dev_aws_root_dir" CF_LOCAL_AWS_ACCOUNT_ID "$CF_LOCAL_AWS_ACCOUNT_ID" || exit $?
export CF_LOCAL_AWS_ACCOUNT_ID
echo "CF_LOCAL_AWS_ACCOUNT_ID='$CF_LOCAL_AWS_ACCOUNT_ID'"
echo ''

#
# setup vars and create directory
the_setup_env_dev_aws_aws_src_dir="$the_setup_env_dev_aws_infra_src_dir/aws"
the_setup_env_dev_aws_aws_dst_dir="$the_setup_env_dev_aws_local_infra_dir/aws"
the_setup_env_dev_aws_sam_config_fname='samconfig.toml'
the_setup_env_dev_aws_sam_config_src_path="$the_setup_env_dev_aws_aws_src_dir/$the_setup_env_dev_aws_sam_config_fname.in"
the_setup_env_dev_aws_sam_config_dst_path="$the_setup_env_dev_aws_aws_dst_dir/$the_setup_env_dev_aws_sam_config_fname"
the_setup_env_dev_aws_sam_config_wrk_path="$the_setup_env_dev_aws_tmp_path_prefix$the_setup_env_dev_aws_sam_config_fname"
mkdir -p "$the_setup_env_dev_aws_aws_dst_dir"
#
# rebuild required?
the_setup_env_dev_aws_sam_config_needs_rebuild=0
[ x"$SETUP_DEV_ENV_AWS_OPTION_RESET_SAM_CONFIG" = x1 ] && the_setup_env_dev_aws_sam_config_needs_rebuild=1
if [ ! -s "$the_setup_env_dev_aws_sam_config_dst_path" ] ; then
  the_setup_env_dev_aws_sam_config_needs_rebuild=1
elif [[ "$the_setup_env_dev_aws_sam_config_src_path" -nt "$the_setup_env_dev_aws_sam_config_dst_path" ]] ; then
  the_setup_env_dev_aws_sam_config_needs_rebuild=1
fi
[ $the_setup_env_dev_aws_sam_config_needs_rebuild -eq 1 ] && rm -f "$the_setup_env_dev_aws_sam_config_dst_path"
#
# rebuild the config file if necessary
echo 'CHECK AWS CONFIG...'
if [ -s "$the_setup_env_dev_aws_sam_config_dst_path" ] ; then
  echo "  ALREADY_EXISTS: $the_setup_env_dev_aws_sam_config_dst_path"
else
  # initial config sync so the guided setup will work
  echo '  INITIAL SYNC CONFIGS...'
  the_setup_env_dev_aws_tmp_sync_path="${the_setup_env_dev_aws_tmp_path_prefix}tmp.txt"
  "$the_setup_env_dev_aws_root_dir/scripts/sync-configs.sh" >"$the_setup_env_dev_aws_tmp_sync_path" 2>&1
  the_rc=$? ; [ $the_rc -eq 99 ] && the_rc=0
  [ $the_rc -ne 0 ] && cat "$the_setup_env_dev_aws_tmp_sync_path" | sed -e 's/^\./  infra/'
  rm -f "$the_setup_env_dev_aws_tmp_sync_path"
  [ $the_rc -ne 0 ] && exit $the_rc
  echo ''

  echo "  CREATE: $the_setup_env_dev_aws_sam_config_dst_path"
  set -x
  DOLLAR='$' envsubst < "$the_setup_env_dev_aws_sam_config_src_path" > "$the_setup_env_dev_aws_sam_config_wrk_path" || exit $?
  set +x
  echo ''

  # initial setup creates a '.personal' section using defaults and non-interactive
  echo '  CREATE DEPLOYMENT...'
  set -x
  "$the_setup_env_dev_aws_root_dir"/scripts/aws-run-cmd.sh sam deploy \
    --guided \
    --config-file "$the_setup_env_dev_aws_sam_config_wrk_path" \
    --config-env "$CF_LOCAL_BILLING_ENV" \
    --no-execute-changeset \
    || exit $?
  set +x
  /bin/mv "$the_setup_env_dev_aws_sam_config_wrk_path" "$the_setup_env_dev_aws_sam_config_dst_path" || exit $?

  # post-process deployment
  "$the_setup_env_dev_aws_script_dir/setup-dev-env-aws-post-process.sh" || exit $?
fi
echo ''

##############################################################
# *now* we sync all configs except those processed explicitly
echo 'SYNC CONFIGS...'
the_setup_env_dev_aws_tmp_sync_path="${the_setup_env_dev_aws_tmp_path_prefix}tmp.txt"
"$the_setup_env_dev_aws_root_dir/scripts/sync-configs.sh" >"$the_setup_env_dev_aws_tmp_sync_path" 2>&1
the_rc=$?
cat "$the_setup_env_dev_aws_tmp_sync_path" | sed -e 's/^\./  infra/'
rm -f "$the_setup_env_dev_aws_tmp_sync_path"
[ $the_rc -ne 0 ] && exit $the_rc

# all good
true
 
