#!/usr/bin/env python3
"""Fast repository contract checks that do not require Flutter."""
from __future__ import annotations

from pathlib import Path
import re
import stat
import sys

import yaml

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = (
    "README.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "SECURITY.md",
    "CHANGELOG.md",
    "pubspec.yaml",
    "analysis_options.yaml",
    "Makefile",
    "requirements-tooling.txt",
    ".github/workflows/ci.yml",
    ".github/dependabot.yml",
    "tool/bootstrap_platforms.sh",
    "tool/catalogue.py",
    "tool/check_coverage.py",
    "tool/check_tests.py",
    "tool/configure_platforms.py",
    "tool/test_configure_platforms.py",
    "tool/repository_check.py",
    "docs/requirements.md",
    "docs/architecture/context.md",
    "docs/architecture/modules.md",
    "docs/architecture/data-flow.md",
    "docs/architecture/playback-sequence.md",
    "docs/architecture/offline-playback.md",
    "docs/architecture/release.md",
)


def fail(message: str) -> None:
    print(f"repository check error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    missing = [path for path in REQUIRED if not (ROOT / path).exists()]
    if missing:
        fail(f"missing required files: {', '.join(missing)}")
    pubspec = yaml.safe_load((ROOT / "pubspec.yaml").read_text())
    if pubspec.get("name") != "dhamma_echo":
        fail("pubspec project name is not dhamma_echo")
    workflow = yaml.safe_load((ROOT / ".github/workflows/ci.yml").read_text())
    if not isinstance(workflow, dict) or "jobs" not in workflow:
        fail("CI workflow has no jobs mapping")
    for script in sorted((ROOT / "tool").glob("*")):
        if script.suffix in {".py", ".sh"} and not script.stat().st_mode & stat.S_IXUSR:
            fail(f"tool is not executable: {script.relative_to(ROOT)}")
    forbidden = re.compile(r"(?:AIza|ghp_|github_pat_|sk-[A-Za-z0-9])")
    for base in (ROOT / "lib", ROOT / "test", ROOT / "tool"):
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if path == Path(__file__).resolve():
                continue
            if path.is_file() and path.suffix in {".dart", ".py", ".sh"}:
                if forbidden.search(path.read_text(errors="ignore")):
                    fail(f"possible committed secret in {path.relative_to(ROOT)}")
    print("repository contract check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
