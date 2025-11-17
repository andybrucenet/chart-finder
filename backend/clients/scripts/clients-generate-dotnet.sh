#!/bin/bash
# clients-generate-dotnet.sh, ABr
# Generate the .NET (NuGet) client from the OpenAPI spec.

clients_generate_dotnet_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ x"$i_mode" = x"source-only" ]; then
    return 0
  fi

  local l_script_dir l_clients_dir l_root_dir
  l_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return $?
  l_clients_dir="$( cd "$l_script_dir/.." >/dev/null 2>&1 && pwd )" || return $?
  l_root_dir="$( cd "$l_clients_dir/../.." >/dev/null 2>&1 && pwd )" || return $?

  source "$l_root_dir/scripts/cf-env-vars.sh" 'source-only' || return $?

  local l_version_short="${CF_BACKEND_VERSION_SHORT:-}"
  local l_build_number="${CF_BACKEND_BUILD_NUMBER:-}"
  local l_base_uri="${CF_DEFAULT_BASE_URI:-}"
  if [ -z "$l_version_short" ] || [ -z "$l_build_number" ]; then
    echo "clients-generate-dotnet: backend version variables missing (run scripts/cf-env-vars.sh)" >&2
    return 1
  fi
  if [ -z "$l_base_uri" ]; then
    echo "clients-generate-dotnet: CF_DEFAULT_BASE_URI is unset" >&2
    return 1
  fi

  local l_nuget_version
  if ! l_nuget_version="$(lcl_version_normalize_nuget "$l_version_short" "$l_build_number")"; then
    echo "clients-generate-dotnet: unable to normalize NuGet version" >&2
    return 1
  fi

  local l_spec_path="$l_root_dir/docs/api/chart-finder-openapi-v1.json"
  if [ ! -s "$l_spec_path" ]; then
    echo "clients-generate-dotnet: missing OpenAPI spec at $l_spec_path" >&2
    return 1
  fi

  local l_output_dir="$l_root_dir/.local/backend/clients/dotnet"
  mkdir -p "$l_output_dir" || return $?

  local l_tmp_spec
  if ! l_tmp_spec="$(mktemp "$l_output_dir/spec.XXXXXX.json")"; then
    echo "clients-generate-dotnet: unable to allocate temp spec" >&2
    return 1
  fi

  python3 - <<'PY' "$l_spec_path" "$l_tmp_spec" "$l_base_uri"
import json, sys
src, dst, base_uri = sys.argv[1:]
with open(src, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
sanitized = base_uri.rstrip('/') or base_uri
data['servers'] = [{'url': sanitized}]
with open(dst, 'w', encoding='utf-8') as fh:
    json.dump(data, fh, indent=2)
PY
  local l_py_status=$?
  if [ $l_py_status -ne 0 ]; then
    rm -f "$l_tmp_spec"
    echo "clients-generate-dotnet: unable to inject servers into spec" >&2
    return $l_py_status
  fi

  (
    cd "$l_clients_dir" || exit 1
    npx openapi-generator-cli generate \
      -i "$l_tmp_spec" \
      -g csharp \
      -o "$l_output_dir" \
      -c "$l_clients_dir/csharp.config.json" \
      --skip-validate-spec \
      --global-property apiTests=false,modelTests=false \
      --additional-properties packageVersion="$l_nuget_version"
  )
  local l_generate_status=$?
  rm -f "$l_tmp_spec"
  return $l_generate_status
}

if [ "${1:-run}" = "source-only" ]; then
  clients_generate_dotnet_main "source-only"
else
  clients_generate_dotnet_main "$@"
fi
