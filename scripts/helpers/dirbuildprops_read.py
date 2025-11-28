#!/usr/bin/env python3
"""
Read a property value from a Directory.Build.props-style XML file.

Inputs:
    1. Path to the props XML file.
    2. Property name to read.

Output:
    Prints the value to stdout. Exits with non-zero status if missing.
"""

from __future__ import annotations

import sys
from pathlib import Path
from xml.etree import ElementTree as ET


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: dirbuildprops_read.py <path-to-props> <property-name>",
            file=sys.stderr,
        )
        return 1

    path = Path(sys.argv[1])
    prop_name = sys.argv[2]

    tree = ET.parse(path)
    root = tree.getroot()

    for elem in root.iter():
        if elem.tag.endswith(prop_name):
            value = (elem.text or "").strip()
            if value:
                print(value)
                return 0
            break

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
