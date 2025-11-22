#!/bin/bash
# frontend-flutter-sync-client.sh
# Ensure the Flutter app references the chart_finder_client version derived from the OpenAPI spec.

# resolve directories
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$( realpath "$SCRIPT_DIR"/.. )"

source "$ROOT_DIR/scripts/lcl-os-checks.sh" 'source-only' || exit $?
source "$ROOT_DIR/scripts/cf-env-vars.sh" 'source-only' || exit $?

SCRIPT_NAME='frontend-flutter-sync-client'
SPEC_PATH="$ROOT_DIR/docs/api/chart-finder-openapi-v1.json"
PUBSPEC_PATH="$ROOT_DIR/src/frontend/chart-finder-flutter/pubspec.yaml"

log() { printf '[%s] %s\n' "$SCRIPT_NAME" "$1"; }

frontend_flutter_sync_client_main() {
  if [ ! -s "$SPEC_PATH" ]; then
    log "WARN: missing OpenAPI spec at $SPEC_PATH; skipping client sync"
    return 0
  fi
  if [ ! -s "$PUBSPEC_PATH" ]; then
    log "ERROR: missing pubspec at $PUBSPEC_PATH"
    return 1
  fi

  local spec_version
  local spec_build
  spec_version=$(python3 - <<'PY' "$SPEC_PATH"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
info = data.get('info', {})
print(info.get('x-chartfinder-backend-version', '') or '')
PY
  ) || return $?
  spec_build=$(python3 - <<'PY' "$SPEC_PATH"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
info = data.get('info', {})
print(info.get('x-chartfinder-backend-build-number', '') or '')
PY
  ) || return $?

  if [ -z "$spec_version" ] || [ -z "$spec_build" ]; then
    log "WARN: spec missing backend metadata; skipping client sync"
    return 0
  fi

  local expected_version
  if ! expected_version="$(lcl_version_normalize_pub "$spec_version" "$spec_build")"; then
    log "ERROR: unable to normalize spec version/build"
    return 1
  fi

  local current_version
  current_version=$(python3 - <<'PY' "$PUBSPEC_PATH"
import sys
from pathlib import Path
path = Path(sys.argv[1])
for line in path.read_text().splitlines():
    stripped = line.strip()
    if stripped.startswith('chart_finder_client:'):
        print(stripped.split(':',1)[1].strip())
        break
PY
  ) || return $?
  current_version="${current_version}"  # ensure empty string allowed

  if [ "$current_version" = "$expected_version" ]; then
    log "chart_finder_client already at $expected_version"
    return 0
  fi

  log "Updating chart_finder_client from '${current_version:-<none>}' to '$expected_version'"
  python3 - <<'PY' "$PUBSPEC_PATH" "$expected_version"
import sys
from pathlib import Path
path = Path(sys.argv[1])
expected = sys.argv[2]
lines = path.read_text().splitlines()
updated = []
replaced = False
for line in lines:
    stripped = line.strip()
    if stripped.startswith('chart_finder_client:'):
        indent = line[:line.index('c')]
        updated.append(f"{indent}chart_finder_client: {expected}")
        replaced = True
    else:
        updated.append(line)
if not replaced:
    raise SystemExit('chart_finder_client dependency not found in pubspec.yml')
path.write_text("\n".join(updated) + "\n")
PY
  local status=$?
  if [ $status -ne 0 ]; then
    log "ERROR: failed to update pubspec"
    return $status
  fi
  log "Updated pubspec dependency to $expected_version"
}

if [ "${1:-}" = "source-only" ]; then
  true
else
  frontend_flutter_sync_client_main "$@"
fi
