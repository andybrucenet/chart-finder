#!/bin/bash
# clients-prepare-dotnet.sh, ABr
# Ensure the generated .NET client has required packaging metadata/files.

clients_prepare_dotnet_main() {
  local i_mode="${1:-run}"
  shift || true
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  local script_dir clients_dir root_dir project_dir csproj_path license_src license_dst readme_path about_json
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || return 1
  clients_dir="$( cd "$script_dir/.." >/dev/null 2>&1 && pwd )" || return 1
  root_dir="$( cd "$clients_dir/../.." >/dev/null 2>&1 && pwd )" || return 1
  project_dir="$root_dir/.local/backend/clients/dotnet/src/ChartFinder.Client"
  csproj_path="$project_dir/ChartFinder.Client.csproj"
  readme_path="$project_dir/README.md"
  license_src="$root_dir/NOTICE.txt"
  license_dst="$project_dir/LICENSE.txt"
  about_json="$root_dir/docs/about.json"

  if [ ! -d "$project_dir" ] || [ ! -f "$csproj_path" ]; then
    echo "[clients] prepare-dotnet: missing project at $project_dir" >&2
    return 1
  fi

  # Ensure license file exists by copying NOTICE.txt (preferred) or creating a placeholder.
  if [ -f "$license_src" ]; then
    cp "$license_src" "$license_dst"
  else
    cat >"$license_dst" <<'LICENSE'
© 2025 Chart Finder. All rights reserved.
LICENSE
  fi

  if [ ! -f "$readme_path" ]; then
    cat >"$readme_path" <<'README'
# Chart Finder Client

Auto-generated SDK for the Chart Finder API.
README
  fi

  python3 - "$csproj_path" "$about_json" <<'PY'
import sys, json
from xml.etree import ElementTree as ET

csproj, about_path = sys.argv[1:3]
tree = ET.parse(csproj)
root = tree.getroot()

prop_group = root.find('PropertyGroup')
if prop_group is None:
    prop_group = ET.SubElement(root, 'PropertyGroup')

about = {}
try:
    with open(about_path, 'r', encoding='utf-8') as fh:
        about = json.load(fh)
except FileNotFoundError:
    about = {}

def ensure_prop(tag, value):
    elem = prop_group.find(tag)
    if elem is None:
        elem = ET.SubElement(prop_group, tag)
    elem.text = value

ensure_prop('PackageLicenseFile', 'LICENSE.txt')
ensure_prop('PackageReadmeFile', 'README.md')

if about.get('authorName'):
    ensure_prop('Authors', about['authorName'])
    ensure_prop('Company', about['authorName'])
if about.get('homepage'):
    ensure_prop('PackageProjectUrl', about['homepage'])
if about.get('repositoryUrl'):
    ensure_prop('RepositoryUrl', about['repositoryUrl'])
if about.get('productName'):
    ensure_prop('Description', f"{about['productName']} API client")

items = root.findall('ItemGroup')
license_added = False
readme_added = False
for item in items:
    for node in list(item):
        if node.tag == 'None' and node.get('Include') == 'LICENSE.txt':
            license_added = True
        if node.tag == 'None' and node.get('Include') == 'README.md':
            readme_added = True

if not license_added or not readme_added:
    item_group = None
    for ig in root.findall('ItemGroup'):
        item_group = ig
        break
    if item_group is None:
        item_group = ET.SubElement(root, 'ItemGroup')
    if not license_added:
        node = ET.SubElement(item_group, 'None', Include='LICENSE.txt')
        node.set('Pack', 'true')
        node.set('PackagePath', '')
    if not readme_added:
        node = ET.SubElement(item_group, 'None', Include='README.md')
        node.set('Pack', 'true')
        node.set('PackagePath', '')

ET.indent(tree, space="  ")
tree.write(csproj, encoding='utf-8', xml_declaration=False)
PY
}

if [ "${1:-run}" = "source-only" ]; then
  clients_prepare_dotnet_main "source-only"
else
  clients_prepare_dotnet_main "$@"
fi
