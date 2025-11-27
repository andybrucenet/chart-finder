#!/usr/bin/env python3
"""Update android:versionCode and android:versionName inside AndroidManifest.xml."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def _usage() -> int:
    print(
        "Usage: frontend_android_manifest_version_update.py "
        "<manifest_path> <version_code> <version_name>",
        file=sys.stderr,
    )
    return 1


def _upsert_attribute(contents: str, attr: str, value: str) -> str:
    pattern = rf'android:{attr}="[^"]*"'
    if re.search(pattern, contents):
        return re.sub(pattern, f'android:{attr}="{value}"', contents, count=1)
    opener = re.search(r"<manifest\b[^>]*?>", contents, flags=re.DOTALL)
    if not opener:
        raise RuntimeError("Opening <manifest> tag not found")
    tag = opener.group(0)
    updated_tag = tag[:-1].rstrip() + f' android:{attr}="{value}">'
    return contents[: opener.start()] + updated_tag + contents[opener.end() :]


def _update_manifest(manifest_path: Path, version_code: str, version_name: str) -> bool:
    contents = manifest_path.read_text(encoding="utf-8")
    updated = contents
    updated = _upsert_attribute(updated, "versionCode", version_code)
    updated = _upsert_attribute(updated, "versionName", version_name)

    if updated != contents:
        manifest_path.write_text(updated, encoding="utf-8")
        return True
    return False


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        return _usage()

    manifest = Path(argv[1])
    version_code = argv[2]
    version_name = argv[3]

    if not manifest.is_file():
        print(f"ERROR: manifest not found: {manifest}", file=sys.stderr)
        return 2

    try:
        changed = _update_manifest(manifest, version_code, version_name)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: failed to update manifest: {exc}", file=sys.stderr)
        return 3

    print("updated" if changed else "unchanged")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
