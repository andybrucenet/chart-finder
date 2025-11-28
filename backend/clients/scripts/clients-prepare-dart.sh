#!/bin/bash
# clients-prepare-dart.sh, ABr
# Ensure the generated Dart client has required packaging metadata/files.

clients_prepare_dart_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir dart_dir license_src license_dst readme_src readme_path changelog_src changelog_path about_json
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return 1
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return 1
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return 1
  source "$root_dir/scripts/lcl-os-checks.sh" 'source-only' || return 1
  source "$root_dir/scripts/cf-env-vars.sh" 'source-only' || return 1
  local product_name="${CF_GLOBAL_PRODUCT:?CF_GLOBAL_PRODUCT missing}"
  dart_dir="$root_dir/.local/backend/clients/dart"
  license_src="$root_dir/NOTICE.txt"
  license_dst="$dart_dir/LICENSE"
  readme_src="$root_dir/src/backend/ChartFinder.Api/README-api.md"
  readme_path="$dart_dir/README.md"
  changelog_src="$root_dir/src/backend/ChartFinder.Api/CHANGELOG.md"
  changelog_path="$dart_dir/CHANGELOG.md"
  about_json="$root_dir/docs/about.json"

  if [ ! -d "$dart_dir" ] || [ ! -f "$dart_dir/pubspec.yaml" ]; then
    echo "[clients] prepare-dart: missing project at $dart_dir" >&2
    return 1
  fi

  if [ -f "$license_src" ]; then
    cp "$license_src" "$license_dst"
  else
    cat >"$license_dst" <<LICENSE
© 2025 ${product_name}. All rights reserved.
LICENSE
  fi

  if [ -f "$readme_src" ]; then
    cp "$readme_src" "$readme_path"
  elif [ ! -f "$readme_path" ]; then
    cat >"$readme_path" <<README
# ${product_name} Dart Client

Auto-generated Flutter/Dart SDK for the ${product_name} API.
README
  fi

  local pubspec_helper="$clients_dir/scripts/helpers/dart_pubspec_update.py"
  if ! python3 "$pubspec_helper" "$dart_dir/pubspec.yaml" "$about_json"; then
    echo "[clients] prepare-dart: failed to update pubspec metadata" >&2
    return 1
  fi

  # scrub known analyzer warnings before publish
  local utils_api_path="$dart_dir/lib/src/api/utils_api.dart"
  if [ -f "$utils_api_path" ]; then
    local utils_helper="$clients_dir/scripts/helpers/dart_utils_api_cleanup.py"
    if ! python3 "$utils_helper" "$utils_api_path"; then
      echo "[clients] prepare-dart: failed to scrub $utils_api_path" >&2
      return 1
    fi
  fi

  local api_path="$dart_dir/lib/src/api.dart"
  if [ -f "$api_path" ]; then
    local api_helper="$clients_dir/scripts/helpers/dart_api_cleanup.py"
    if ! python3 "$api_helper" "$api_path"; then
      echo "[clients] prepare-dart: failed to scrub $api_path" >&2
      return 1
    fi
  fi

  # ensure CHANGELOG.md exists with entry for current version
  if [ -f "$changelog_src" ]; then
    cp "$changelog_src" "$changelog_path"
  else
    cat >"$changelog_path" <<'EOF'
# Changelog
EOF
  fi

  local pub_version
  if ! pub_version="$(lcl_version_normalize_pub "${CF_BACKEND_VERSION_SHORT}" "${CF_BACKEND_BUILD_NUMBER}")"; then
    echo "[clients] prepare-dart: unable to compute pub version" >&2
    return 1
  fi

  local changelog_helper="$clients_dir/scripts/helpers/dart_changelog_update.py"
  if ! python3 "$changelog_helper" "$changelog_path" "$pub_version" "$product_name"; then
    echo "[clients] prepare-dart: failed to update changelog" >&2
    return 1
  fi

  # ensure .pubignore exists so pub.dev doesn't treat pubspec/LICENSE as ignored
  cat >"$dart_dir/.pubignore" <<'PUBIGNORE'
# Override repo-level ignores but keep required files.
!.pubignore
!pubspec.yaml
!README.md
!CHANGELOG.md
!LICENSE
PUBIGNORE
}

if [ "${1:-run}" = "source-only" ]; then
  clients_prepare_dart_main "source-only"
else
  clients_prepare_dart_main "$@"
fi
