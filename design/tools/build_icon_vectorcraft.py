#!/usr/bin/env python3
"""Generate Dhamma Echo Mobile App Icon in native VectorCraft (.vectorcraft) + PNG/SVG exports."""
import json, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DESIGN = ROOT / "design"
EXPORTS = DESIGN / "exports" / "icon"
EXPORTS.mkdir(parents=True, exist_ok=True)

# Palette: Monastic Lacquer & Raw Cotton
LACQUER = "#B24A2B"
LACQUER_DEEP = "#943A1F"
LACQUER_LIGHT = "#C95D3C"
COTTON = "#FAF8F3"
GOLD = "#E8C98A"
INK = "#1A1918"

def add_ripple_mark(cmds, ox, oy, scale=1.0, primary=COTTON, secondary=GOLD, mono=False):
    """Abstract concentric acoustic ripple / resonance emblem centered at (ox+512, oy+512)."""
    cx, cy = ox + 512, oy + 512
    # Outer subtle resonance ring
    r3 = 310 * scale
    cmds.append({"command": "shape.ellipse", "params": {"x": cx - r3, "y": cy - r3, "width": r3 * 2, "height": r3 * 2}})
    cmds.append({"command": "paint.setFill", "params": {"none": True}})
    cmds.append({"command": "paint.setStroke", "params": {"color": primary if mono else secondary}})
    cmds.append({"command": "stroke.set", "params": {"weight": 22 * scale, "cap": "round"}})

    # Middle resonance ring
    r2 = 212 * scale
    cmds.append({"command": "shape.ellipse", "params": {"x": cx - r2, "y": cy - r2, "width": r2 * 2, "height": r2 * 2}})
    cmds.append({"command": "paint.setFill", "params": {"none": True}})
    cmds.append({"command": "paint.setStroke", "params": {"color": primary}})
    cmds.append({"command": "stroke.set", "params": {"weight": 30 * scale, "cap": "round"}})

    # Inner resonance ring
    r1 = 122 * scale
    cmds.append({"command": "shape.ellipse", "params": {"x": cx - r1, "y": cy - r1, "width": r1 * 2, "height": r1 * 2}})
    cmds.append({"command": "paint.setFill", "params": {"none": True}})
    cmds.append({"command": "paint.setStroke", "params": {"color": primary}})
    cmds.append({"command": "stroke.set", "params": {"weight": 34 * scale, "cap": "round"}})

    # Center stillness core (solid dot)
    r0 = 44 * scale
    cmds.append({"command": "shape.ellipse", "params": {"x": cx - r0, "y": cy - r0, "width": r0 * 2, "height": r0 * 2}})
    cmds.append({"command": "paint.setFill", "params": {"color": primary}})
    cmds.append({"command": "paint.setStroke", "params": {"none": True}})

cmds = []
# Artboard 0 (default): resize to 1024x1024 for iOS App Icon
cmds.append({"command": "artboard.setProps", "params": {"index": 0, "name": "iOS App Icon", "x": 0, "y": 0, "width": 1024, "height": 1024}})
# Background square + subtle warm radial vignette
cmds.append({"command": "shape.rectangle", "params": {"x": 0, "y": 0, "width": 1024, "height": 1024}})
cmds.append({"command": "paint.setFill", "params": {"gradient": {
    "kind": "radial",
    "stops": [
        {"offset": 0.0, "color": LACQUER_LIGHT},
        {"offset": 0.55, "color": LACQUER},
        {"offset": 1.0, "color": LACQUER_DEEP}
    ]
}}})
cmds.append({"command": "paint.setStroke", "params": {"none": True}})
add_ripple_mark(cmds, 0, 0, scale=1.0, primary=COTTON, secondary=GOLD, mono=False)

# Artboard 1: Android Adaptive Foreground (transparent background, 66% safe zone)
ox1 = 1200
cmds.append({"command": "artboard.new", "params": {"x": ox1, "y": 0, "width": 1024, "height": 1024, "name": "Android Adaptive Foreground"}})
add_ripple_mark(cmds, ox1, 0, scale=0.72, primary=COTTON, secondary=GOLD, mono=False)

# Artboard 2: Android Adaptive Background
ox2 = 2400
cmds.append({"command": "artboard.new", "params": {"x": ox2, "y": 0, "width": 1024, "height": 1024, "name": "Android Adaptive Background"}})
cmds.append({"command": "shape.rectangle", "params": {"x": ox2, "y": 0, "width": 1024, "height": 1024}})
cmds.append({"command": "paint.setFill", "params": {"gradient": {
    "kind": "radial",
    "stops": [
        {"offset": 0.0, "color": LACQUER_LIGHT},
        {"offset": 0.55, "color": LACQUER},
        {"offset": 1.0, "color": LACQUER_DEEP}
    ]
}}})
cmds.append({"command": "paint.setStroke", "params": {"none": True}})

# Artboard 3: Android Monochrome
ox3 = 3600
cmds.append({"command": "artboard.new", "params": {"x": ox3, "y": 0, "width": 1024, "height": 1024, "name": "Android Monochrome"}})
add_ripple_mark(cmds, ox3, 0, scale=0.72, primary=INK, secondary=INK, mono=True)

steps_path = DESIGN / "tools" / "icon-commands.json"
steps_path.write_text(json.dumps(cmds, indent=2), encoding="utf-8")

master_vc = DESIGN / "dhamma-echo-icon.vectorcraft"
p = subprocess.run([
    "vectorcraft-cli", "--safe-mode", "run",
    "--commands", str(steps_path),
    "--export", str(master_vc),
], capture_output=True, text=True)
if p.returncode != 0:
    print("VC RUN ERROR:", p.stderr, p.stdout, file=sys.stderr)
    sys.exit(p.returncode)

# Export each artboard to 1024x1024 PNG + SVG
exports = [
    (0, "app-icon-ios-1024.png"),
    (0, "app-icon-ios.svg"),
    (1, "app-icon-android-foreground.png"),
    (2, "app-icon-android-background.png"),
    (3, "app-icon-android-monochrome.png"),
]
for idx, fname in exports:
    out_file = EXPORTS / fname
    cmd = ["vectorcraft-cli", "--safe-mode", "convert", str(master_vc), str(out_file), "--artboard", str(idx)]
    if fname.endswith(".png"):
        cmd += ["--scale", "1"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"CONVERT ERROR {fname}:", r.stderr, r.stdout, file=sys.stderr)
        sys.exit(r.returncode)
    print(f"Exported {fname}: {out_file.stat().st_size} bytes")

print("SUCCESS:", master_vc)
