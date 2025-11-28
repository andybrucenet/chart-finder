#!/bin/bash
# clients-prepare-dotnet.sh, ABr
# Ensure the generated .NET client has required packaging metadata/files.

clients_prepare_dotnet_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir project_dir csproj_path license_src license_dst readme_path about_json
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return 1
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return 1
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return 1
  source "$root_dir/scripts/lcl-os-checks.sh" 'source-only' || return 1
  source "$root_dir/scripts/cf-env-vars.sh" 'source-only' || return 1
  local product_name="${CF_GLOBAL_PRODUCT:?CF_GLOBAL_PRODUCT missing}"
  project_dir="$root_dir/.local/backend/clients/dotnet/src/ChartFinder.Client"
  csproj_path="$project_dir/ChartFinder.Client.csproj"
  readme_path="$project_dir/README.md"
  license_src="$root_dir/NOTICE.txt"
  license_dst="$project_dir/LICENSE.txt"
  about_json="$root_dir/docs/about.json"

  if [ ! -d "$project_dir" ] || [ ! -f "$csproj_path" ]; then
    echo "[clients] prepare-dotnet: missing project at $project_dir" >&2
    return 1
  fi

  # Ensure license file exists by copying NOTICE.txt (preferred) or creating a placeholder.
  if [ -f "$license_src" ]; then
    cp "$license_src" "$license_dst"
  else
    cat >"$license_dst" <<LICENSE
© 2025 ${product_name}. All rights reserved.
LICENSE
  fi

  if [ ! -f "$readme_path" ]; then
    cat >"$readme_path" <<README
# ${product_name} Client

Auto-generated SDK for the ${product_name} API.
README
  fi

  local helper="$clients_dir/scripts/helpers/dotnet_csproj_metadata.py"
  if ! python3 "$helper" "$csproj_path" "$about_json"; then
    echo "[clients] prepare-dotnet: failed to update $csproj_path" >&2
    return 1
  fi
}

if [ "${1:-run}" = "source-only" ]; then
  clients_prepare_dotnet_main "source-only"
else
  clients_prepare_dotnet_main "$@"
fi
