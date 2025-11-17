#!/bin/bash
# clients-publish-all.sh, ABr
# Publish all backend client SDKs.

clients_publish_all_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir dotnet_dir ts_dir
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return 1
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return 1
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return 1
  dotnet_dir="$root_dir/.local/backend/clients/dotnet"
  ts_dir="$root_dir/.local/backend/clients/typescript-fetch"

  source "$root_dir/scripts/lcl-os-checks.sh" 'source-only' || return 1
  source "$root_dir/scripts/cf-env-vars.sh" 'source-only' || return 1

  local nuget_version
  if ! nuget_version="$(lcl_version_normalize_nuget "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"; then
    echo "[clients] ERROR: unable to compute NuGet version" >&2
    return 1
  fi
  local nuget_pkg_path="$dotnet_dir/src/ChartFinder.Client/bin/Release/ChartFinder.Client.${nuget_version}.nupkg"

  if [ -z "${CLIENTS_SKIP_NUGET:-}" ]; then
    echo "[clients] dotnet pack"
    if ! ( cd "$dotnet_dir" && dotnet pack -c Release ); then
      echo "[clients] ERROR: dotnet pack failed" >&2
      return 1
    fi

    if [ ! -f "$nuget_pkg_path" ]; then
      echo "[clients] ERROR: expected package not found at $nuget_pkg_path" >&2
      return 1
    fi

    echo "[clients] nuget push ($nuget_pkg_path)"
    if ! dotnet nuget push "$nuget_pkg_path" \
      --source https://api.nuget.org/v3/index.json \
      --api-key "${CF_LOCAL_BACKEND_API_KEY_NUGET_ORG:?Set CF_LOCAL_BACKEND_API_KEY_NUGET_ORG}" \
      --skip-duplicate; then
      echo "[clients] ERROR: nuget push failed" >&2
      return 1
    fi
  else
    echo "[clients] Skipping NuGet publish (CLIENTS_SKIP_NUGET=1)"
  fi

  if [ -z "${CLIENTS_SKIP_NPM:-}" ]; then
    local npm_version npm_tag_flag=""
    npm_version="$(node -p "require('$ts_dir/package.json').version" 2>/dev/null || echo "")"
    if [[ "$npm_version" == *-* ]]; then
      npm_tag_flag="--tag prerelease"
    fi

    echo "[clients] npm install ($ts_dir)"
    if ! ( cd "$ts_dir" && npm install ); then
      echo "[clients] ERROR: npm install failed" >&2
      return 1
    fi

    echo "[clients] npm publish ($ts_dir)"
    if ! ( cd "$ts_dir" && npm publish --access public $npm_tag_flag ); then
      echo "[clients] ERROR: npm publish failed" >&2
      return 1
    fi
  else
    echo "[clients] Skipping npm publish (CLIENTS_SKIP_NPM=1)"
  fi
}

if [ "${1:-run}" = "source-only" ]; then
  clients_publish_all_main "source-only"
else
  clients_publish_all_main "$@"
fi
