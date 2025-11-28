#!/usr/bin/env python3
"""
Augment an OpenAPI document with backend version metadata.

Inputs:
    1. Source OpenAPI JSON path.
    2. Destination path for the updated document.
Environment:
    CF_BACKEND_VERSION_FULL, CF_BACKEND_BUILD_NUMBER
Outputs:
    Writes the updated JSON to the destination path.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: backend_openapi_metadata.py <source-json> <dest-json>",
            file=sys.stderr,
        )
        return 1

    source_path = Path(sys.argv[1])
    dest_path = Path(sys.argv[2])

    data = json.loads(source_path.read_text(encoding="utf-8"))
    info = data.setdefault("info", {})
    info["x-chartfinder-backend-version"] = os.environ.get("CF_BACKEND_VERSION_FULL", "")
    info["x-chartfinder-backend-build-number"] = os.environ.get("CF_BACKEND_BUILD_NUMBER", "")

    dest_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
