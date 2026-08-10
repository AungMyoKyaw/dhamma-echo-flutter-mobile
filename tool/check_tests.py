#!/usr/bin/env python3
"""Reject skipped, disabled, or focused Dart tests."""
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TEST_ROOTS = (ROOT / "test", ROOT / "integration_test")
PATTERNS = (
    re.compile(r"\b(?:test|testWidgets|group)\.(?:skip|only)\b"),
    re.compile(r"@Skip\b"),
    re.compile(r"\b(?:test|testWidgets|group)\s*\([^;]{0,2000}\bskip\s*:", re.DOTALL),
)


def main() -> int:
    failures: list[str] = []
    for base in TEST_ROOTS:
        if not base.exists():
            continue
        for path in sorted(base.rglob("*.dart")):
            text = path.read_text()
            if any(pattern.search(text) for pattern in PATTERNS):
                failures.append(str(path.relative_to(ROOT)))
    if failures:
        print("disabled/focused tests found:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print("test marker check passed: zero skipped/disabled/focused tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
