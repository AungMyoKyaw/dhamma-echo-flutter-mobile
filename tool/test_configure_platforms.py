#!/usr/bin/env python3
"""Regression tests for generated Android/iOS background playback config."""
from __future__ import annotations

import tempfile
from pathlib import Path
import unittest
from unittest import mock

from PIL import Image

import configure_platforms
from configure_platforms import (
    _configure_android_manifest,
    _configure_ios_plist,
    configure_android_icons,
)


class ConfigurePlatformsTest(unittest.TestCase):
    def test_android_background_audio_configuration_is_idempotent(self) -> None:
        manifest = """<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">
  <application android:label=\"old\">
    <activity android:name=\".MainActivity\" android:exported=\"true\"></activity>
  </application>
</manifest>"""

        configured = _configure_android_manifest(manifest)

        for value in (
            "android.permission.INTERNET",
            "android.permission.WAKE_LOCK",
            "android.permission.FOREGROUND_SERVICE",
            "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
            "com.ryanheise.audioservice.AudioServiceActivity",
            'android:name="com.ryanheise.audioservice.AudioService"',
            "com.ryanheise.audioservice.MediaButtonReceiver",
            'android:foregroundServiceType="mediaPlayback"',
        ):
            self.assertIn(value, configured)
        self.assertEqual(_configure_android_manifest(configured), configured)

    def test_ios_background_audio_preserves_existing_modes(self) -> None:
        plist = (
            '<?xml version="1.0"?><plist><dict>'
            '<key>CFBundleDisplayName</key><string>old</string>'
            '<key>UIBackgroundModes</key><array><string>processing</string></array>'
            "</dict></plist>"
        )

        configured = _configure_ios_plist(plist)

        self.assertIn("<string>processing</string>", configured)
        self.assertIn("<string>audio</string>", configured)
        self.assertEqual(configured.count("<key>UIBackgroundModes</key>"), 1)

    def test_source_icons_meet_platform_constraints(self) -> None:
        images = Path(__file__).resolve().parents[1] / "assets/images"
        with Image.open(images / "app-icon.png") as master:
            self.assertEqual(master.size, (1024, 1024))
            self.assertEqual(master.mode, "RGB")

        safe_min = round(1024 * 21 / 108)
        safe_max = 1024 - safe_min
        for name in ("app-icon-foreground.png", "app-icon-monochrome.png"):
            with Image.open(images / name) as layer:
                self.assertEqual(layer.size, (1024, 1024))
                self.assertEqual(layer.mode, "RGBA")
                alpha = layer.getchannel("A")
                left, top, right, bottom = alpha.getbbox()
                self.assertGreaterEqual(left, safe_min)
                self.assertGreaterEqual(top, safe_min)
                self.assertLessEqual(right, safe_max)
                self.assertLessEqual(bottom, safe_max)

    def test_android_icons_include_adaptive_and_monochrome_layers(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = Image.new("RGBA", (1024, 1024), "#173F35")
            foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
            foreground.paste("#F8F5EC", (300, 300, 724, 724))
            monochrome = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
            monochrome.paste("#FFFFFF", (300, 300, 724, 724))

            with mock.patch.object(configure_platforms, "ROOT", root):
                configure_android_icons(source, foreground, monochrome)

            adaptive = (
                root
                / "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"
            ).read_text()
            colors = (
                root / "android/app/src/main/res/values/dhamma_echo_icons.xml"
            ).read_text()

            self.assertIn('@mipmap/ic_launcher_foreground', adaptive)
            self.assertIn('@mipmap/ic_launcher_monochrome', adaptive)
            self.assertIn(configure_platforms.ANDROID_ICON_BACKGROUND, colors)

            expected_sizes = {
                "mdpi": 108,
                "hdpi": 162,
                "xhdpi": 216,
                "xxhdpi": 324,
                "xxxhdpi": 432,
            }
            for density, expected_size in expected_sizes.items():
                icon_path = (
                    root
                    / f"android/app/src/main/res/mipmap-{density}"
                    / "ic_launcher_foreground.png"
                )
                with Image.open(icon_path) as icon:
                    self.assertEqual(icon.size, (expected_size, expected_size))

    def test_ios_background_audio_configuration_is_idempotent(self) -> None:
        plist = (
            '<?xml version="1.0"?><plist><dict>'
            '<key>CFBundleDisplayName</key><string>old</string>'
            "</dict></plist>"
        )

        configured = _configure_ios_plist(plist)

        self.assertIn("<string>Dhamma Echo</string>", configured)
        self.assertIn("<key>UIBackgroundModes</key>", configured)
        self.assertEqual(configured.count("<string>audio</string>"), 1)
        self.assertEqual(_configure_ios_plist(configured), configured)


if __name__ == "__main__":
    unittest.main()
