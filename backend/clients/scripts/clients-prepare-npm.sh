#!/bin/bash
# clients-prepare-npm.sh, ABr
# Normalize metadata for the generated TypeScript client package.

clients_prepare_npm_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir pkg_dir pkg_json about_json
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return 1
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return 1
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return 1
  pkg_dir="$root_dir/.local/backend/clients/typescript-fetch"
  pkg_json="$pkg_dir/package.json"
  about_json="$root_dir/docs/about.json"

  if [ ! -f "$pkg_json" ]; then
    echo "[clients] prepare-npm: missing package.json at $pkg_json" >&2
    return 1
  fi

  local helper="$clients_dir/scripts/helpers/npm_package_metadata.py"
  if ! python3 "$helper" "$pkg_json" "$about_json"; then
    echo "[clients] prepare-npm: failed to update $pkg_json" >&2
    return 1
  fi
}

if [ "${1:-run}" = "source-only" ]; then
  clients_prepare_npm_main "source-only"
else
  clients_prepare_npm_main "$@"
fi
