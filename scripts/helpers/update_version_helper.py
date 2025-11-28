#!/usr/bin/env python3
"""
Helper utilities for scripts/update-version.sh.

Subcommands:
  about-get <about.json> <key>
  update-backend-props <props-file> <version> <branch> <comment> <build-number> <informational>
  frontend-get-field <version.json> <key>
  write-frontend-metadata <version.json> <version> <branch> <comment> <build-number> <informational> <company> <product>
  set-msbuild-property <props-file> <tag> <value>
  update-frontend-product <version.json> <product>
  hash-string <value>
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from xml.etree import ElementTree as ET


def about_get(args: argparse.Namespace) -> int:
    data = json.loads(Path(args.about_json).read_text(encoding="utf-8"))
    value = data.get(args.key, "")
    if isinstance(value, str):
        value = value.strip()
    print(value)
    return 0


def update_backend_props(args: argparse.Namespace) -> int:
    path = Path(args.props_file)
    tree = ET.parse(path)
    root = tree.getroot()

    def replace(tag: str, value: str) -> None:
        pattern = f".//{tag}"
        elem = root.find(pattern)
        if elem is None:
            raise SystemExit(f"Missing <{tag}> in {path}")
        elem.text = value

    replace("ChartFinderVersion", args.version)
    replace("ChartFinderBackendBuildBranch", args.branch)
    replace("ChartFinderBackendBuildComment", args.comment)
    replace("ChartFinderBackendBuildNumber", args.build_number)
    replace("ChartFinderBackendInformationalVersion", args.informational)

    tree.write(path, encoding="utf-8", xml_declaration=False)
    return 0


def frontend_get_field(args: argparse.Namespace) -> int:
    data = json.loads(Path(args.version_json).read_text(encoding="utf-8"))
    print(data.get(args.key, ""))
    return 0


def write_frontend_metadata(args: argparse.Namespace) -> int:
    payload = {
        "version": args.version,
        "branch": args.branch,
        "comment": args.comment,
        "buildNumber": args.build_number,
        "informationalVersion": args.informational,
        "company": args.company,
        "product": args.product,
    }
    path = Path(args.version_json)
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    tmp_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    tmp_path.replace(path)
    return 0


def set_msbuild_property(args: argparse.Namespace) -> int:
    path = Path(args.props_file)
    tree = ET.parse(path)
    root = tree.getroot()
    target = None
    for elem in root.iter():
        if elem.tag.endswith(args.tag):
            target = elem
            break
    if target is None:
        print(f"ERROR: Missing <{args.tag}> in {path}", file=sys.stderr)
        return 2
    if target.text == args.value:
        return 0
    target.text = args.value
    tree.write(path, encoding="utf-8", xml_declaration=False)
    return 0


def update_frontend_product(args: argparse.Namespace) -> int:
    path = Path(args.version_json)
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("product") == args.product:
        return 0
    data["product"] = args.product
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    tmp_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    tmp_path.replace(path)
    return 0


def hash_string(args: argparse.Namespace) -> int:
    print(hashlib.sha256(args.value.encode("utf-8")).hexdigest())
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="update-version helper utilities")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("about-get")
    p.add_argument("about_json")
    p.add_argument("key")
    p.set_defaults(func=about_get)

    p = sub.add_parser("update-backend-props")
    p.add_argument("props_file")
    p.add_argument("version")
    p.add_argument("branch")
    p.add_argument("comment")
    p.add_argument("build_number")
    p.add_argument("informational")
    p.set_defaults(func=update_backend_props)

    p = sub.add_parser("frontend-get-field")
    p.add_argument("version_json")
    p.add_argument("key")
    p.set_defaults(func=frontend_get_field)

    p = sub.add_parser("write-frontend-metadata")
    p.add_argument("version_json")
    p.add_argument("version")
    p.add_argument("branch")
    p.add_argument("comment")
    p.add_argument("build_number")
    p.add_argument("informational")
    p.add_argument("company")
    p.add_argument("product")
    p.set_defaults(func=write_frontend_metadata)

    p = sub.add_parser("set-msbuild-property")
    p.add_argument("props_file")
    p.add_argument("tag")
    p.add_argument("value")
    p.set_defaults(func=set_msbuild_property)

    p = sub.add_parser("update-frontend-product")
    p.add_argument("version_json")
    p.add_argument("product")
    p.set_defaults(func=update_frontend_product)

    p = sub.add_parser("hash-string")
    p.add_argument("value")
    p.set_defaults(func=hash_string)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
