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
    cat >"$license_dst" <<'LICENSE'
© 2025 Chart Finder. All rights reserved.
LICENSE
  fi

  if [ -f "$readme_src" ]; then
    cp "$readme_src" "$readme_path"
  elif [ ! -f "$readme_path" ]; then
    cat >"$readme_path" <<'README'
# Chart Finder Dart Client

Auto-generated Flutter/Dart SDK for the Chart Finder API.
README
  fi

  python3 - <<'PY' "$dart_dir/pubspec.yaml" "$about_json"
import sys, json
from pathlib import Path

pubspec_path, about_path = sys.argv[1:3]
pubspec = Path(pubspec_path)
lines = pubspec.read_text(encoding='utf-8').splitlines()

about = {}
if Path(about_path).exists():
    with open(about_path, 'r', encoding='utf-8') as fh:
        about = json.load(fh)

replacements = []
if about.get('homepage'):
    replacements.append(('homepage:', f"homepage: {about['homepage']}"))
if about.get('repositoryUrl'):
    replacements.append(('repository:', f"repository: {about['repositoryUrl']}"))
if about.get('supportUrl'):
    replacements.append(('issue_tracker:', f"issue_tracker: {about['supportUrl']}"))

updated = []
seen_keys = set()
for line in lines:
    stripped = line.strip()
    replaced = False
    for key, value in replacements:
        if stripped.startswith(key):
            updated.append(value)
            seen_keys.add(key)
            replaced = True
            break
    if not replaced:
        updated.append(line)

for key, value in replacements:
    if key not in seen_keys:
        updated.append(value)

pubspec.write_text("\n".join(updated) + "\n", encoding='utf-8')
PY

  # scrub known analyzer warnings before publish
  local utils_api_path="$dart_dir/lib/src/api/utils_api.dart"
  if [ -f "$utils_api_path" ]; then
    python3 - "$utils_api_path" <<'PY'
import sys, pathlib, re
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = re.sub(r"import 'package:built_value/serializer\.dart';\n", "", text)
text = re.sub(r"\n\s*final\s+Serializers\s+_serializers;\n", "\n", text)
text = re.sub(r"const\s+UtilsApi\(\s*this\._dio\s*,\s*this\._serializers\s*\);", "const UtilsApi(this._dio);", text)
text = re.sub(r"const\s+UtilsApi\(\s*this\._dio\s*\);", "const UtilsApi(this._dio);", text)
text = re.sub(r"\s*,\s*this\._serializers", "", text)
text = re.sub(r"import 'package:built_value/json_object\.dart';\n", "", text)
path.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
PY
  fi

  local api_path="$dart_dir/lib/src/api.dart"
  if [ -f "$api_path" ]; then
    python3 - "$api_path" <<'PY'
import sys, pathlib, re
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = re.sub(r"import 'package:built_value/serializer\.dart';\n", "", text)
text = re.sub(r"import 'package:chart_finder_client/src/serializers\.dart';\n", "", text)
text = re.sub(r"\n\s*final\s+Serializers\s+serializers;\n", "\n", text)
text = re.sub(r",\s*Serializers\?\s*serializers", "", text)
text = re.sub(r"this\.serializers\s*=\s*serializers\s*\?\?\s*standardSerializers,\s*", "", text)
text = re.sub(r"UtilsApi\(\s*dio\s*,\s*serializers\s*\)", "UtilsApi(dio)", text)
path.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
PY
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

  python3 - "$changelog_path" "$pub_version" <<'PY'
import sys, pathlib
path = pathlib.Path(sys.argv[1])
version = sys.argv[2]
lines = path.read_text(encoding="utf-8").splitlines()
entry = f"## {version}"
if entry not in lines:
    if lines and lines[-1].strip():
        lines.append("")
    lines.append(entry)
    lines.append("- Auto-generated client for the Chart Finder API.")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

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
