#!/usr/bin/env python3
"""Apply Dhamma Echo identifiers, display names, network permission, and icons."""
from __future__ import annotations

import json
from pathlib import Path
import re
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ANDROID_MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
ANDROID_BUILD = ROOT / "android/app/build.gradle.kts"
IOS_PLIST = ROOT / "ios/Runner/Info.plist"
IOS_PROJECT = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
ICON = ROOT / "assets/images/app-icon.png"
BUNDLE_ID = "com.aungmyokyaw.dhammaecho"


def _replace(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if old in text:
        path.write_text(text.replace(old, new))


def configure_identifiers() -> None:
    manifest = ANDROID_MANIFEST.read_text()
    if "android.permission.INTERNET" not in manifest:
        closing = manifest.find(">")
        manifest = manifest[: closing + 1] + '\n    <uses-permission android:name="android.permission.INTERNET" />' + manifest[closing + 1 :]
    manifest = re.sub(r'android:label="[^"]*"', 'android:label="Dhamma Echo"', manifest, count=1)
    ANDROID_MANIFEST.write_text(manifest)

    _replace(ANDROID_BUILD, "com.aungmyokyaw.dhamma_echo", BUNDLE_ID)
    _replace(ANDROID_BUILD, "com.aungmyokyaw.dhammaEcho", BUNDLE_ID)

    plist = IOS_PLIST.read_text()
    plist = re.sub(
        r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)',
        r'\1Dhamma Echo\2',
        plist,
        count=1,
    )
    IOS_PLIST.write_text(plist)

    project = IOS_PROJECT.read_text()
    project = project.replace("com.aungmyokyaw.dhamma_echo", BUNDLE_ID)
    project = project.replace("com.aungmyokyaw.dhammaEcho", BUNDLE_ID)
    IOS_PROJECT.write_text(project)


def verify_configuration() -> None:
    manifest = ANDROID_MANIFEST.read_text()
    android_build = ANDROID_BUILD.read_text()
    plist = IOS_PLIST.read_text()
    project = IOS_PROJECT.read_text()
    if 'android.permission.INTERNET' not in manifest or 'android:label="Dhamma Echo"' not in manifest:
        raise ValueError('Android manifest configuration did not apply')
    if BUNDLE_ID not in android_build:
        raise ValueError('Android application ID configuration did not apply')
    if '<key>CFBundleDisplayName</key>' not in plist or '<string>Dhamma Echo</string>' not in plist:
        raise ValueError('iOS display name configuration did not apply')
    if BUNDLE_ID not in project:
        raise ValueError('iOS bundle identifier configuration did not apply')


def resize_icon(source: Image.Image, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    source.resize((size, size), Image.Resampling.LANCZOS).save(destination, format="PNG", optimize=True)


def configure_android_icons(source: Image.Image) -> None:
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in sizes.items():
        resize_icon(source, ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)


def configure_ios_icons(source: Image.Image) -> None:
    directory = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    manifest_path = directory / "Contents.json"
    manifest = json.loads(manifest_path.read_text())
    images = manifest.get("images")
    if not isinstance(images, list):
        raise ValueError("iOS AppIcon Contents.json has no images list")
    for item in images:
        if not isinstance(item, dict):
            continue
        filename = item.get("filename")
        logical_size = item.get("size")
        scale = item.get("scale")
        if not all(isinstance(value, str) for value in (filename, logical_size, scale)):
            continue
        width = float(logical_size.split("x", maxsplit=1)[0])
        multiplier = float(scale.removesuffix("x"))
        resize_icon(source, directory / filename, round(width * multiplier))


def main() -> int:
    required = (ANDROID_MANIFEST, ANDROID_BUILD, IOS_PLIST, IOS_PROJECT, ICON)
    missing = [str(path.relative_to(ROOT)) for path in required if not path.exists()]
    if missing:
        print(f"platform configuration error: missing {', '.join(missing)}", file=sys.stderr)
        return 1
    configure_identifiers()
    verify_configuration()
    with Image.open(ICON) as raw_source:
        source = raw_source.convert("RGBA")
        configure_android_icons(source)
        configure_ios_icons(source)
    print("platform configuration applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
