#!/bin/bash
# frontend-version-artifacts.sh
# Generate frontend source artifacts (e.g., versionInfo.ts / version_info.dart) from frontend/version.json.

# resolve directories
the_frontend_version_artifacts_source="${BASH_SOURCE[0]}"
while [ -h "$the_frontend_version_artifacts_source" ]; do
  the_frontend_version_artifacts_dir="$( cd -P "$( dirname "$the_frontend_version_artifacts_source" )" >/dev/null 2>&1 && pwd )"
  the_frontend_version_artifacts_source="$(readlink "$the_frontend_version_artifacts_source")"
  [[ $the_frontend_version_artifacts_source != /* ]] && the_frontend_version_artifacts_source="$the_frontend_version_artifacts_dir/$the_frontend_version_artifacts_source"
done
the_frontend_version_artifacts_script_dir="$( cd -P "$( dirname "$the_frontend_version_artifacts_source" )" >/dev/null 2>&1 && pwd )"
the_frontend_version_artifacts_root_dir="$( realpath "$the_frontend_version_artifacts_script_dir"/.. )"
source "$the_frontend_version_artifacts_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

the_frontend_version_artifacts_version_file="$the_frontend_version_artifacts_root_dir/frontend/version.json"
the_frontend_version_artifacts_ts_file="$the_frontend_version_artifacts_root_dir/src/frontend/chart-finder-react/src/versionInfo.ts"
the_frontend_version_artifacts_dart_file="$the_frontend_version_artifacts_root_dir/src/frontend/chart-finder-flutter/lib/version_info.dart"

frontend_version_artifacts_log() {
  local i_message="$1"
  printf '[frontend-version-artifacts] %s\n' "$i_message"
}

frontend_version_artifacts_usage() {
  cat <<'USAGE'
Usage: ./scripts/frontend-version-artifacts.sh [command]

Commands:
  run        Generate frontend version artifacts (default). Uses CF_LOCAL_FRONTEND_ENV or FRONTEND_VERSION_ARTIFACTS_OPTION_STACK.
  help       Show this help message

Environment:
  CF_LOCAL_FRONTEND_ENV                Select the active stack ('react', 'flutter'); defaults to 'react' when unset.
  FRONTEND_VERSION_ARTIFACTS_OPTION_STACK
                                       Override stack detection. Set to 'react', 'flutter', or 'all' to emit both.
USAGE
}

frontend_version_artifacts_resolve_stacks() {
  local l_requested
  if [ -n "${FRONTEND_VERSION_ARTIFACTS_OPTION_STACK:-}" ]; then
    l_requested="${FRONTEND_VERSION_ARTIFACTS_OPTION_STACK}"
  else
    l_requested="${CF_LOCAL_FRONTEND_ENV:-react}"
  fi
  l_requested="$(printf '%s' "$l_requested" | tr '[:upper:]' '[:lower:]')"
  case "$l_requested" in
    ''|react)
      printf 'react\n'
      ;;
    flutter)
      printf 'flutter\n'
      ;;
    all|both)
      printf 'react flutter\n'
      ;;
    *)
      frontend_version_artifacts_log "WARN: unknown CF_LOCAL_FRONTEND_ENV='$l_requested'; defaulting to react"
      printf 'react\n'
      return 1
      ;;
  esac
  return 0
}

frontend_version_artifacts_target_path() {
  local i_stack="$1"
  case "$i_stack" in
    react)
      printf '%s\n' "$the_frontend_version_artifacts_ts_file"
      ;;
    flutter)
      printf '%s\n' "$the_frontend_version_artifacts_dart_file"
      ;;
    *)
      frontend_version_artifacts_log "ERROR: unsupported stack '$i_stack'"
      return 1
      ;;
  esac
}

frontend_version_artifacts_verify_common_prereqs() {
  if [ ! -f "$the_frontend_version_artifacts_version_file" ]; then
    frontend_version_artifacts_log "ERROR: missing $the_frontend_version_artifacts_version_file"
    return 1
  fi
  return 0
}

frontend_version_artifacts_prepare_target() {
  local i_target="$1"
  local l_target_dir
  l_target_dir="$( dirname "$i_target" )"
  if ! mkdir -p "$l_target_dir"; then
    frontend_version_artifacts_log "ERROR: unable to create directory $l_target_dir"
    return 1
  fi
  return 0
}

frontend_version_artifacts_generate_tmp() {
  local i_stack="$1"
  local i_target="$2"
  local l_tmp_file
  l_tmp_file="$(mktemp "${i_target}.XXXXXX")" || return 1
  if ! FRONTEND_VERSION_ARTIFACTS_BASE_URI="${CF_LOCAL_BASE_URI:-}" \
    FRONTEND_VERSION_ARTIFACTS_STACK="$i_stack" \
    python3 - "$the_frontend_version_artifacts_version_file" "$l_tmp_file" <<'PY'
import json
import os
import re
import sys

version_path, output_path = sys.argv[1], sys.argv[2]
stack = os.environ.get("FRONTEND_VERSION_ARTIFACTS_STACK", "react").strip().lower() or "react"
data = json.load(open(version_path, encoding="utf-8"))
base_uri = os.environ.get("FRONTEND_VERSION_ARTIFACTS_BASE_URI", "")

version = data.get("version", "") or ""
parts = version.split(".")
major = parts[0] if len(parts) > 0 else ""
minor = parts[1] if len(parts) > 1 else ""
release = parts[2] if len(parts) > 2 else ""
global_release = parts[3] if len(parts) > 3 else ""

def pad(part: str, width: int) -> str:
    if not part:
        return "".zfill(width)
    digits = "".join(ch for ch in part if ch.isdigit())
    if not digits:
        digits = part
    return digits.zfill(width)

minor_pad = pad(minor, 2) if minor else ""
release_pad = pad(release, 2) if release else ""

version_short_parts = [p for p in (major, minor, release) if p]
version_short = ".".join(version_short_parts)
version_short_numeric = "".join([
    major,
    minor_pad,
    release_pad,
])
version_full_numeric = "".join([
    major,
    minor_pad,
    release_pad,
    global_release or "",
])

company = data.get("company", "")
product = data.get("product", "")

def slugify(value: str) -> str:
    if not value:
        return ""
    lowered = value.lower()
    return re.sub(r"[^a-z0-9]+", "", lowered)

company_slug = slugify(company)
product_slug = slugify(product)

def escape_ts(value: str) -> str:
    return (value or "").replace("\\", "\\\\").replace("`", "\\`")

def escape_dart(value: str) -> str:
    return (value or "").replace("\\", "\\\\").replace("'", "\\'")

values = {
    "version": version,
    "versionMajor": major,
    "versionMinor": minor,
    "versionRelease": release,
    "versionGlobalRelease": global_release,
    "versionShort": version_short,
    "versionShortNumeric": version_short_numeric,
    "versionFullNumeric": version_full_numeric,
    "buildNumber": data.get("buildNumber", "") or "",
    "buildComment": data.get("comment", "") or "",
    "branch": data.get("branch", "") or "",
    "informationalVersion": data.get("informationalVersion", "") or "",
    "apiBaseUrl": base_uri or "",
    "companyName": company,
    "productName": product,
    "companySlug": company_slug,
    "productSlug": product_slug,
}

react_template = """// This file is auto-generated by scripts/frontend-version-artifacts.sh
// Do not edit manually.
export const VersionInfo = {{
  version: `{version}`,
  versionMajor: `{versionMajor}`,
  versionMinor: `{versionMinor}`,
  versionRelease: `{versionRelease}`,
  versionGlobalRelease: `{versionGlobalRelease}`,
  versionFullNumeric: `{versionFullNumeric}`,
  versionShort: `{versionShort}`,
  versionShortNumeric: `{versionShortNumeric}`,
  buildNumber: `{buildNumber}`,
  buildComment: `{buildComment}`,
  branch: `{branch}`,
  informationalVersion: `{informationalVersion}`,
  apiBaseUrl: `{apiBaseUrl}`,
  companyName: `{companyName}`,
  productName: `{productName}`,
  companySlug: `{companySlug}`,
  productSlug: `{productSlug}`,
}} as const;
"""

flutter_template = """// This file is auto-generated by scripts/frontend-version-artifacts.sh
// Do not edit manually.
class VersionInfo {{
  final String version;
  final String versionMajor;
  final String versionMinor;
  final String versionRelease;
  final String versionGlobalRelease;
  final String versionFullNumeric;
  final String versionShort;
  final String versionShortNumeric;
  final String buildNumber;
  final String buildComment;
  final String branch;
  final String informationalVersion;
  final String apiBaseUrl;
  final String companyName;
  final String productName;
  final String companySlug;
  final String productSlug;

  const VersionInfo({{
    required this.version,
    required this.versionMajor,
    required this.versionMinor,
    required this.versionRelease,
    required this.versionGlobalRelease,
    required this.versionFullNumeric,
    required this.versionShort,
    required this.versionShortNumeric,
    required this.buildNumber,
    required this.buildComment,
    required this.branch,
    required this.informationalVersion,
    required this.apiBaseUrl,
    required this.companyName,
    required this.productName,
    required this.companySlug,
    required this.productSlug,
  }});
}}

const versionInfo = VersionInfo(
  version: '{version}',
  versionMajor: '{versionMajor}',
  versionMinor: '{versionMinor}',
  versionRelease: '{versionRelease}',
  versionGlobalRelease: '{versionGlobalRelease}',
  versionFullNumeric: '{versionFullNumeric}',
  versionShort: '{versionShort}',
  versionShortNumeric: '{versionShortNumeric}',
  buildNumber: '{buildNumber}',
  buildComment: '{buildComment}',
  branch: '{branch}',
  informationalVersion: '{informationalVersion}',
  apiBaseUrl: '{apiBaseUrl}',
  companyName: '{companyName}',
  productName: '{productName}',
  companySlug: '{companySlug}',
  productSlug: '{productSlug}',
);
"""

if stack == "react":
    rendered = react_template.format(**{k: escape_ts(v) for k, v in values.items()})
elif stack == "flutter":
    rendered = flutter_template.format(**{k: escape_dart(v) for k, v in values.items()})
else:
    raise SystemExit(f"Unsupported stack '{stack}'")

with open(output_path, "w", encoding="utf-8") as handle:
    handle.write(rendered)
PY
  then
    rm -f "$l_tmp_file"
    frontend_version_artifacts_log "ERROR: failed to generate version artifacts for stack '$i_stack'"
    return 1
  fi

  printf '%s\n' "$l_tmp_file"
}

frontend_version_artifacts_write_if_changed() {
  local i_tmp_file="$1"
  local i_target_file="$2"
  if [ ! -f "$i_target_file" ] || ! cmp -s "$i_tmp_file" "$i_target_file"; then
    if ! mv "$i_tmp_file" "$i_target_file"; then
      frontend_version_artifacts_log "ERROR: unable to write $i_target_file"
      rm -f "$i_tmp_file"
      return 1
    fi
    frontend_version_artifacts_log "Updated $i_target_file"
  else
    rm -f "$i_tmp_file"
    frontend_version_artifacts_log "$(basename "$i_target_file") unchanged"
  fi
}

frontend_version_artifacts_process_stack() {
  local i_stack="$1"
  local l_target_path
  l_target_path="$(frontend_version_artifacts_target_path "$i_stack")" || return 1
  if ! frontend_version_artifacts_prepare_target "$l_target_path"; then
    return 1
  fi
  frontend_version_artifacts_log "Generating version artifacts for stack '$i_stack'"
  local l_tmp_file
  if ! l_tmp_file="$(frontend_version_artifacts_generate_tmp "$i_stack" "$l_target_path")"; then
    return 1
  fi
  frontend_version_artifacts_write_if_changed "$l_tmp_file" "$l_target_path"
}

frontend_version_artifacts_run() {
  if ! frontend_version_artifacts_verify_common_prereqs; then
    return 1
  fi
  local l_stacks
  if ! l_stacks="$(frontend_version_artifacts_resolve_stacks)"; then
    # Continue with whatever was returned even if we warned.
    true
  fi
  local l_status=0
  for l_stack in $l_stacks; do
    if ! frontend_version_artifacts_process_stack "$l_stack"; then
      l_status=1
    fi
  done
  return $l_status
}

frontend_version_artifacts_main() {
  local l_command="${1:-run}"
  case "$l_command" in
    run)
      frontend_version_artifacts_run
      ;;
    help|--help|-h)
      frontend_version_artifacts_usage
      ;;
    *)
      frontend_version_artifacts_log "ERROR: unknown command '$l_command'"
      frontend_version_artifacts_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" != "source-only" ]; then
  frontend_version_artifacts_main "$@"
else
  true
fi
