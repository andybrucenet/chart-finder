#!/usr/bin/env python3
"""
Ensure the generated .NET client csproj has the correct metadata.

Inputs:
    1. Path to the csproj that should be rewritten.
    2. Path to docs/about.json for authoritative metadata.

Outputs:
    Updates the csproj in place.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from xml.etree import ElementTree as ET


def ensure_prop(prop_group: ET.Element, tag: str, value: str) -> None:
    elem = prop_group.find(tag)
    if elem is None:
        elem = ET.SubElement(prop_group, tag)
    elem.text = value


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: dotnet_csproj_metadata.py <csproj> <about.json>",
            file=sys.stderr,
        )
        return 1

    csproj_path = Path(sys.argv[1])
    about_path = Path(sys.argv[2])

    tree = ET.parse(csproj_path)
    root = tree.getroot()
    prop_group = root.find("PropertyGroup")
    if prop_group is None:
        prop_group = ET.SubElement(root, "PropertyGroup")

    about = json.loads(about_path.read_text(encoding="utf-8"))

    ensure_prop(prop_group, "PackageLicenseFile", "LICENSE.txt")
    ensure_prop(prop_group, "PackageReadmeFile", "README.md")

    author = about.get("authorName")
    if author:
        ensure_prop(prop_group, "Authors", author)
        ensure_prop(prop_group, "Company", author)
    homepage = about.get("homepage")
    if homepage:
        ensure_prop(prop_group, "PackageProjectUrl", homepage)
    repo = about.get("repositoryUrl")
    if repo:
        ensure_prop(prop_group, "RepositoryUrl", repo)
    product_name = about.get("productName")
    if product_name:
        ensure_prop(prop_group, "Description", f"{product_name} API client")

    license_added = False
    readme_added = False
    for item in root.findall("ItemGroup"):
        for node in list(item):
            if node.tag == "None" and node.get("Include") == "LICENSE.txt":
                license_added = True
            if node.tag == "None" and node.get("Include") == "README.md":
                readme_added = True

    if not (license_added and readme_added):
        item_group = root.find("ItemGroup")
        if item_group is None:
            item_group = ET.SubElement(root, "ItemGroup")
        if not license_added:
            node = ET.SubElement(item_group, "None", Include="LICENSE.txt")
            node.set("Pack", "true")
            node.set("PackagePath", "")
        if not readme_added:
            node = ET.SubElement(item_group, "None", Include="README.md")
            node.set("Pack", "true")
            node.set("PackagePath", "")

    ET.indent(tree, space="  ")
    tree.write(csproj_path, encoding="utf-8", xml_declaration=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
