#!/usr/bin/env python3
"""
Hydrate the dart.config.json template with version + metadata details.

Inputs:
    1. Template config path.
    2. Output config path.
    3. Pub version string.
    4. docs/about.json path.

Outputs:
    Writes the hydrated config JSON to the output path.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def maybe_set(container: dict, key: str, value: str | None) -> None:
    if value:
        container[key] = value


def main() -> int:
    if len(sys.argv) != 5:
        print(
            "Usage: dart_config_hydrate.py <template> <output> <pub-version> <about.json>",
            file=sys.stderr,
        )
        return 1

    template_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    pub_version = sys.argv[3]
    about_path = Path(sys.argv[4])

    data = json.loads(template_path.read_text(encoding="utf-8"))
    props = data.setdefault("additionalProperties", {})
    props["pubVersion"] = pub_version

    about = json.loads(about_path.read_text(encoding="utf-8"))
    product_name = about.get("productName", "").strip()
    if not product_name:
        print("ERROR: docs/about.json missing productName", file=sys.stderr)
        return 1

    maybe_set(props, "pubDescription", f"{product_name} API client")
    maybe_set(props, "pubAuthor", about.get("authorName"))
    maybe_set(props, "pubAuthorEmail", about.get("authorEmail"))
    maybe_set(props, "pubHomepage", about.get("homepage"))
    maybe_set(props, "pubRepository", about.get("repositoryUrl"))
    maybe_set(props, "pubIssueTracker", about.get("supportUrl"))

    output_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
