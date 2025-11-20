#!/bin/bash
# aws-sam-deploy.sh ABr
#
# Deploy the SAM stack for the current environment. Cleans up failed stacks and
# then invokes sam deploy. Defaults to config-env "$CF_LOCAL_BILLING_ENV" but accepts an override
# (AWS_SAM_DEPLOY_OPTION_CONFIG_ENV or second CLI argument).

AWS_SAM_DEPLOY_OPTION_MODE="${AWS_SAM_DEPLOY_OPTION_MODE:-build}"
AWS_SAM_DEPLOY_OPTION_CONFIG_ENV="${AWS_SAM_DEPLOY_OPTION_CONFIG_ENV:-}"

the_aws_sam_deploy_mode="${1:-$AWS_SAM_DEPLOY_OPTION_MODE}"
the_aws_sam_deploy_config_env="${2:-$AWS_SAM_DEPLOY_OPTION_CONFIG_ENV}"

# locate script source directory
the_aws_sam_deploy_source="${BASH_SOURCE[0]}"
while [ -h "$the_aws_sam_deploy_source" ]; do
  the_aws_sam_deploy_dir="$( cd -P "$( dirname "$the_aws_sam_deploy_source" )" >/dev/null 2>&1 && pwd )"
  the_aws_sam_deploy_source="$(readlink "$the_aws_sam_deploy_source")"
  [[ $the_aws_sam_deploy_source != /* ]] && the_aws_sam_deploy_source="$the_aws_sam_deploy_dir/$the_aws_sam_deploy_source"
done
the_aws_sam_deploy_script_dir="$( cd -P "$( dirname "$the_aws_sam_deploy_source" )" >/dev/null 2>&1 && pwd )"
the_aws_sam_deploy_root_dir="$( realpath "$the_aws_sam_deploy_script_dir"/.. )"
source "$the_aws_sam_deploy_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_aws_sam_deploy_root_dir" || exit $?
#
# also source in all the local build version settings - we need them for 'sam deploy'
source "$the_aws_sam_deploy_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

aws_sam_deploy_ensure_tls_certificate() {
  local cert_path="${CF_LOCAL_TLS_CERT_PATH:-}"
  local chain_path="${CF_LOCAL_TLS_CHAIN_PATH:-}"
  local key_path="${CF_LOCAL_TLS_KEY_PATH:-}"

  if [ x"$cert_path" = x ] || [ x"$key_path" = x ] || [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
    echo "WARN: TLS certificate or key not found; skipping ACM import." >&2
    return 0
  fi

  # ensure certificate is not expiring within 14 days
  local cert_not_after_output=''
  cert_not_after_output="$(python3 - "$cert_path" <<'PY'
import sys
from datetime import datetime, timezone
import ssl
from pathlib import Path

cert_path = Path(sys.argv[1])
if not cert_path.is_file():
    sys.exit("CERT_MISSING")
try:
    cert_info = ssl._ssl._test_decode_cert(str(cert_path))
except Exception as exc:
    sys.exit(f"CERT_PARSE_ERROR: {exc}")
not_after_raw = cert_info.get("notAfter")
if not not_after_raw:
    sys.exit("CERT_NO_NOT_AFTER")
dt = datetime.strptime(not_after_raw, "%b %d %H:%M:%S %Y %Z")
dt = dt.replace(tzinfo=timezone.utc)
print(int(dt.timestamp()))
print(dt.isoformat())
PY
)"
  local python_rc=$?
  local cert_not_after_epoch=''
  local cert_not_after_iso=''
  if [ $python_rc -ne 0 ] || [ -z "$cert_not_after_output" ]; then
    echo "ERROR: unable to determine TLS certificate expiration for '$cert_path'." >&2
    return 1
  fi
  cert_not_after_epoch="$(printf '%s\n' "$cert_not_after_output" | sed -n '1p')"
  cert_not_after_iso="$(printf '%s\n' "$cert_not_after_output" | sed -n '2p')"
  local now_epoch="$(date -u +%s)"
  local fourteen_days=$((14 * 24 * 60 * 60))
  local seconds_until_expiry=$((cert_not_after_epoch - now_epoch))
  local two_days=$((2 * 24 * 60 * 60))
  local three_days=$((3 * 24 * 60 * 60))
  local seven_days=$((7 * 24 * 60 * 60))
  local fourteen_days=$((14 * 24 * 60 * 60))

  if [ $seconds_until_expiry -le $two_days ]; then
    echo "ERROR: TLS certificate '$cert_path' expires in less than 48 hours ($cert_not_after_iso); renew before deploying." >&2
    return 1
  elif [ $seconds_until_expiry -le $seven_days ]; then
    echo "WARNING: TLS certificate '$cert_path' expires within 7 days ($cert_not_after_iso)." >&2
    read -r -p "Proceed with deploy? [y/N]: " l_confirm
    if [[ ! "$l_confirm" =~ ^[Yy]$ ]]; then
      echo "Deploy aborted due to pending TLS certificate expiration." >&2
      return 1
    fi
  elif [ $seconds_until_expiry -le $fourteen_days ]; then
    echo "WARNING: TLS certificate '$cert_path' expires within 14 days ($cert_not_after_iso)." >&2
    echo "Please schedule a renewal soon."
  fi

  local state_dir="$the_aws_sam_deploy_root_dir/$g_DOT_LOCAL_DIR_NAME/state"
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

  echo 'Importing TLS certificate into ACM...'
  echo "  aws ${import_args[*]}"
  local import_output
  import_output="$("$the_aws_sam_deploy_root_dir/scripts/cf-run-cmd.sh" "${import_args[@]}")"
  local import_rc=$?
  local certificate_arn
  certificate_arn="$(printf '%s\n' "$import_output" | tail -n1 | tr -d '[:space:]')"

  if [ $import_rc -ne 0 ] || [ -z "$certificate_arn" ]; then
    echo 'ERROR: ACM certificate import failed.' >&2
    return ${import_rc:-1}
  fi

  {
    echo "HASH=$cert_hash"
    echo "ARN=$certificate_arn"
  } > "$state_file"

  export CF_LOCAL_TLS_CERT_ARN="$certificate_arn"
  lcl_dot_local_settings_update "$the_aws_sam_deploy_root_dir" CF_LOCAL_TLS_CERT_ARN "$CF_LOCAL_TLS_CERT_ARN" >/dev/null 2>&1 || true
  echo "  ACM certificate ARN: $CF_LOCAL_TLS_CERT_ARN"
}

# run in top-level folder
cd "$the_aws_sam_deploy_root_dir" || exit $?

# get the local.env config env if not overridden or set on command line
the_aws_sam_deploy_config_env="${the_aws_sam_deploy_config_env:-$CF_LOCAL_BILLING_ENV}"

the_aws_sam_deploy_stack_info="$("$the_aws_sam_deploy_root_dir/scripts/aws-sam-stack-state.sh")"
the_aws_sam_deploy_rc=$?
if [ $the_aws_sam_deploy_rc -ne 0 ]; then
  echo "ERROR: failed to retrieve stack state" >&2
  exit $the_aws_sam_deploy_rc
fi

the_aws_sam_deploy_stack_status="$(printf '%s' "$the_aws_sam_deploy_stack_info" | jq -r '.StackStatus // empty')"

the_aws_sam_deploy_mode="$(printf '%s' "$the_aws_sam_deploy_mode" | tr '[:upper:]' '[:lower:]')"

if [ "$the_aws_sam_deploy_mode" = "status" ]; then
  printf '%s\n' "$the_aws_sam_deploy_stack_info"
  exit 0
fi

if [ "$the_aws_sam_deploy_mode" = "uri" ]; then
  # get the URL
  "$the_aws_sam_deploy_root_dir/scripts/cf-run-cmd.sh" aws cloudformation describe-stacks \
    --stack-name "$CF_LOCAL_ENV_ID" \
    --query "Stacks[0].Outputs" \
    --no-cli-pager \
    | jq -r '.[] | select(.OutputKey=="ApiInvokeUrl").OutputValue'
  exit 0
fi

if [ -z "$the_aws_sam_deploy_stack_status" ]; then
  echo "Stack $CF_LOCAL_ENV_ID not found."
elif [ "$the_aws_sam_deploy_mode" = "clean" ] || [ "$the_aws_sam_deploy_mode" = "rebuild" ] \
  || [ "$the_aws_sam_deploy_stack_status" = "ROLLBACK_COMPLETE" ] \
  || [ "$the_aws_sam_deploy_stack_status" = "ROLLBACK_FAILED" ]; then
  echo "Deleting stack $CF_LOCAL_ENV_ID (status: ${the_aws_sam_deploy_stack_status:-unknown})..."
  "$the_aws_sam_deploy_root_dir/scripts/cf-run-cmd.sh" aws cloudformation delete-stack \
    --stack-name "$CF_LOCAL_ENV_ID" \
    --no-cli-pager
  the_aws_sam_deploy_delete_rc=$?
  if [ $the_aws_sam_deploy_delete_rc -ne 0 ]; then
    echo "ERROR: stack delete failed rc=$the_aws_sam_deploy_delete_rc" >&2
    exit $the_aws_sam_deploy_delete_rc
  fi
  echo "Waiting for stack delete to complete..."
  "$the_aws_sam_deploy_root_dir/scripts/cf-run-cmd.sh" aws cloudformation wait stack-delete-complete \
    --stack-name "$CF_LOCAL_ENV_ID" \
    --no-cli-pager
  the_aws_sam_deploy_wait_rc=$?
  if [ $the_aws_sam_deploy_wait_rc -ne 0 ]; then
    echo "ERROR: stack delete wait failed rc=$the_aws_sam_deploy_wait_rc" >&2
    exit $the_aws_sam_deploy_wait_rc
  fi
else
  echo "Existing stack status: $the_aws_sam_deploy_stack_status"
fi

if [ "$the_aws_sam_deploy_mode" = "clean" ]; then
  echo "CLEAN mode complete; deploy skipped."
  exit 0
fi

if [ "$the_aws_sam_deploy_mode" = "build" ] || [ "$the_aws_sam_deploy_mode" = "rebuild" ]; then
  aws_sam_deploy_ensure_tls_certificate || exit $?
  "$the_aws_sam_deploy_root_dir/scripts/sync-configs.sh"
fi

echo "Running SAM deploy (config-env: $the_aws_sam_deploy_config_env)..."
#
# hydrate again
the_aws_sam_deploy_tmp_prefix="`lcl_os_tmp_dir`/aws-sam-deploy-$$-"
the_aws_sam_deploy_tmp_samconfig_toml="${the_aws_sam_deploy_tmp_prefix}samconfig.toml"
the_aws_sam_deploy_root_dir="$( realpath "$the_aws_sam_deploy_script_dir"/.. )"
DOLLAR='$' envsubst < "$the_aws_sam_deploy_root_dir/$g_DOT_LOCAL_DIR_NAME/infra/aws/samconfig.toml" >"$the_aws_sam_deploy_tmp_samconfig_toml" || exit $?
set -x
"$the_aws_sam_deploy_root_dir/scripts/cf-run-cmd.sh" sam deploy \
  --config-file "$the_aws_sam_deploy_tmp_samconfig_toml" \
  --config-env "$the_aws_sam_deploy_config_env"
the_aws_sam_deploy_deploy_rc=$?
rm -f "$the_aws_sam_deploy_tmp_samconfig_toml"
set +x

if [ $the_aws_sam_deploy_deploy_rc -ne 0 ]; then
  echo "ERROR: sam deploy failed rc=$the_aws_sam_deploy_deploy_rc" >&2
  exit $the_aws_sam_deploy_deploy_rc
fi

echo "SAM deploy complete."
