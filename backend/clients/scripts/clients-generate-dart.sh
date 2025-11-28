#!/bin/bash
# clients-generate-dart.sh, ABr
# Generate the Dart (Flutter) client from the OpenAPI spec.

clients_generate_dart_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ x"$i_mode" = x"source-only" ]; then
    return 0
  fi

  local l_script_dir l_clients_dir l_root_dir
  l_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return $?
  l_clients_dir="$( cd "$l_script_dir/.." >/dev/null 2>&1 && pwd )" || return $?
  l_root_dir="$( cd "$l_clients_dir/../.." >/dev/null 2>&1 && pwd )" || return $?

  source "$l_root_dir/scripts/lcl-os-checks.sh" 'source-only' || return $?
  source "$l_root_dir/scripts/cf-env-vars.sh" 'source-only' || return $?

  local l_version_short="${CF_BACKEND_VERSION_SHORT:-}"
  local l_build_number="${CF_BACKEND_BUILD_NUMBER:-}"
  local l_base_uri="${CF_DEFAULT_BASE_URI:-}"
  if [ -z "$l_version_short" ] || [ -z "$l_build_number" ]; then
    echo "[clients] generate-dart: backend version variables missing (run scripts/cf-env-vars.sh)" >&2
    return 1
  fi
  if [ -z "$l_base_uri" ]; then
    echo "[clients] generate-dart: CF_DEFAULT_BASE_URI is unset" >&2
    return 1
  fi

  local l_pub_version
  if ! l_pub_version="$(lcl_version_normalize_pub "$l_version_short" "$l_build_number")"; then
    echo "[clients] generate-dart: unable to normalize pub.dev version" >&2
    return 1
  fi

  local l_spec_path="$l_root_dir/docs/api/chart-finder-openapi-v1.json"
  if [ ! -s "$l_spec_path" ]; then
    echo "[clients] generate-dart: missing OpenAPI spec at $l_spec_path" >&2
    return 1
  fi

  local l_output_dir="$l_root_dir/.local/backend/clients/dart"
  local l_stage_dir
  if ! l_stage_dir="$(mktemp -d "$l_root_dir/.local/backend/clients/dart.stage.XXXXXX")"; then
    echo "[clients] generate-dart: unable to allocate stage directory" >&2
    return 1
  fi

  local l_tmp_spec
  if ! l_tmp_spec="$(mktemp "$l_stage_dir/spec.XXXXXX.json")"; then
    echo "[clients] generate-dart: unable to allocate temp spec" >&2
    rmdir "$l_stage_dir"
    return 1
  fi

  local l_spec_helper="$l_clients_dir/scripts/helpers/spec_update_servers.py"
  if ! python3 "$l_spec_helper" "$l_spec_path" "$l_tmp_spec" "$l_base_uri"; then
    rm -f "$l_tmp_spec"
    echo "[clients] generate-dart: unable to inject servers into spec" >&2
    return 1
  fi

  local l_config_template="$l_clients_dir/dart.config.json"
  local l_tmp_config
  if ! l_tmp_config="$(mktemp "$l_stage_dir/config.XXXXXX.json")"; then
    rm -f "$l_tmp_spec"
    rmdir "$l_stage_dir"
    echo "[clients] generate-dart: unable to allocate temp config" >&2
    return 1
  fi

  local l_about_json="$l_root_dir/docs/about.json"
  local l_config_helper="$l_clients_dir/scripts/helpers/dart_config_hydrate.py"
  if ! python3 "$l_config_helper" "$l_config_template" "$l_tmp_config" "$l_pub_version" "$l_about_json"; then
    rm -f "$l_tmp_spec" "$l_tmp_config"
    echo "[clients] generate-dart: unable to hydrate config" >&2
    return 1
  fi

  local l_generator="dart-dio"
  (
    cd "$l_clients_dir" || exit 1
    npx openapi-generator-cli generate \
      -i "$l_tmp_spec" \
      -g "$l_generator" \
      -o "$l_stage_dir/output" \
      -c "$l_tmp_config" \
      --skip-validate-spec \
      --global-property apiTests=false,modelTests=false
  )
  local l_generate_status=$?
  rm -f "$l_tmp_spec" "$l_tmp_config"
  if [ $l_generate_status -ne 0 ]; then
    rm -rf "$l_stage_dir"
    return $l_generate_status
  fi

  rm -rf "$l_output_dir"
  mkdir -p "$l_output_dir" || {
    rm -rf "$l_stage_dir"
    return 1
  }
  /bin/cp -R "$l_stage_dir/output/." "$l_output_dir/" || {
    rm -rf "$l_stage_dir"
    return 1
  }
  rm -rf "$l_stage_dir"
  return 0
}

if [ "${1:-run}" = "source-only" ]; then
  clients_generate_dart_main "source-only"
else
  clients_generate_dart_main "$@"
fi
