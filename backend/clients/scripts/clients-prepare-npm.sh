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

  python3 - "$pkg_json" "$about_json" <<'PY'
import json, sys, pathlib
pkg_path, about_path = sys.argv[1:3]
with open(pkg_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
try:
    with open(about_path, 'r', encoding='utf-8') as fh:
        about = json.load(fh)
except FileNotFoundError:
    about = {}

def repo_url(base):
    if not base:
        return None
    url = base
    if url.endswith('.git'):
        git_url = url
    else:
        git_url = url.rstrip('/') + '.git'
    return 'git+' + git_url

product = about.get('productName') or 'Chart Finder'
author_name = about.get('authorName') or 'Chart Finder'
author_email = about.get('authorEmail') or ''
homepage = about.get('homepage') or about.get('repositoryUrl')
support = about.get('supportUrl') or about.get('repositoryUrl')
license_value = about.get('license') or data.get('license') or 'UNLICENSED'
repo = repo_url(about.get('repositoryUrl'))

data['description'] = f"{product} API client"
if author_email:
    data['author'] = f"{author_name} <{author_email}>"
else:
    data['author'] = author_name
if homepage:
    data['homepage'] = homepage
if support:
    data.setdefault('bugs', {})['url'] = support
if repo:
    data['repository'] = {'type': 'git', 'url': repo}
if license_value:
    data['license'] = license_value

keywords = set(data.get('keywords') or [])
keywords.update({'chart-finder', 'sdk', 'openapi'})
data['keywords'] = sorted(keywords)

with open(pkg_path, 'w', encoding='utf-8') as fh:
    json.dump(data, fh, indent=2)
    fh.write('\n')
PY
}

if [ "${1:-run}" = "source-only" ]; then
  clients_prepare_npm_main "source-only"
else
  clients_prepare_npm_main "$@"
fi
