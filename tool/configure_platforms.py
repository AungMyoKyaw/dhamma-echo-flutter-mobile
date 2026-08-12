#!/usr/bin/env python3
"""Apply Dhamma Echo identifiers, background playback config, and icons."""
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
ICON_FOREGROUND = ROOT / "assets/images/app-icon-foreground.png"
ICON_MONOCHROME = ROOT / "assets/images/app-icon-monochrome.png"
ANDROID_ICON_BACKGROUND = "#FCF9F2"
BUNDLE_ID = "com.aungmyokyaw.dhammaecho"
AUDIO_SERVICE_ACTIVITY = "com.ryanheise.audioservice.AudioServiceActivity"
AUDIO_SERVICE = "com.ryanheise.audioservice.AudioService"
MEDIA_BUTTON_RECEIVER = "com.ryanheise.audioservice.MediaButtonReceiver"


def _replace(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if old in text:
        path.write_text(text.replace(old, new))


def _ensure_manifest_permission(manifest: str, permission: str) -> str:
    if permission in manifest:
        return manifest
    closing = manifest.find(">")
    if closing < 0:
        raise ValueError("Android manifest has no opening element")
    declaration = f'\n    <uses-permission android:name="{permission}" />'
    return manifest[: closing + 1] + declaration + manifest[closing + 1 :]


def _configure_android_manifest(manifest: str) -> str:
    if 'xmlns:tools="http://schemas.android.com/tools"' not in manifest:
        manifest = manifest.replace(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    xmlns:tools="http://schemas.android.com/tools"',
            1,
        )

    for permission in (
        "android.permission.INTERNET",
        "android.permission.WAKE_LOCK",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
    ):
        manifest = _ensure_manifest_permission(manifest, permission)

    manifest = re.sub(
        r'(<activity\s+[^>]*android:name=")[^"]+("[^>]*>)',
        rf"\1{AUDIO_SERVICE_ACTIVITY}\2",
        manifest,
        count=1,
        flags=re.DOTALL,
    )

    if f'android:name="{AUDIO_SERVICE}"' not in manifest:
        service = f'''
        <service
            android:name="{AUDIO_SERVICE}"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver
            android:name="{MEDIA_BUTTON_RECEIVER}"
            android:exported="true"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
'''
        manifest = manifest.replace("</application>", service + "</application>", 1)

    return re.sub(
        r'android:label="[^"]*"',
        'android:label="Dhamma Echo"',
        manifest,
        count=1,
    )


def _configure_ios_plist(plist: str) -> str:
    plist = re.sub(
        r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)',
        r"\1Dhamma Echo\2",
        plist,
        count=1,
    )
    if "<key>UIBackgroundModes</key>" not in plist:
        plist = plist.replace(
            "</dict>",
            "\t<key>UIBackgroundModes</key>\n"
            "\t<array>\n"
            "\t\t<string>audio</string>\n"
            "\t</array>\n"
            "</dict>",
            1,
        )
    elif "<string>audio</string>" not in plist:
        plist = re.sub(
            r"(<key>UIBackgroundModes</key>\s*<array>)",
            r"\1\n\t\t<string>audio</string>",
            plist,
            count=1,
        )
    return plist


def configure_identifiers() -> None:
    ANDROID_MANIFEST.write_text(
        _configure_android_manifest(ANDROID_MANIFEST.read_text())
    )

    _replace(ANDROID_BUILD, "com.aungmyokyaw.dhamma_echo", BUNDLE_ID)
    _replace(ANDROID_BUILD, "com.aungmyokyaw.dhammaEcho", BUNDLE_ID)

    IOS_PLIST.write_text(_configure_ios_plist(IOS_PLIST.read_text()))

    project = IOS_PROJECT.read_text()
    project = project.replace("com.aungmyokyaw.dhamma_echo", BUNDLE_ID)
    project = project.replace("com.aungmyokyaw.dhammaEcho", BUNDLE_ID)
    IOS_PROJECT.write_text(project)


def verify_configuration() -> None:
    manifest = ANDROID_MANIFEST.read_text()
    android_build = ANDROID_BUILD.read_text()
    plist = IOS_PLIST.read_text()
    project = IOS_PROJECT.read_text()
    required_android = (
        "android.permission.INTERNET",
        "android.permission.WAKE_LOCK",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
        AUDIO_SERVICE_ACTIVITY,
        AUDIO_SERVICE,
        MEDIA_BUTTON_RECEIVER,
        'android:foregroundServiceType="mediaPlayback"',
    )
    if (
        any(value not in manifest for value in required_android)
        or 'android:label="Dhamma Echo"' not in manifest
    ):
        raise ValueError("Android background playback configuration did not apply")
    if BUNDLE_ID not in android_build:
        raise ValueError("Android application ID configuration did not apply")
    if (
        "<key>CFBundleDisplayName</key>" not in plist
        or "<string>Dhamma Echo</string>" not in plist
    ):
        raise ValueError("iOS display name configuration did not apply")
    if (
        "<key>UIBackgroundModes</key>" not in plist
        or "<string>audio</string>" not in plist
    ):
        raise ValueError("iOS background audio configuration did not apply")
    if BUNDLE_ID not in project:
        raise ValueError("iOS bundle identifier configuration did not apply")


def resize_icon(source: Image.Image, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    source.resize((size, size), Image.Resampling.LANCZOS).save(
        destination, format="PNG", optimize=True
    )


def configure_android_icons(
    source: Image.Image,
    foreground: Image.Image,
    monochrome: Image.Image,
) -> None:
    legacy_sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    adaptive_sizes = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    for density, size in legacy_sizes.items():
        resize_icon(
            source,
            ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png",
            size,
        )
    for density, size in adaptive_sizes.items():
        directory = ROOT / f"android/app/src/main/res/mipmap-{density}"
        resize_icon(foreground, directory / "ic_launcher_foreground.png", size)
        resize_icon(monochrome, directory / "ic_launcher_monochrome.png", size)

    values = ROOT / "android/app/src/main/res/values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "dhamma_echo_icons.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{ANDROID_ICON_BACKGROUND}</color>\n'
        '</resources>\n'
    )

    adaptive = ROOT / "android/app/src/main/res/mipmap-anydpi-v26"
    adaptive.mkdir(parents=True, exist_ok=True)
    (adaptive / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n'
    )


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
        if not all(
            isinstance(value, str) for value in (filename, logical_size, scale)
        ):
            continue
        width = float(logical_size.split("x", maxsplit=1)[0])
        multiplier = float(scale.removesuffix("x"))
        resize_icon(source, directory / filename, round(width * multiplier))


def main() -> int:
    required = (
        ANDROID_MANIFEST,
        ANDROID_BUILD,
        IOS_PLIST,
        IOS_PROJECT,
        ICON,
        ICON_FOREGROUND,
        ICON_MONOCHROME,
    )
    missing = [str(path.relative_to(ROOT)) for path in required if not path.exists()]
    if missing:
        print(
            f"platform configuration error: missing {', '.join(missing)}",
            file=sys.stderr,
        )
        return 1
    configure_identifiers()
    verify_configuration()
    with (
        Image.open(ICON) as raw_source,
        Image.open(ICON_FOREGROUND) as raw_foreground,
        Image.open(ICON_MONOCHROME) as raw_monochrome,
    ):
        source = raw_source.convert("RGBA")
        foreground = raw_foreground.convert("RGBA")
        monochrome = raw_monochrome.convert("RGBA")
        configure_android_icons(source, foreground, monochrome)
        configure_ios_icons(source)
    print("platform configuration applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
