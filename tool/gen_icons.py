#!/usr/bin/env python3
"""Generate iOS AppIcon and Android adaptive launcher icons from design/exports/icon."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "design/exports/icon"
IOS_SET = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
RES = ROOT / "android/app/src/main/res"

ios = Image.open(SRC / "app-icon-ios-1024.png")
flat = Image.new("RGB", ios.size, (250, 248, 243))
flat.paste(ios, mask=ios.getchannel("A") if "A" in ios.getbands() else None)
contents = json.loads((IOS_SET / "Contents.json").read_text())
for entry in contents["images"]:
    fname = entry.get("filename")
    if not fname:
        continue
    w, _ = entry["size"].split("x")
    px = round(float(w) * int(entry["scale"].rstrip("x")))
    flat.resize((px, px), Image.LANCZOS).save(IOS_SET / fname, "PNG")

densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
layers = {
    "ic_launcher_foreground": "app-icon-android-foreground.png",
    "ic_launcher_background": "app-icon-android-background.png",
    "ic_launcher_monochrome": "app-icon-android-monochrome.png",
}
for dens, k in densities.items():
    d = RES / f"mipmap-{dens}"
    d.mkdir(parents=True, exist_ok=True)
    legacy = round(48 * k)
    flat.resize((legacy, legacy), Image.LANCZOS).save(d / "ic_launcher.png", "PNG")
    layer_px = round(108 * k)
    for name, src in layers.items():
        Image.open(SRC / src).convert("RGBA").resize((layer_px, layer_px), Image.LANCZOS).save(d / f"{name}.png", "PNG")

any26 = RES / "mipmap-anydpi-v26"
any26.mkdir(parents=True, exist_ok=True)
(any26 / "ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
    '</adaptive-icon>\n'
)
print("icons ok")
