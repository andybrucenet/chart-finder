#!/usr/bin/env python3
"""
Remove unused serializer scaffolding from lib/src/api.dart.

Input:
    1. Path to api.dart.

Output:
    Rewrites the file in place.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: dart_api_cleanup.py <api.dart>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"import 'package:built_value/serializer\.dart';\n", "", text)
    text = re.sub(r"import 'package:chart_finder_client/src/serializers\.dart';\n", "", text)
    text = re.sub(r"\n\s*final\s+Serializers\s+serializers;\n", "\n", text)
    text = re.sub(r",\s*Serializers\?\s*serializers", "", text)
    text = re.sub(
        r"this\.serializers\s*=\s*serializers\s*\?\?\s*standardSerializers,\s*",
        "",
        text,
    )
    text = re.sub(r"UtilsApi\(\s*dio\s*,\s*serializers\s*\)", "UtilsApi(dio)", text)
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
