#!/bin/bash
# clients-publish-all.sh, ABr
# Publish all backend client SDKs.

clients_publish_all_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir dotnet_dir ts_dir dart_dir
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return 1
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return 1
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return 1
  dotnet_dir="$root_dir/.local/backend/clients/dotnet"
  ts_dir="$root_dir/.local/backend/clients/typescript-fetch"
  dart_dir="$root_dir/.local/backend/clients/dart"

  source "$root_dir/scripts/lcl-os-checks.sh" 'source-only' || return 1
  source "$root_dir/scripts/cf-env-vars.sh" 'source-only' || return 1

  local nuget_version npm_version dart_version
  if ! nuget_version="$(lcl_version_normalize_nuget "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"; then
    echo "[clients] ERROR: unable to compute NuGet version" >&2
    return 1
  fi
  if ! npm_version="$(lcl_version_normalize_npm "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"; then
    echo "[clients] ERROR: unable to compute npm version" >&2
    return 1
  fi
  if ! dart_version="$(lcl_version_normalize_pub "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"; then
    echo "[clients] ERROR: unable to compute Dart version" >&2
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
      echo "[clients] WARN: npm publish failed; checking for existing version" >&2
      if npm view "@andybrucenet/chart-finder-sdk@$npm_version" >/dev/null 2>&1; then
        echo "[clients] npm version already exists upstream; treating as success"
      else
        echo "[clients] ERROR: npm publish failed and version not found upstream" >&2
        return 1
      fi
    fi
  else
    echo "[clients] Skipping npm publish (CLIENTS_SKIP_NPM=1)"
  fi

  if [ -z "${CLIENTS_SKIP_DART:-}" ]; then
    if [ ! -d "$dart_dir" ] || [ ! -f "$dart_dir/pubspec.yaml" ]; then
      echo "[clients] ERROR: dart client not generated at $dart_dir" >&2
      return 1
    fi
    if ! command -v dart >/dev/null 2>&1; then
      echo "[clients] ERROR: dart CLI not found (install Dart SDK)" >&2
      return 1
    fi

    local dart_stage_dir
    if ! dart_stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/chart-finder-dart-pkg.XXXXXX")"; then
      echo "[clients] ERROR: unable to allocate Dart staging directory" >&2
      return 1
    fi

    if ! rsync -a "$dart_dir"/ "$dart_stage_dir"/; then
      rm -rf "$dart_stage_dir"
      echo "[clients] ERROR: unable to stage Dart package" >&2
      return 1
    fi

    echo "[clients] dart pub get ($dart_stage_dir)"
    if ! ( cd "$dart_stage_dir" && dart pub get ); then
      rm -rf "$dart_stage_dir"
      echo "[clients] ERROR: dart pub get failed" >&2
      return 1
    fi

    echo "[clients] dart run build_runner build --delete-conflicting-outputs ($dart_stage_dir)"
    if ! ( cd "$dart_stage_dir" && dart run build_runner build --delete-conflicting-outputs >/dev/null ); then
      rm -rf "$dart_stage_dir"
      echo "[clients] ERROR: dart run build_runner build failed" >&2
      return 1
    fi

    echo "[clients] dart pub publish --dry-run ($dart_stage_dir)"
    if ! ( cd "$dart_stage_dir" && dart pub publish --dry-run ); then
      rm -rf "$dart_stage_dir"
      echo "[clients] ERROR: dart pub publish --dry-run failed" >&2
      return 1
    fi

    echo "[clients] dart pub publish --force ($dart_stage_dir)"
    if ! ( cd "$dart_stage_dir" && dart pub publish --force ); then
      echo "[clients] WARN: dart pub publish failed; checking for existing version" >&2
      if python3 - <<'PY' "$dart_version"
import json, sys, urllib.request
version = sys.argv[1]
url = "https://pub.dev/api/packages/chart_finder_client"
try:
    with urllib.request.urlopen(url, timeout=10) as resp:
        data = json.load(resp)
    versions = [entry["version"] for entry in data.get("versions", [])]
    sys.exit(0 if version in versions else 1)
except Exception:
    sys.exit(1)
PY
      then
        echo "[clients] Dart version already exists on pub.dev; treating as success"
      else
        echo "[clients] ERROR: dart pub publish failed and version not found on pub.dev" >&2
        rm -rf "$dart_stage_dir"
        return 1
      fi
    fi
    rm -rf "$dart_stage_dir"
  else
    echo "[clients] Skipping Dart publish (CLIENTS_SKIP_DART=1)"
  fi
}

if [ "${1:-run}" = "source-only" ]; then
  clients_publish_all_main "source-only"
else
  clients_publish_all_main "$@"
fi
