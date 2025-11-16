#!/bin/bash
# tls-status.sh
# Inspect the current TLS certificate and report its expiration window.

the_tls_status_source="${BASH_SOURCE[0]}"
while [ -h "$the_tls_status_source" ]; do
  the_tls_status_dir="$( cd -P "$( dirname "$the_tls_status_source" )" >/dev/null 2>&1 && pwd )"
  the_tls_status_source="$(readlink "$the_tls_status_source")"
  [[ $the_tls_status_source != /* ]] && the_tls_status_source="$the_tls_status_dir/$the_tls_status_source"
done
the_tls_status_script_dir="$( cd -P "$( dirname "$the_tls_status_source" )" >/dev/null 2>&1 && pwd )"
the_tls_status_root_dir="$( realpath "$the_tls_status_script_dir"/.. )"

source "$the_tls_status_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_tls_status_root_dir" || exit $?

the_tls_status_cert_path="${TLS_STATUS_OPTION_CERT_PATH:-${CF_LOCAL_TLS_CERT_PATH:-}}"

tls_status_log() {
  local i_message="$1"
  printf '[tls-status] %s\n' "$i_message"
}

tls_status_usage() {
  cat <<'USAGE'
Usage: ./scripts/tls-status.sh [command]

Commands:
  show       Display certificate subject, issuer, and expiry (default)
  help       Show this help text

Environment overrides:
  TLS_STATUS_OPTION_CERT_PATH   Path to the PEM certificate (defaults to CF_LOCAL_TLS_CERT_PATH)
USAGE
}

tls_status_check_prereqs() {
  if [ -z "$the_tls_status_cert_path" ]; then
    tls_status_log "ERROR: CF_LOCAL_TLS_CERT_PATH is unset (set TLS_STATUS_OPTION_CERT_PATH to override)"
    return 1
  fi
  if [ ! -f "$the_tls_status_cert_path" ]; then
    tls_status_log "ERROR: certificate file not found: $the_tls_status_cert_path"
    return 1
  fi
  if ! command -v openssl >/dev/null 2>&1; then
    tls_status_log "ERROR: openssl not found in PATH"
    return 1
  fi
  return 0
}

tls_status_show() {
  tls_status_check_prereqs || return 1
  python3 - "$the_tls_status_cert_path" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path
import ssl

path = Path(sys.argv[1])
cert = ssl._ssl._test_decode_cert(str(path))
subject = ', '.join('='.join(map(str, pair)) for pair in cert.get('subject', []))
issuer = ', '.join('='.join(map(str, pair)) for pair in cert.get('issuer', []))
not_before = cert.get('notBefore')
not_after = cert.get('notAfter')

def parse(ts: str | None) -> datetime | None:
    if not ts:
        return None
    return datetime.strptime(ts, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)

nb = parse(not_before)
na = parse(not_after)
now = datetime.now(timezone.utc)
days_left = (na - now).days if na else None

print(f"Subject       : {subject}")
print(f"Issuer        : {issuer}")
print(f"Not Before    : {nb.isoformat() if nb else 'unknown'}")
print(f"Not After     : {na.isoformat() if na else 'unknown'}")
print(f"Days Remaining: {days_left if days_left is not None else 'unknown'}")
if days_left is not None:
    if days_left < 0:
        print("Status        : EXPIRED")
    elif days_left <= 2:
        print("Status        : CRITICAL (<48h)")
    elif days_left <= 7:
        print("Status        : Warning (<=7 days)")
    elif days_left <= 14:
        print("Status        : Notice (<=14 days)")
    else:
        print("Status        : OK")
PY
}

tls_status_main() {
  local l_command="${1:-show}"
  case "$l_command" in
    show)
      tls_status_show
      ;;
    help|-h|--help)
      tls_status_usage
      ;;
    *)
      tls_status_log "ERROR: unknown command '$l_command'"
      tls_status_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" != "source-only" ]; then
  tls_status_main "$@"
else
  true
fi
