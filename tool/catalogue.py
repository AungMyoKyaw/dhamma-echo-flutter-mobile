#!/usr/bin/env python3
"""Fetch and verify the immutable Dhamma Echo production catalogue."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import sys
import tarfile
import tempfile
from urllib.request import Request, urlopen

REPOSITORY = "AungMyoKyaw/dhamma-echo"
EXPECTED_SIZE = 27_750_400
EXPECTED_SHA256 = "d88cfda6d761d0e682dac3bf29ab3b1d7019496a114defe057bfc55a6e746d31"
DEFAULT_OUTPUT = Path("assets/catalogue/dhamma.db")
USER_AGENT = "dhamma-echo-flutter-catalogue/1.0"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def verify_bytes(data: bytes) -> None:
    if len(data) != EXPECTED_SIZE:
        raise ValueError(f"catalogue size mismatch: expected {EXPECTED_SIZE}, got {len(data)}")
    digest = sha256(data)
    if digest != EXPECTED_SHA256:
        raise ValueError(f"catalogue SHA-256 mismatch: expected {EXPECTED_SHA256}, got {digest}")


def verify_file(path: Path) -> None:
    verify_bytes(path.read_bytes())


def _request_json(url: str) -> dict[str, object]:
    request = Request(url, headers={"Accept": "application/vnd.github+json", "User-Agent": USER_AGENT})
    with urlopen(request, timeout=60) as response:
        payload = json.load(response)
    if not isinstance(payload, dict):
        raise ValueError("GitHub release response was not an object")
    return payload


def _download(url: str) -> bytes:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=120) as response:
        return response.read()


def latest_macos_archive_url() -> str:
    release = _request_json(f"https://api.github.com/repos/{REPOSITORY}/releases/latest")
    assets = release.get("assets")
    if not isinstance(assets, list):
        raise ValueError("Latest GitHub release has no asset list")
    candidates: list[tuple[int, str]] = []
    for raw_asset in assets:
        if not isinstance(raw_asset, dict):
            continue
        name = raw_asset.get("name")
        url = raw_asset.get("browser_download_url")
        if not isinstance(name, str) or not isinstance(url, str) or not name.endswith(".app.tar.gz"):
            continue
        priority = 0 if "aarch64" in name else 1
        candidates.append((priority, url))
    if not candidates:
        raise ValueError("Latest GitHub release has no macOS .app.tar.gz asset")
    candidates.sort(key=lambda item: item[0])
    return candidates[0][1]


def extract_database(archive: bytes) -> bytes:
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as package:
        matches = [
            member
            for member in package.getmembers()
            if member.isfile() and PurePosixPath(member.name).name == "dhamma.db"
        ]
        if len(matches) != 1:
            raise ValueError(f"Expected exactly one dhamma.db in desktop package, found {len(matches)}")
        stream = package.extractfile(matches[0])
        if stream is None:
            raise ValueError("Could not read dhamma.db from desktop package")
        database = stream.read()
    verify_bytes(database)
    return database


def write_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=f".{path.name}.", delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(data)
        handle.flush()
    temporary.replace(path)


def fetch(path: Path) -> None:
    archive_url = latest_macos_archive_url()
    database = extract_database(_download(archive_url))
    write_atomic(path, database)
    print(f"catalogue ready: {path} ({len(database)} bytes, sha256={sha256(database)})")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("fetch", "verify"))
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        if args.command == "fetch":
            fetch(args.output)
        else:
            verify_file(args.output)
            print(f"catalogue verified: {args.output}")
    except (OSError, ValueError, tarfile.TarError, json.JSONDecodeError) as error:
        print(f"catalogue error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
