#!/usr/bin/env python3
"""Regression tests for generated Android/iOS background playback config."""
from __future__ import annotations

import unittest

from configure_platforms import _configure_android_manifest, _configure_ios_plist


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
