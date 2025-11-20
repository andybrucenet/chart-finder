#!/bin/bash
# frontend-src-sig.sh
# Compute frontend source signature and auto-bump build number when it changes.

# resolve directories
the_frontend_src_sig_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_src_sig_source" ]; do
  the_frontend_src_sig_dir="$( cd -P "$( dirname "$the_frontend_src_sig_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_src_sig_source="$(readlink "$the_frontend_src_sig_source")"
  [[ $the_frontend_src_sig_source != /* ]] && the_frontend_src_sig_source="$the_frontend_src_sig_dir/$the_frontend_src_sig_source"
done
the_frontend_src_sig_script_dir="$( cd -P "$( dirname "$the_frontend_src_sig_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_src_sig_root_dir="$( realpath "$the_frontend_src_sig_script_dir"/.. )"
source "$the_frontend_src_sig_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

the_frontend_src_sig_app_dir_react="${CF_FRONTEND_APP_DIR_REACT:-${CF_FRONTEND_APP_DIR:-$the_frontend_src_sig_root_dir/src/frontend/chart-finder-react}}"
the_frontend_src_sig_app_dir_flutter="${CF_FRONTEND_APP_DIR_FLUTTER:-$the_frontend_src_sig_root_dir/src/frontend/chart-finder-flutter}"
the_frontend_src_sig_source_roots=()
the_frontend_src_sig_active_env="${CF_LOCAL_FRONTEND_ENV:-all}"
case "$the_frontend_src_sig_active_env" in
  react)
    [ -d "$the_frontend_src_sig_app_dir_react" ] && the_frontend_src_sig_source_roots+=("react|$the_frontend_src_sig_app_dir_react")
    ;;
  flutter)
    [ -d "$the_frontend_src_sig_app_dir_flutter" ] && the_frontend_src_sig_source_roots+=("flutter|$the_frontend_src_sig_app_dir_flutter")
    ;;
  all|both|'')
    [ -d "$the_frontend_src_sig_app_dir_react" ] && the_frontend_src_sig_source_roots+=("react|$the_frontend_src_sig_app_dir_react")
    [ -d "$the_frontend_src_sig_app_dir_flutter" ] && the_frontend_src_sig_source_roots+=("flutter|$the_frontend_src_sig_app_dir_flutter")
    ;;
  *)
    frontend_src_sig_log "WARN: unknown CF_LOCAL_FRONTEND_ENV='$the_frontend_src_sig_active_env'; hashing all known roots."
    [ -d "$the_frontend_src_sig_app_dir_react" ] && the_frontend_src_sig_source_roots+=("react|$the_frontend_src_sig_app_dir_react")
    [ -d "$the_frontend_src_sig_app_dir_flutter" ] && the_frontend_src_sig_source_roots+=("flutter|$the_frontend_src_sig_app_dir_flutter")
    ;;
esac
the_frontend_src_sig_state_dir="$the_frontend_src_sig_root_dir/$g_DOT_LOCAL_DIR_NAME/state"
the_frontend_src_sig_state_file="$the_frontend_src_sig_state_dir/frontend-source.sig"

frontend_src_sig_log() {
  local i_message="$1"
  printf '[frontend-src-sig] %s\n' "$i_message"
}

frontend_src_sig_usage() {
  cat <<'USAGE'
Usage: ./scripts/frontend-src-sig.sh [command]

Commands:
  run        Compute signature, update build number if needed (default)
  show       Print current and previous signatures without updating
  help       Show this message
USAGE
}

frontend_src_sig_verify_prereqs() {
  if [ ${#the_frontend_src_sig_source_roots[@]} -eq 0 ]; then
    frontend_src_sig_log "ERROR: no frontend source directories found (expected react and/or flutter)"
    frontend_src_sig_log "Checked REACT: $the_frontend_src_sig_app_dir_react"
    frontend_src_sig_log "Checked FLUTTER: $the_frontend_src_sig_app_dir_flutter"
    return 1
  fi
  if ! mkdir -p "$the_frontend_src_sig_state_dir"; then
    frontend_src_sig_log "ERROR: failed to create state dir: $the_frontend_src_sig_state_dir"
    return 1
  fi
  return 0
}

frontend_src_sig_compute_signature() {
  local -a l_signature_args=()
  local l_entry l_prefix l_path
  for l_entry in "${the_frontend_src_sig_source_roots[@]}"; do
    l_prefix="${l_entry%%|*}"
    l_path="${l_entry#*|}"
    l_signature_args+=("$l_prefix" "$l_path")
  done
  local l_signature
  if ! l_signature="$(
    python3 - "${l_signature_args[@]}" <<'PY'
import hashlib
import os
import sys

args = sys.argv[1:]
if len(args) % 2 != 0:
    print("ERROR: expected prefix/path argument pairs", file=sys.stderr)
    sys.exit(2)

roots = [(args[i], args[i + 1]) for i in range(0, len(args), 2)]
if not roots:
    print("ERROR: no frontend roots provided", file=sys.stderr)
    sys.exit(3)

skip_dirs_common = {'.git', '.expo', '.expo-shared', '.turbo', 'dist', 'build', '.dart_tool', '.fvm', '.idea', '.gradle'}
skip_dirs_per_prefix = {
    'react': skip_dirs_common | {'node_modules'},
    'flutter': skip_dirs_common | {'node_modules', 'ios', 'android', '.symlinks'},
}
skip_files = {'src/versionInfo.ts', 'lib/version_info.dart', 'lib/version_info.g.dart'}

records = []
for prefix, root in roots:
    if not os.path.isdir(root):
        continue
    local_skip_dirs = skip_dirs_per_prefix.get(prefix, skip_dirs_common)
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in local_skip_dirs]
        for name in filenames:
            path = os.path.join(dirpath, name)
            rel_path = os.path.relpath(path, root)
            rel_posix = rel_path.replace(os.sep, '/')
            rel_with_prefix = f"{prefix}/{rel_posix}" if prefix else rel_posix
            if rel_with_prefix in skip_files or rel_posix in skip_files:
                continue
            try:
                with open(path, 'rb') as handle:
                    file_hash = hashlib.sha256()
                    while True:
                        chunk = handle.read(1024 * 1024)
                        if not chunk:
                            break
                        file_hash.update(chunk)
            except (FileNotFoundError, PermissionError):
                continue
            records.append((rel_with_prefix, file_hash.hexdigest()))

records.sort()
summary = hashlib.sha256()
for rel_path, digest in records:
    summary.update(rel_path.encode('utf-8'))
    summary.update(b':')
    summary.update(digest.encode('utf-8'))

print(summary.hexdigest())
PY
  )"; then
    frontend_src_sig_log "ERROR: failed to compute frontend signature"
    return 1
  fi

  l_signature="$(echo "$l_signature" | tr -d '\r\n')"
  if [ -z "$l_signature" ]; then
    frontend_src_sig_log "ERROR: computed signature is empty"
    return 1
  fi

  printf '%s\n' "$l_signature"
}

frontend_src_sig_read_previous() {
  if [ -s "$the_frontend_src_sig_state_file" ]; then
    cat "$the_frontend_src_sig_state_file"
  fi
}

frontend_src_sig_write_signature() {
  local i_signature="$1"
  if ! printf '%s\n' "$i_signature" >"$the_frontend_src_sig_state_file"; then
    frontend_src_sig_log "ERROR: failed to write signature file: $the_frontend_src_sig_state_file"
    return 1
  fi
  frontend_src_sig_log "Stored signature in $the_frontend_src_sig_state_file"
}

frontend_src_sig_update_build_number() {
  local l_build_number
  l_build_number="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  frontend_src_sig_log "Updating frontend build number to $l_build_number"
  if ! CHARTFINDER_FRONTEND_BUILD_NUMBER="$l_build_number" "$the_frontend_src_sig_root_dir/scripts/update-version.sh" frontend-batch; then
    frontend_src_sig_log "ERROR: update-version.sh frontend-batch failed"
    return 1
  fi
  frontend_src_sig_log "Frontend build number updated"
}

frontend_src_sig_show() {
  local l_current l_previous
  if ! l_current="$(frontend_src_sig_compute_signature)"; then
    return 1
  fi
  l_previous="$(frontend_src_sig_read_previous)"
  frontend_src_sig_log "Frontend Src Signature (CURRENT) : $l_current"
  frontend_src_sig_log "Frontend Src Signature (PREVIOUS): ${l_previous:-<none>}"
}

frontend_src_sig_run() {
  if ! frontend_src_sig_verify_prereqs; then
    return 1
  fi

  local l_current l_previous
  if ! l_current="$(frontend_src_sig_compute_signature)"; then
    return 1
  fi
  l_previous="$(frontend_src_sig_read_previous)"

  frontend_src_sig_log "Frontend Src Signature (CURRENT) : $l_current"
  frontend_src_sig_log "Frontend Src Signature (PREVIOUS): ${l_previous:-<none>}"

  if [ -n "$l_previous" ] && [ "$l_current" = "$l_previous" ]; then
    frontend_src_sig_log "Signatures identical; no build number update required."
    return 0
  fi

  if ! frontend_src_sig_update_build_number; then
    return 1
  fi

  # recompute signature after regenerating artifacts (e.g., versionInfo.ts)
  if ! l_current="$(frontend_src_sig_compute_signature)"; then
    return 1
  fi
  frontend_src_sig_log "Frontend Src Signature (UPDATED): $l_current"

  if ! frontend_src_sig_write_signature "$l_current"; then
    return 1
  fi

  frontend_src_sig_log "Frontend source signature updated successfully."
}

frontend_src_sig_main() {
  local l_command="${1:-run}"

  case "$l_command" in
    run)
      frontend_src_sig_run
      ;;
    show)
      frontend_src_sig_verify_prereqs && frontend_src_sig_show
      ;;
    help|--help|-h)
      frontend_src_sig_usage
      ;;
    *)
      frontend_src_sig_log "ERROR: unknown command '$l_command'"
      frontend_src_sig_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" != "source-only" ]; then
  frontend_src_sig_main "$@"
else
  true
fi
