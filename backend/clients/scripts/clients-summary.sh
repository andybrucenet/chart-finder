#!/bin/bash
# clients-summary.sh, ABr
# Summarize client SDK versions + endpoints.

clients_summary_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return $?
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return $?
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return $?

  source "$root_dir/scripts/lcl-os-checks.sh" 'source-only' || return $?
  source "$root_dir/scripts/cf-env-vars.sh" 'source-only' || return $?

  local spec_path="$root_dir/docs/api/chart-finder-openapi-v1.json"
  local cache_path="$root_dir/.local/state/chart-finder-openapi-v1.json"
  local spec_status="missing"
  if [ -f "$spec_path" ]; then
    if [ -f "$cache_path" ] && cmp -s "$spec_path" "$cache_path"; then
      spec_status="match"
    else
      spec_status="differs"
    fi
  fi

  local npm_version nuget_version dart_version
  npm_version="$(lcl_version_normalize_npm "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"
  nuget_version="$(lcl_version_normalize_nuget "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"
  dart_version="$(lcl_version_normalize_pub "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"

  cat <<REPORT
[clients] spec path: $spec_path ($spec_status vs cache)
[clients] npm version: $npm_version → https://www.npmjs.com/package/@andybrucenet/chart-finder-sdk/v/$npm_version
[clients] NuGet version: $nuget_version → https://www.nuget.org/packages/ChartFinder.Client/$nuget_version
[clients] Dart version: $dart_version → https://pub.dev/packages/chart_finder_client/versions/$dart_version
[clients] default base URI: ${CF_DEFAULT_BASE_URI}
REPORT
}

if [ "${1:-run}" = "source-only" ]; then
  clients_summary_main "source-only"
else
  clients_summary_main "$@"
fi
