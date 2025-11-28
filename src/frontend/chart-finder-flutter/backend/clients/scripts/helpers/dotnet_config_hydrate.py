#!/usr/bin/env python3
"""
Hydrate csharp.config.json with the current product metadata.

Inputs:
    1. Template config path.
    2. Output config path.
    3. Product name replacement.

Output:
    Writes the updated config JSON to the output path.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "Usage: dotnet_config_hydrate.py <template> <output> <product-name>",
            file=sys.stderr,
        )
        return 1

    template_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    product_name = sys.argv[3]

    data = json.loads(template_path.read_text(encoding="utf-8"))

    def replace_value(value: str) -> str:
        return value.replace("{{PRODUCT_NAME}}", product_name)

    for key, value in list(data.items()):
        if isinstance(value, str):
            data[key] = replace_value(value)

    output_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
