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
    echo "[clients] generate-dart: unable to inject servers into spec" >&2
    return $l_py_status
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
  python3 - <<'PY' "$l_config_template" "$l_tmp_config" "$l_pub_version" "$l_about_json"
import json, sys, os

tpl_path, out_path, pub_version, about_path = sys.argv[1:5]
with open(tpl_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)

props = data.setdefault('additionalProperties', {})
props['pubVersion'] = pub_version

about = {}
if os.path.exists(about_path):
    with open(about_path, 'r', encoding='utf-8') as fh:
        about = json.load(fh)

def maybe_set(key, value):
    if value:
        props[key] = value

maybe_set('pubDescription', about.get('productName', 'Chart Finder API client'))
maybe_set('pubAuthor', about.get('authorName'))
maybe_set('pubAuthorEmail', about.get('authorEmail'))
maybe_set('pubHomepage', about.get('homepage'))
maybe_set('pubRepository', about.get('repositoryUrl'))
maybe_set('pubIssueTracker', about.get('supportUrl'))

with open(out_path, 'w', encoding='utf-8') as fh:
    json.dump(data, fh, indent=2)
PY
  local l_cfg_status=$?
  if [ $l_cfg_status -ne 0 ]; then
    rm -f "$l_tmp_spec" "$l_tmp_config"
    echo "[clients] generate-dart: unable to hydrate config" >&2
    return $l_cfg_status
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
