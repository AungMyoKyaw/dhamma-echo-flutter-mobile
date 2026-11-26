#!/usr/bin/env python3
"""Programmatic layout, text-overlap, bounds-overflow, Lucide icon, and Featured Teachers auditor."""
import collections, json, pathlib, sys, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
MASTER = ROOT / "design" / "dhamma-echo-mobile.figcraft"
FORBIDDEN_GLYPHS = {"⌂", "▤", "⌕", "★", "⚙", "▶", "❚❚", "↺15", "15↻", "☾", "⏮", "⏭", "⌄", "⋯"}

with zipfile.ZipFile(MASTER) as z:
    doc = json.loads(z.read("document.json"))
nodes = doc["nodes"]

def get_page(v):
    for _ in range(16):
        if v.get("type") == "page": return v.get("name")
        p = v.get("parent")
        if p is None or str(p) not in nodes: break
        v = nodes[str(p)]
    return "?"

def box(v):
    m = v.get("transform", [1, 0, 0, 1, 0, 0])
    return (float(m[4]), float(m[5]), float(v.get("width", 0)), float(v.get("height", 0)))

by_page_text = collections.defaultdict(list)
frames = {}
lucide_frames = 0
glyph_violations = []
for v in nodes.values():
    pg = get_page(v)
    if v.get("type") == "frame" and nodes.get(str(v.get("parent")), {}).get("type") == "page":
        frames[pg] = (float(v.get("width", 0)), float(v.get("height", 0)))
    if v.get("type") == "frame" and str(v.get("name", "")).startswith("Icon / Lucide / "):
        lucide_frames += 1
    if v.get("type") == "text":
        by_page_text[pg].append(v)
        ch = v.get("characters", "").strip()
        if ch in FORBIDDEN_GLYPHS:
            glyph_violations.append((pg, ch))

overlaps = []
overflows = []
for pg, texts in sorted(by_page_text.items()):
    fw, fh = frames.get(pg, (9999, 9999))
    for t in texts:
        x, y, w, h = box(t)
        if x < -1 or y < -1 or x + w > fw + 1 or y + h > fh + 1:
            overflows.append((pg, t.get("characters", "")[:26], (x, y, w, h), (fw, fh)))
    for i in range(len(texts)):
        x1, y1, w1, h1 = box(texts[i])
        for j in range(i + 1, len(texts)):
            x2, y2, w2, h2 = box(texts[j])
            ix = min(x1 + w1, x2 + w2) - max(x1, x2)
            iy = min(y1 + h1, y2 + h2) - max(y1, y2)
            if ix > 1.5 and iy > 1.5:
                overlaps.append((pg, texts[i].get("characters", "")[:24], texts[j].get("characters", "")[:24], round(ix, 1), round(iy, 1)))

# Check featured teachers on Page 07
p07_texts = [t.get("characters", "") for t in by_page_text.get("07 • Browse · Teachers & Sources", [])]
has_mogok_first = any("မိုးကုတ်" in s for s in p07_texts)
has_theinngu = any("သဲအင်းဂူ" in s for s in p07_texts)
has_paauk = any("ဖားအောက်" in s for s in p07_texts)

print(f"AUDIT SUMMARY: pages={len(frames)} | lucide_icons={lucide_frames} | text_overlaps={len(overlaps)} | frame_overflows={len(overflows)} | unicode_glyph_hacks={len(glyph_violations)}")
print(f"FEATURED TEACHERS CHECK (Page 07): mogok={has_mogok_first}, theinngu={has_theinngu}, paauk={has_paauk}")
for o in overlaps[:30]: print("  OVERLAP:", o)
for ov in overflows[:20]: print("  OVERFLOW:", ov)
for g in glyph_violations[:20]: print("  GLYPH:", g)
sys.exit(0 if (len(overlaps) == 0 and len(overflows) == 0 and len(glyph_violations) == 0 and lucide_frames > 50 and has_mogok_first) else 1)