#!/bin/bash
# tls-renew.sh
# Renew the Chart Finder wildcard certificate via Certbot and re-import it into ACM.

the_tls_renew_source="${BASH_SOURCE[0]}"
while [ -h "$the_tls_renew_source" ]; do
  the_tls_renew_dir="$( cd -P "$( dirname "$the_tls_renew_source" )" >/dev/null 2>&1 && pwd )"
  the_tls_renew_source="$(readlink "$the_tls_renew_source")"
  [[ $the_tls_renew_source != /* ]] && the_tls_renew_source="$the_tls_renew_dir/$the_tls_renew_source"
done
the_tls_renew_script_dir="$( cd -P "$( dirname "$the_tls_renew_source" )" >/dev/null 2>&1 && pwd )"
the_tls_renew_root_dir="$( realpath "$the_tls_renew_script_dir"/.. )"

source "$the_tls_renew_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_tls_renew_root_dir" || exit $?

the_tls_renew_certbot_bin="${TLS_RENEW_OPTION_CERTBOT_BIN:-/opt/homebrew/bin/certbot}"
the_tls_renew_aws_bin="${TLS_RENEW_OPTION_AWS_BIN:-/opt/homebrew/bin/aws}"
the_tls_renew_dns_creds="${TLS_RENEW_OPTION_DNS_CREDS:-${HOME}/.cloudflare-api-token.ini}"
the_tls_renew_cert_root="${TLS_RENEW_OPTION_CERT_ROOT:-${HOME}/Documents/Personal/andy/certs/ssl/chart-finder}"
the_tls_renew_domain="${TLS_RENEW_OPTION_DOMAIN:-chart-finder.app}"
the_tls_renew_stack_name="${TLS_RENEW_OPTION_STACK:-${CF_LOCAL_ENV_ID:-cf-sab-u-dev}}"
the_tls_renew_region="${TLS_RENEW_OPTION_REGION:-${CF_LOCAL_AWS_REGION:-us-east-2}}"

tls_renew_log() {
  local i_message="$1"
  printf '[tls-renew] %s\n' "$i_message"
}

tls_renew_usage() {
  cat <<'USAGE'
Usage: ./scripts/tls-renew.sh [command]

Commands:
  run        Renew cert via certbot and re-import into ACM (default)
  help       Show this help text

Environment overrides:
  TLS_RENEW_OPTION_CERTBOT_BIN   Path to certbot (default /opt/homebrew/bin/certbot)
  TLS_RENEW_OPTION_AWS_BIN       Path to aws CLI (default /opt/homebrew/bin/aws)
  TLS_RENEW_OPTION_DNS_CREDS     DNS credentials file (default ~/.cloudflare-api-token.ini)
  TLS_RENEW_OPTION_CERT_ROOT     Base directory for certbot data
  TLS_RENEW_OPTION_DOMAIN        Domain to renew (default chart-finder.app)
  TLS_RENEW_OPTION_STACK         Stack used to locate ACM ARN (default CF_LOCAL_ENV_ID)
  TLS_RENEW_OPTION_REGION        AWS region (default CF_LOCAL_AWS_REGION)
USAGE
}

tls_renew_require_file() {
  local i_path="$1"
  if [ ! -f "$i_path" ]; then
    tls_renew_log "ERROR: Missing file: $i_path"
    return 1
  fi
}

tls_renew_check_binary() {
  local i_binary="$1"
  if ! command -v "$i_binary" >/dev/null 2>&1; then
    tls_renew_log "ERROR: Required binary not found: $i_binary"
    return 1
  fi
}

tls_renew_find_cert_arn() {
  local l_output
  l_output="$("$the_tls_renew_root_dir/scripts/cf-run-cmd.sh" aws cloudformation describe-stacks \
    --region "$the_tls_renew_region" \
    --stack-name "$the_tls_renew_stack_name" \
    --query "Stacks[0].Outputs[?OutputKey=='ApiCertificateArn'].OutputValue" \
    --output text 2>/dev/null)"
  if [ -z "$l_output" ] || [ "$l_output" = "None" ]; then
    return 1
  fi
  printf '%s\n' "$l_output"
}

tls_renew_run() {
  tls_renew_check_binary "$the_tls_renew_certbot_bin" || return 1
  tls_renew_check_binary "$the_tls_renew_aws_bin" || return 1
  tls_renew_require_file "$the_tls_renew_dns_creds" || return 1

  local l_config_dir="$the_tls_renew_cert_root/config"
  local l_work_dir="$the_tls_renew_cert_root/work"
  local l_logs_dir="$the_tls_renew_cert_root/logs"

  tls_renew_log "Renewing certificate for $the_tls_renew_domain"
  "$the_tls_renew_certbot_bin" renew \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$the_tls_renew_dns_creds" \
    --config-dir "$l_config_dir" \
    --work-dir "$l_work_dir" \
    --logs-dir "$l_logs_dir"
  local l_certbot_rc=$?
  if [ $l_certbot_rc -ne 0 ]; then
    tls_renew_log "ERROR: certbot renew failed (rc=$l_certbot_rc)"
    return $l_certbot_rc
  fi

  local l_cert_live_dir="$l_config_dir/live/$the_tls_renew_domain"
  local l_cert_path="$l_cert_live_dir/cert.pem"
  local l_chain_path="$l_cert_live_dir/chain.pem"
  local l_key_path="$l_cert_live_dir/privkey.pem"

  tls_renew_require_file "$l_cert_path" || return 1
  tls_renew_require_file "$l_chain_path" || return 1
  tls_renew_require_file "$l_key_path" || return 1

  tls_renew_log "Locating ACM certificate ARN from stack $the_tls_renew_stack_name"
  local l_cert_arn
  if ! l_cert_arn="$(tls_renew_find_cert_arn)"; then
    tls_renew_log "ERROR: Unable to resolve ApiCertificateArn from stack outputs"
    return 1
  fi

  tls_renew_log "Importing certificate into ACM (ARN: $l_cert_arn)"
  "$the_tls_renew_aws_bin" acm import-certificate \
    --region "$the_tls_renew_region" \
    --certificate "fileb://$l_cert_path" \
    --private-key "fileb://$l_key_path" \
    --certificate-chain "fileb://$l_chain_path" \
    --certificate-arn "$l_cert_arn"
  local l_import_rc=$?
  if [ $l_import_rc -ne 0 ]; then
    tls_renew_log "ERROR: AWS ACM import failed (rc=$l_import_rc)"
    return $l_import_rc
  fi

  tls_renew_log "TLS renewal complete."
}

tls_renew_main() {
  local l_command="${1:-run}"
  case "$l_command" in
    run)
      tls_renew_run
      ;;
    help|-h|--help)
      tls_renew_usage
      ;;
    *)
      tls_renew_log "ERROR: Unknown command '$l_command'"
      tls_renew_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" != "source-only" ]; then
  tls_renew_main "$@"
else
  true
fi
