#!/usr/bin/env python3
"""
Append a changelog entry for the generated Dart client if it is missing.

Inputs:
    1. Path to CHANGELOG.md.
    2. Pub version string.
    3. Product name.

Output:
    Rewrites the changelog in place.
"""

from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "Usage: dart_changelog_update.py <changelog.md> <version> <product-name>",
            file=sys.stderr,
        )
        return 1

    path = Path(sys.argv[1])
    version = sys.argv[2]
    product = sys.argv[3]
    lines = path.read_text(encoding="utf-8").splitlines()

    entry = f"## {version}"
    if entry not in lines:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append(entry)
        lines.append(f"- Auto-generated client for the {product} API.")
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
