#!/usr/bin/env python3
"""
Update pubspec.yaml metadata based on docs/about.json.

Inputs:
    1. Path to pubspec.yaml.
    2. Path to docs/about.json.

Output:
    Rewrites pubspec.yaml in place with homepage/repository/issue tracker entries.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: dart_pubspec_update.py <pubspec.yaml> <about.json>",
            file=sys.stderr,
        )
        return 1

    pubspec_path = Path(sys.argv[1])
    about_path = Path(sys.argv[2])

    lines = pubspec_path.read_text(encoding="utf-8").splitlines()
    about = json.loads(about_path.read_text(encoding="utf-8"))

    replacements: list[tuple[str, str]] = []
    if about.get("homepage"):
        replacements.append(("homepage:", f"homepage: {about['homepage']}"))
    if about.get("repositoryUrl"):
        replacements.append(("repository:", f"repository: {about['repositoryUrl']}"))
    if about.get("supportUrl"):
        replacements.append(("issue_tracker:", f"issue_tracker: {about['supportUrl']}"))

    updated: list[str] = []
    seen_keys: set[str] = set()
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

    pubspec_path.write_text("\n".join(updated) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
