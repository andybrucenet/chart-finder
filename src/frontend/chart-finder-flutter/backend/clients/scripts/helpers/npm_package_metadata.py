#!/usr/bin/env python3
"""
Normalize package.json metadata for the generated TypeScript client.

Inputs:
    1. package.json path to rewrite.
    2. docs/about.json path for authoritative metadata.

Output:
    Overwrites package.json with the updated fields.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def repo_url(base: str | None) -> str | None:
    if not base:
        return None
    url = base.rstrip("/")
    git_url = url if url.endswith(".git") else f"{url}.git"
    return f"git+{git_url}"


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: npm_package_metadata.py <package-json> <about.json>",
            file=sys.stderr,
        )
        return 1

    pkg_path = Path(sys.argv[1])
    about_path = Path(sys.argv[2])

    data = json.loads(pkg_path.read_text(encoding="utf-8"))
    about = json.loads(about_path.read_text(encoding="utf-8"))

    product = about.get("productName", "").strip()
    if not product:
        print("ERROR: docs/about.json missing productName", file=sys.stderr)
        return 1

    author_name = about.get("authorName", "").strip()
    author_email = about.get("authorEmail", "").strip()
    homepage = about.get("homepage") or about.get("repositoryUrl")
    support = about.get("supportUrl") or about.get("repositoryUrl")
    license_value = about.get("license") or data.get("license") or "UNLICENSED"
    repo = repo_url(about.get("repositoryUrl"))

    data["description"] = f"{product} API client"
    if author_email:
        data["author"] = f"{author_name} <{author_email}>"
    else:
        data["author"] = author_name
    if homepage:
        data["homepage"] = homepage
    if support:
        data.setdefault("bugs", {})["url"] = support
    if repo:
        data["repository"] = {"type": "git", "url": repo}
    if license_value:
        data["license"] = license_value

    keywords = set(data.get("keywords") or [])
    keywords.update({"chart-finder", "sdk", "openapi"})
    data["keywords"] = sorted(keywords)

    pkg_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
