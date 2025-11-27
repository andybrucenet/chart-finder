#!/usr/bin/env python3
"""Update CFBundleShortVersionString and CFBundleVersion inside Info.plist."""

from __future__ import annotations

import plistlib
import sys
from pathlib import Path


def _usage() -> int:
    print(
        "Usage: frontend_ios_info_plist_update.py "
        "<plist_path> <short_version> <build_version>",
        file=sys.stderr,
    )
    return 1


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        return _usage()

    plist_path = Path(argv[1])
    short_version = argv[2]
    build_version = argv[3]

    if not plist_path.is_file():
        print(f"ERROR: Info.plist not found: {plist_path}", file=sys.stderr)
        return 2

    try:
        data = plistlib.loads(plist_path.read_bytes())
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: failed to read plist: {exc}", file=sys.stderr)
        return 3

    changed = False
    if data.get("CFBundleShortVersionString") != short_version:
        data["CFBundleShortVersionString"] = short_version
        changed = True
    if data.get("CFBundleVersion") != build_version:
        data["CFBundleVersion"] = build_version
        changed = True

    if changed:
        try:
            plistlib.dump(data, plist_path.open("wb"), sort_keys=False)
        except Exception as exc:  # noqa: BLE001
            print(f"ERROR: failed to write plist: {exc}", file=sys.stderr)
            return 4
        print("updated")
    else:
        print("unchanged")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
