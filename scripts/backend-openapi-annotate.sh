#!/bin/bash
# backend-openapi-annotate.sh
# Adds Chart Finder backend metadata fields to an OpenAPI document.

##############################################################
# OPTIONS
BACKEND_OPENAPI_ANNOTATE_OPTION_STDOUT="${BACKEND_OPENAPI_ANNOTATE_OPTION_STDOUT:-0}"

##############################################################
# environment
the_backend_openapi_annotate_source="${BASH_SOURCE[0]}"
while [ -h "$the_backend_openapi_annotate_source" ]; do
  the_backend_openapi_annotate_dir="$( cd -P "$( dirname "$the_backend_openapi_annotate_source" )" >/dev/null 2>&1 && pwd )"
  the_backend_openapi_annotate_source="$(readlink "$the_backend_openapi_annotate_source")"
  [[ $the_backend_openapi_annotate_source != /* ]] && the_backend_openapi_annotate_source="$the_backend_openapi_annotate_dir/$the_backend_openapi_annotate_source"
done
the_backend_openapi_annotate_script_dir="$( cd -P "$( dirname "$the_backend_openapi_annotate_source" )" >/dev/null 2>&1 && pwd )"
the_backend_openapi_annotate_root_dir="$( realpath "$the_backend_openapi_annotate_script_dir"/.. )"
source "$the_backend_openapi_annotate_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

##############################################################
# functions
backend_openapi_annotate_usage() {
  cat <<'USAGE'
Usage: ./scripts/backend-openapi-annotate.sh <openapi-json-path>

Adds Chart Finder backend metadata (version + build number) to the OpenAPI
info section. The JSON file is updated in-place unless BACKEND_OPENAPI_ANNOTATE_OPTION_STDOUT=1.
USAGE
}

backend_openapi_annotate_log() {
  local i_message="$1"
  printf '[backend-openapi-annotate] %s\n' "$i_message"
}

backend_openapi_annotate_update_file() {
  local i_target_file="$1"
  local l_stdout_mode="${BACKEND_OPENAPI_ANNOTATE_OPTION_STDOUT:-0}"
  if [ -z "$i_target_file" ]; then
    backend_openapi_annotate_log "ERROR: missing OpenAPI file path"
    return 1
  fi
  if [ ! -f "$i_target_file" ]; then
    backend_openapi_annotate_log "ERROR: OpenAPI file not found: $i_target_file"
    return 1
  fi

  local l_tmpdir
  l_tmpdir="$(lcl_os_tmp_dir)" || {
    backend_openapi_annotate_log "ERROR: unable to resolve temp directory"
    return 1
  }

  local l_tmpfile="$l_tmpdir/backend-openapi-annotate-$$.json"

  local l_python_cmd
  l_python_cmd=$(
    cat <<'PYCODE'
import json
import os
import pathlib
import sys

def main():
    source_path = pathlib.Path(sys.argv[1])
    dest_path = pathlib.Path(sys.argv[2])
    data = json.loads(source_path.read_text(encoding='utf-8'))
    info = data.setdefault('info', {})
    info['x-chartfinder-backend-version'] = os.environ.get('CF_BACKEND_VERSION_FULL', '')
    info['x-chartfinder-backend-build-number'] = os.environ.get('CF_BACKEND_BUILD_NUMBER', '')
    dest_path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

if __name__ == '__main__':
    main()
PYCODE
  )

  if ! python3 -c "$l_python_cmd" "$i_target_file" "$l_tmpfile"; then
    backend_openapi_annotate_log "ERROR: failed to update $i_target_file"
    rm -f "$l_tmpfile"
    return 1
  fi

  if [ "$l_stdout_mode" = "1" ]; then
    if ! cat "$l_tmpfile"; then
      backend_openapi_annotate_log "ERROR: failed to emit stdout output"
      rm -f "$l_tmpfile"
      return 1
    fi
    rm -f "$l_tmpfile"
    return 0
  fi

  if ! mv "$l_tmpfile" "$i_target_file"; then
    backend_openapi_annotate_log "ERROR: unable to replace $i_target_file"
    rm -f "$l_tmpfile"
    return 1
  fi

  backend_openapi_annotate_log "Updated metadata for $i_target_file"
}

backend_openapi_annotate_main() {
  local l_target_file="${1:-}"

  case "$l_target_file" in
    ''|--help|-h|help)
      backend_openapi_annotate_usage
      if [ -z "$l_target_file" ]; then
        return 1
      fi
      return 0
      ;;
  esac

  backend_openapi_annotate_update_file "$l_target_file"
}

if [ "${1:-}" != "source-only" ]; then
  backend_openapi_annotate_main "$@"
else
  true
fi
