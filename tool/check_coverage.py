#!/usr/bin/env python3
"""Enforce every coverage metric that Flutter LCOV actually emits."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys


def parse_lcov(path: Path) -> dict[str, tuple[int, int]]:
    totals = {"lines": [0, 0], "functions": [0, 0], "branches": [0, 0]}
    keys = {"LF": ("lines", 0), "LH": ("lines", 1), "FNF": ("functions", 0), "FNH": ("functions", 1), "BRF": ("branches", 0), "BRH": ("branches", 1)}
    for line in path.read_text().splitlines():
        key, separator, raw_value = line.partition(":")
        if separator and key in keys:
            metric, index = keys[key]
            totals[metric][index] += int(raw_value)
    return {metric: (values[0], values[1]) for metric, values in totals.items()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path, nargs="?", default=Path("coverage/lcov.info"))
    parser.add_argument("--minimum", type=float, default=100.0)
    args = parser.parse_args()
    if not args.path.exists():
        print(f"coverage file missing: {args.path}", file=sys.stderr)
        return 1
    failed = False
    for metric, (found, hit) in parse_lcov(args.path).items():
        if found == 0:
            print(f"{metric}: metric not emitted by this Flutter LCOV report")
            continue
        percent = hit * 100 / found
        print(f"{metric}: {percent:.2f}% ({hit}/{found})")
        if percent < args.minimum:
            failed = True
    if failed:
        return 1
    print("LCOV-emitted coverage metrics meet the configured threshold")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
