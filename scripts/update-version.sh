#!/bin/bash
# update-version.sh
#
# Usage: ./scripts/update-version.sh backend
# Updates version metadata for the specified project area.

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_update_version_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_update_version_root_dir="$( realpath "$the_update_version_script_dir"/.. )"
source "$the_update_version_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_update_version_root_dir" || exit $?

# now the variables
set -euo pipefail
script_dir="$the_update_version_script_dir"
repo_root="$the_update_version_root_dir"
frontend_version_file="$repo_root/frontend/version.json"
frontend_version_artifacts_script="$repo_root/scripts/frontend-version-artifacts.sh"

print_usage() {
  cat <<'USAGE'
Usage: ./scripts/update-version.sh <target>

Targets:
  backend       Interactive backend (.NET) version update.
  backend-batch Non-interactive backend update (env vars must be provided).
  frontend      Interactive frontend (mobile) version update.
  frontend-batch Non-interactive frontend update (env vars must be provided).
USAGE
}

get_prop() {
  local file="$1"
  local prop="$2"
  sed -n "s|.*<${prop}[^>]*>\\(.*\\)</${prop}>.*|\\1|p" "$file" | head -n1
}

update_props() {
  local file="$1"
  local version="$2"
  local branch="$3"
  local comment="$4"
  local build_number="$5"
  local informational="$6"

  NEW_ChartFinderVersion="$version" \
  NEW_ChartFinderBuildBranch="$branch" \
  NEW_ChartFinderBuildComment="$comment" \
  NEW_ChartFinderBuildNumber="$build_number" \
  NEW_ChartFinderInformationalVersion="$informational" \
  python3 - "$file" <<'PY'
import os
import re
import sys

path = sys.argv[1]
data = open(path, encoding="utf-8").read()

def replace(tag: str, value: str) -> None:
    global data
    pattern = rf"(<{tag}[^>]*>)(.*?)(</{tag}>)"
    data, count = re.subn(pattern, lambda m: f"{m.group(1)}{value}{m.group(3)}", data, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"Failed to update {tag} in {path}")

replace("ChartFinderVersion", os.environ["NEW_ChartFinderVersion"])
replace("ChartFinderBackendBuildBranch", os.environ["NEW_ChartFinderBuildBranch"])
replace("ChartFinderBackendBuildComment", os.environ["NEW_ChartFinderBuildComment"])
replace("ChartFinderBackendBuildNumber", os.environ["NEW_ChartFinderBuildNumber"])
replace("ChartFinderBackendInformationalVersion", os.environ["NEW_ChartFinderInformationalVersion"])

with open(path, "w", encoding="utf-8") as handle:
    handle.write(data)
PY
}

frontend_get_field() {
  local key="$1"
  if [[ ! -f "$frontend_version_file" ]]; then
    echo ""
    return
  fi

  python3 - "$frontend_version_file" "$key" <<'PY'
import json
import sys
path, key = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
print(data.get(key, ""))
PY
}

run_frontend_version_artifacts() {
  if [[ ! -x "$frontend_version_artifacts_script" ]]; then
    echo "ERROR: missing executable $frontend_version_artifacts_script" >&2
    return 1
  fi
  if ! "$frontend_version_artifacts_script" run; then
    echo "ERROR: frontend-version-artifacts script failed" >&2
    return 1
  fi
}

write_frontend_metadata() {
  mkdir -p "$(dirname "$frontend_version_file")"
  local tmp_file
  tmp_file="$(mktemp "${frontend_version_file}.XXXXXX")"
  NEW_FRONTEND_VERSION="$1" \
  NEW_FRONTEND_BRANCH="$2" \
  NEW_FRONTEND_COMMENT="$3" \
  NEW_FRONTEND_BUILD_NUMBER="$4" \
  NEW_FRONTEND_INFORMATIONAL="$5" \
  python3 - "$tmp_file" <<'PY'
import json
import os
import sys
path = sys.argv[1]
data = {
    "version": os.environ["NEW_FRONTEND_VERSION"],
    "branch": os.environ["NEW_FRONTEND_BRANCH"],
    "comment": os.environ["NEW_FRONTEND_COMMENT"],
    "buildNumber": os.environ["NEW_FRONTEND_BUILD_NUMBER"],
    "informationalVersion": os.environ["NEW_FRONTEND_INFORMATIONAL"],
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")
PY

  if [[ ! -f "$frontend_version_file" ]] || ! cmp -s "$tmp_file" "$frontend_version_file"; then
    mv "$tmp_file" "$frontend_version_file"
  else
    rm "$tmp_file"
  fi
}

detect_branch() {
  local branch
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ "$branch" == "HEAD" || -z "$branch" ]]; then
      branch="$(git rev-parse --short HEAD 2>/dev/null || echo "")"
    fi
  else
    branch=""
  fi
  echo "$branch"
}

update_backend() {
  local props_file="$repo_root/Directory.Build.props"

  if [[ ! -f "$props_file" ]]; then
    echo "ERROR: Cannot find $props_file" >&2
    exit 1
  fi

  local current_version current_branch current_comment current_build_number
  current_version="$(get_prop "$props_file" "ChartFinderVersion")"
  current_branch="$(get_prop "$props_file" "ChartFinderBackendBuildBranch")"
  current_comment="$(get_prop "$props_file" "ChartFinderBackendBuildComment")"
  current_build_number="$(get_prop "$props_file" "ChartFinderBackendBuildNumber")"

  printf "Current backend version       : %s\n" "$current_version"
  printf "Current backend build branch  : %s\n" "$current_branch"
  printf "Current backend build comment : %s\n" "$current_comment"
  printf "Current backend build number  : %s\n\n" "$current_build_number"

  local new_version
  if [[ -n "${CHARTFINDER_BACKEND_VERSION:-}" ]]; then
    new_version="$CHARTFINDER_BACKEND_VERSION"
    echo "Using CHARTFINDER_BACKEND_VERSION=$new_version"
  else
    local default_year default_month default_month_release default_global_build
    default_year="$(date -u +"%Y")"
    default_month="$(date -u +"%m")"
    default_month_release="10"
    default_global_build="10000"
    if [[ -n "$current_version" ]]; then
      IFS='.' read -r _ _ cv_month_release cv_global_build <<<"$current_version"
      if [[ -n "$cv_month_release" && "$cv_month_release" -ge 10 ]]; then
        default_month_release="$cv_month_release"
      fi
      if [[ -n "$cv_global_build" && "$cv_global_build" -ge 10000 ]]; then
        default_global_build="$cv_global_build"
      fi
    fi

    read -r -p "Year [${default_year}]: " new_year
    new_year="${new_year:-$default_year}"
    read -r -p "Month [${default_month}]: " new_month
    new_month="${new_month:-$default_month}"
    read -r -p "Month release index (>=10) [${default_month_release}]: " new_month_release
    new_month_release="${new_month_release:-$default_month_release}"
    read -r -p "Global build number (>=10000) [${default_global_build}]: " new_global_build
    new_global_build="${new_global_build:-$default_global_build}"

    if [[ "$new_year" =~ ^[0-9]+$ ]]; then
      printf -v new_year "%04d" "$new_year"
    fi
    if [[ "$new_month" =~ ^[0-9]+$ ]]; then
      printf -v new_month "%02d" "$new_month"
    fi
    new_version="${new_year}.${new_month}.${new_month_release}.${new_global_build}"
  fi

  local new_branch
  if [[ -n "${CHARTFINDER_BACKEND_BRANCH:-}" ]]; then
    new_branch="$CHARTFINDER_BACKEND_BRANCH"
    echo "Using CHARTFINDER_BACKEND_BRANCH=$new_branch"
  else
    new_branch="$(detect_branch)"
    if [[ -z "$new_branch" ]]; then
      new_branch="$current_branch"
    fi
    echo "Detected branch: ${new_branch}"
  fi

  local new_comment="$current_comment"
  if [[ -n "${CHARTFINDER_BACKEND_COMMENT:-}" ]]; then
    new_comment="$CHARTFINDER_BACKEND_COMMENT"
    echo "Using CHARTFINDER_BACKEND_COMMENT=$new_comment"
  else
    read -r -p "Build comment [${current_comment}]: " new_comment_input
    if [[ -n "$new_comment_input" ]]; then
      new_comment="$new_comment_input"
    fi
  fi

  local default_build_number prompt_build_number
  default_build_number="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  prompt_build_number="$default_build_number"

  local new_build_number
  if [[ -n "${CHARTFINDER_BACKEND_BUILD_NUMBER:-}" ]]; then
    new_build_number="$CHARTFINDER_BACKEND_BUILD_NUMBER"
    echo "Using CHARTFINDER_BACKEND_BUILD_NUMBER=$new_build_number"
  else
    read -r -p "Build number (UTC timestamp) [${prompt_build_number}]: " new_build_number_input
    if [[ -z "$new_build_number_input" ]]; then
      new_build_number="$default_build_number"
    else
      new_build_number="$new_build_number_input"
    fi
  fi

  local informational="$new_version"
  if [[ -n "$new_branch" ]]; then
    informational="${informational}+${new_branch}"
    if [[ -n "$new_comment" ]]; then
      informational="${informational}.${new_comment}"
    fi
  fi

  update_props "$props_file" "$new_version" "$new_branch" "$new_comment" "$new_build_number" "$informational"

  echo ""
  echo "Updated backend version metadata in Directory.Build.props"
}

update_frontend() {
  local current_version current_branch current_comment current_build_number
  current_version="$(frontend_get_field "version")"
  current_branch="$(frontend_get_field "branch")"
  current_comment="$(frontend_get_field "comment")"
  current_build_number="$(frontend_get_field "buildNumber")"

  printf "Current frontend version       : %s\n" "${current_version:-<none>}"
  printf "Current frontend build branch  : %s\n" "${current_branch:-<none>}"
  printf "Current frontend build comment : %s\n" "${current_comment:-<none>}"
  printf "Current frontend build number  : %s\n\n" "${current_build_number:-<none>}"

  local new_version
  if [[ -n "${CHARTFINDER_FRONTEND_VERSION:-}" ]]; then
    new_version="$CHARTFINDER_FRONTEND_VERSION"
    echo "Using CHARTFINDER_FRONTEND_VERSION=$new_version"
  else
    local default_year default_month default_month_release default_global_build
    default_year="$(date -u +"%Y")"
    default_month="$(date -u +"%m")"
    default_month_release="10"
    default_global_build="10000"
    if [[ -n "$current_version" ]]; then
      IFS='.' read -r _ _ cv_month_release cv_global_build <<<"$current_version"
      if [[ -n "${cv_month_release:-}" && "$cv_month_release" -ge 10 ]]; then
        default_month_release="$cv_month_release"
      fi
      if [[ -n "${cv_global_build:-}" && "$cv_global_build" -ge 10000 ]]; then
        default_global_build="$cv_global_build"
      fi
    fi

    read -r -p "Year [${default_year}]: " new_year
    new_year="${new_year:-$default_year}"
    read -r -p "Month [${default_month}]: " new_month
    new_month="${new_month:-$default_month}"
    read -r -p "Month release index (>=10) [${default_month_release}]: " new_month_release
    new_month_release="${new_month_release:-$default_month_release}"
    read -r -p "Global build number (>=10000) [${default_global_build}]: " new_global_build
    new_global_build="${new_global_build:-$default_global_build}"

    if [[ "$new_year" =~ ^[0-9]+$ ]]; then
      printf -v new_year "%04d" "$new_year"
    fi
    if [[ "$new_month" =~ ^[0-9]+$ ]]; then
      printf -v new_month "%02d" "$new_month"
    fi
    new_version="${new_year}.${new_month}.${new_month_release}.${new_global_build}"
  fi

  local new_branch
  if [[ -n "${CHARTFINDER_FRONTEND_BRANCH:-}" ]]; then
    new_branch="$CHARTFINDER_FRONTEND_BRANCH"
    echo "Using CHARTFINDER_FRONTEND_BRANCH=$new_branch"
  else
    new_branch="$(detect_branch)"
    if [[ -z "$new_branch" ]]; then
      new_branch="$current_branch"
    fi
    echo "Detected branch: ${new_branch}"
  fi

  local new_comment="$current_comment"
  if [[ -n "${CHARTFINDER_FRONTEND_COMMENT:-}" ]]; then
    new_comment="$CHARTFINDER_FRONTEND_COMMENT"
    echo "Using CHARTFINDER_FRONTEND_COMMENT=$new_comment"
  else
    read -r -p "Build comment [${current_comment:-}]: " new_comment_input
    if [[ -n "$new_comment_input" ]]; then
      new_comment="$new_comment_input"
    fi
  fi

  local default_build_number prompt_build_number
  default_build_number="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  prompt_build_number="$default_build_number"

  local new_build_number
  if [[ -n "${CHARTFINDER_FRONTEND_BUILD_NUMBER:-}" ]]; then
    new_build_number="$CHARTFINDER_FRONTEND_BUILD_NUMBER"
    echo "Using CHARTFINDER_FRONTEND_BUILD_NUMBER=$new_build_number"
  else
    read -r -p "Build number (UTC timestamp) [${prompt_build_number}]: " new_build_number_input
    if [[ -z "$new_build_number_input" ]]; then
      new_build_number="$default_build_number"
    else
      new_build_number="$new_build_number_input"
    fi
  fi

  local informational="$new_version"
  if [[ -n "$new_branch" ]]; then
    informational="${informational}+${new_branch}"
    if [[ -n "$new_comment" ]]; then
      informational="${informational}.${new_comment}"
    fi
  fi

  write_frontend_metadata "$new_version" "${new_branch:-}" "${new_comment:-}" "$new_build_number" "$informational"
  run_frontend_version_artifacts || exit $?

  echo ""
  echo "Updated frontend version metadata in $frontend_version_file"
}

main() {
  if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
  fi

  case "$1" in
    backend)
      update_backend
      ;;
    backend-batch)
      : "${CHARTFINDER_BACKEND_BUILD_NUMBER:?CHARTFINDER_BACKEND_BUILD_NUMBER required}"
      python3 - "$repo_root/Directory.Build.props" "$CHARTFINDER_BACKEND_BUILD_NUMBER" <<'PY'
import sys
from xml.etree import ElementTree as ET

path, build_number = sys.argv[1], sys.argv[2]
tree = ET.parse(path)
root = tree.getroot()
elem = root.find('.//ChartFinderBackendBuildNumber')
if elem is None:
    raise SystemExit(f"ChartFinderBackendBuildNumber missing in {path}")
elem.text = build_number
tree.write(path, encoding='utf-8', xml_declaration=False)
PY
      echo "Updated ChartFinderBackendBuildNumber in Directory.Build.props (batch mode)"
      ;;
    frontend)
      update_frontend
      ;;
    frontend-batch)
      : "${CHARTFINDER_FRONTEND_BUILD_NUMBER:?CHARTFINDER_FRONTEND_BUILD_NUMBER required}"
      local current_version current_branch current_comment
      current_version="$(frontend_get_field "version")"
      current_branch="$(frontend_get_field "branch")"
      current_comment="$(frontend_get_field "comment")"
      local informational="$current_version"
      if [[ -n "${current_branch:-}" ]]; then
        informational="${informational}+${current_branch}"
        if [[ -n "${current_comment:-}" ]]; then
          informational="${informational}.${current_comment}"
        fi
      fi
    write_frontend_metadata "${current_version:-}" "${current_branch:-}" "${current_comment:-}" "$CHARTFINDER_FRONTEND_BUILD_NUMBER" "$informational"
    run_frontend_version_artifacts || exit $?
    echo "Updated frontend build number in $frontend_version_file (batch mode)"
      ;;
    help|-h|--help)
      print_usage
      ;;
    *)
      echo "Unsupported target: $1" >&2
      print_usage
      exit 1
      ;;
  esac
}

main "$@"
