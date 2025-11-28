#!/usr/bin/env python3
"""
Remove unused serializer artifacts from lib/src/api/utils_api.dart.

Input:
    1. Path to utils_api.dart.

Output:
    Rewrites the file in place.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: dart_utils_api_cleanup.py <utils_api.dart>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"import 'package:built_value/serializer\.dart';\n", "", text)
    text = re.sub(r"\n\s*final\s+Serializers\s+_serializers;\n", "\n", text)
    text = re.sub(
        r"const\s+UtilsApi\(\s*this\._dio\s*,\s*this\._serializers\s*\);",
        "const UtilsApi(this._dio);",
        text,
    )
    text = re.sub(r"const\s+UtilsApi\(\s*this\._dio\s*\);", "const UtilsApi(this._dio);", text)
    text = re.sub(r"\s*,\s*this\._serializers", "", text)
    text = re.sub(r"import 'package:built_value/json_object\.dart';\n", "", text)
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
