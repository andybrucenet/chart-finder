#!/usr/bin/env python3
"""Helper utilities for interacting with `xcrun simctl` device listings."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _available_simulators(devices: dict) -> list[str]:
    names: list[str] = []
    for os_name, entries in devices.items():
        is_ios = "iOS" in os_name or os_name.lower().startswith("com.apple.coreplatform")
        if not is_ios:
            continue
        for entry in entries:
            if entry.get("isAvailable"):
                name = entry.get("name")
                if name:
                    names.append(name)
    return sorted(set(names))


def cmd_list_available(devices: dict) -> int:
    for name in _available_simulators(devices):
        print(name)
    return 0


def cmd_find_booted(devices: dict) -> int:
    for entries in devices.values():
        for entry in entries:
            if entry.get("state") == "Booted":
                print(entry.get("udid", ""))
                return 0
    print("", end="")
    return 0


def cmd_find_udid(devices: dict, desired_name: str) -> int:
    found_name = False
    for os_name, entries in devices.items():
        is_ios = "iOS" in os_name or os_name.lower().startswith("com.apple.coreplatform")
        if not is_ios:
            continue
        for entry in entries:
            if entry.get("name") != desired_name:
                continue
            found_name = True
            if entry.get("isAvailable"):
                print(entry.get("udid", ""))
                return 0
    if not found_name:
        print("", end="")
        return 2
    print("", end="")
    return 1


def load_devices(stdin_data: str) -> dict:
    try:
        payload = json.loads(stdin_data)
    except json.JSONDecodeError as exc:  # noqa: BLE001
        raise SystemExit(f"ERROR: failed to parse simctl JSON: {exc}") from exc
    return payload.get("devices", {})


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: frontend-ios-simctl-utils.py <command> [args...]", file=sys.stderr)
        return 1

    command = sys.argv[1]
    stdin_data = sys.stdin.read()
    devices = load_devices(stdin_data)

    if command == "list-available":
        return cmd_list_available(devices)
    if command == "find-udid":
        if len(sys.argv) != 3:
            print("Usage: ... find-udid <device-name>", file=sys.stderr)
            return 1
        return cmd_find_udid(devices, sys.argv[2])
    if command == "find-booted":
        return cmd_find_booted(devices)

    print(f"Unknown command: {command}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
