#!/usr/bin/env python3
"""Build Dhamma Echo Mobile v1.1 (Bagan Manuscript) FigCraft master with Lucide vector icons & Featured Teachers."""
from __future__ import annotations
import hashlib, json, pathlib, re, sqlite3, subprocess, sys
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = pathlib.Path(__file__).resolve().parents[2]
DB_PATH = ROOT / "assets" / "catalogue" / "dhamma.db"
DESIGN = ROOT / "design"
LUCIDE_DIR = DESIGN / "assets" / "lucide"
SCREENS_DIR = DESIGN / "exports" / "screens"
PREVIEWS_DIR = DESIGN / "exports" / "previews"
SCREENS_DIR.mkdir(parents=True, exist_ok=True)
PREVIEWS_DIR.mkdir(parents=True, exist_ok=True)

# Exact featured teacher ordering from projects/life/dhamma-echo/src/views.rs
FEATURED_TEACHERS = [16, 42, 40, 53, 61, 8, 55, 1307]

LIGHT = {
    "paper": "#FAF8F3", "surface": "#FFFFFF", "surfaceSoft": "#F2EFE7",
    "ink": "#1A1918", "inkMuted": "#635E57", "inkSubtle": "#8A8378",
    "lacquer": "#B24A2B", "lacquerStrong": "#8F371D", "lacquerSoft": "#F5E4DC", "onLacquer": "#FAF8F3",
    "gold": "#9A742B", "goldSoft": "#F4ECDB",
    "sage": "#4E6E58", "sageSoft": "#E4EFE7",
    "rule": "#E3DDD2", "danger": "#A63329", "dangerSoft": "#F8E2DF",
}
DARK = {
    "paper": "#141210", "surface": "#1D1A17", "surfaceSoft": "#26221E",
    "ink": "#F3EFE8", "inkMuted": "#A69E92", "inkSubtle": "#7A7368",
    "lacquer": "#E38A6B", "lacquerStrong": "#F0A58B", "lacquerSoft": "#3A241C", "onLacquer": "#141210",
    "gold": "#D4B06A", "goldSoft": "#332B1B",
    "sage": "#86B394", "sageSoft": "#1F3025",
    "rule": "#332E28", "danger": "#F28B82", "dangerSoft": "#3B1E1C",
}
SEAL_TONES_LIGHT = [
    ("#F5E4DC", "#B24A2B"), ("#F4ECDB", "#8C6522"), ("#E4EFE7", "#43634D"),
    ("#EAE6F0", "#5C4D73"), ("#E6ECF0", "#3D5A73"), ("#F2E8E2", "#8A4A36"),
]
SEAL_TONES_DARK = [
    ("#3A241C", "#E38A6B"), ("#332B1B", "#D4B06A"), ("#1F3025", "#86B394"),
    ("#2A2436", "#BCAEE0"), ("#1E2C38", "#8FB8DB"), ("#36241E", "#E09A82"),
]

def has_myanmar(s: str) -> bool:
    return any(0x1000 <= ord(c) <= 0x109F or 0xAA60 <= ord(c) <= 0xAA7F for c in str(s))

def cut(s: str, n: int = 44) -> str:
    s = str(s).strip()
    return s if len(s) <= n else s[:n-1].rstrip() + "…"

def _svg_path(el: ET.Element) -> str | None:
    name = el.tag.rsplit("}", 1)[-1]
    get = lambda k, default="0": float(el.get(k, default))
    if name == "path":
        return el.get("d")
    if name in ("circle", "ellipse"):
        cx, cy = get("cx"), get("cy")
        rx = get("r") if name == "circle" else get("rx")
        ry = rx if name == "circle" else get("ry")
        if rx <= 0 or ry <= 0: return None
        return f"M{cx+rx:g} {cy:g} A{rx:g} {ry:g} 0 1 0 {cx-rx:g} {cy:g} A{rx:g} {ry:g} 0 1 0 {cx+rx:g} {cy:g} Z"
    if name == "line":
        return f"M{get('x1'):g} {get('y1'):g} L{get('x2'):g} {get('y2'):g}"
    if name in ("polyline", "polygon"):
        pts = re.findall(r"[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?", el.get("points", ""))
        if len(pts) < 4: return None
        path = "M" + " ".join(pts[:2]) + " " + " ".join("L" + pts[i] + " " + pts[i+1] for i in range(2, len(pts)-1, 2))
        return path + (" Z" if name == "polygon" else "")
    if name == "rect":
        x, y, w, h = get("x"), get("y"), get("width"), get("height")
        rx = min(get("rx"), w/2, h/2)
        if rx:
            return f"M{x+rx:g} {y:g} H{x+w-rx:g} A{rx:g} {rx:g} 0 0 1 {x+w:g} {y+rx:g} V{y+h-rx:g} A{rx:g} {rx:g} 0 0 1 {x+w-rx:g} {y+h:g} H{x+rx:g} A{rx:g} {rx:g} 0 0 1 {x:g} {y+h-rx:g} V{y+rx:g} A{rx:g} {rx:g} 0 0 1 {x+rx:g} {y:g} Z"
        return f"M{x:g} {y:g} H{x+w:g} V{y+h:g} H{x:g} Z"
    return None

def lucide_paths(name: str) -> list[str]:
    f = LUCIDE_DIR / f"{name}.svg"
    if not f.is_file():
        raise FileNotFoundError(f"Missing Lucide SVG: {f}")
    root = ET.fromstring(f.read_text(encoding="utf-8"))
    return [p for el in root.iter() if el is not root and (p := _svg_path(el))]

def load_fixtures() -> dict:
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    # Fetch exact Featured Teachers in canonical order from dhamma-echo
    placeholders = ",".join("?" for _ in FEATURED_TEACHERS)
    feat_map = {r["id"]: dict(r) for r in cur.execute(f"""
        SELECT id, name,
               (SELECT COUNT(*) FROM media WHERE teacher_id=teachers.id) as media_count,
               (SELECT COUNT(*) FROM collections WHERE teacher_id=teachers.id) as col_count
        FROM teachers WHERE id IN ({placeholders})
    """, FEATURED_TEACHERS).fetchall()}
    featured_teachers = [dict(feat_map[tid], featured=True) for tid in FEATURED_TEACHERS if tid in feat_map]
    other_teachers = [dict(r, featured=False) for r in cur.execute(f"""
        SELECT id, name,
               (SELECT COUNT(*) FROM media WHERE teacher_id=teachers.id) as media_count,
               (SELECT COUNT(*) FROM collections WHERE teacher_id=teachers.id) as col_count
        FROM teachers WHERE id NOT IN ({placeholders})
        ORDER BY media_count DESC LIMIT 6
    """, FEATURED_TEACHERS).fetchall()]
    ordered_teachers = featured_teachers + other_teachers

    audios = [dict(r) for r in cur.execute("""
        SELECT m.id, m.title, m.format, m.language, t.name as teacher_name
        FROM media m LEFT JOIN teachers t ON m.teacher_id=t.id
        WHERE m.type='audio' AND m.format='mp3' AND length(m.title) BETWEEN 18 AND 68
        LIMIT 10
    """).fetchall()]
    mogok_cols = [dict(r) for r in cur.execute("""
        SELECT col.id, col.name, col.type, t.name as teacher_name, COUNT(mc.media_id) as item_count
        FROM collections col LEFT JOIN teachers t ON col.teacher_id=t.id
        LEFT JOIN media_collections mc ON mc.collection_id=col.id
        WHERE col.teacher_id = 16
        GROUP BY col.id ORDER BY item_count DESC LIMIT 5
    """).fetchall()]
    videos = [dict(r) for r in cur.execute("""
        SELECT m.id, m.title, m.format, m.language, t.name as teacher_name
        FROM media m LEFT JOIN teachers t ON m.teacher_id=t.id
        WHERE m.type='video' AND m.format='mp4' AND length(m.title) BETWEEN 15 AND 62
        LIMIT 6
    """).fetchall()]
    ebooks = [dict(r) for r in cur.execute("""
        SELECT m.id, m.title, m.format, m.language, t.name as teacher_name
        FROM media m LEFT JOIN teachers t ON m.teacher_id=t.id
        WHERE m.type='ebook' AND m.format='pdf' AND length(m.title) BETWEEN 15 AND 68
        LIMIT 6
    """).fetchall()]
    legacy = [dict(r) for r in cur.execute("""
        SELECT m.id, m.title, m.type, m.format, m.language, m.url, t.name as teacher_name
        FROM media m LEFT JOIN teachers t ON m.teacher_id=t.id
        WHERE m.format IN ('wma','wmv','doc') AND length(m.title) BETWEEN 18 AND 72
        LIMIT 4
    """).fetchall()]
    long_mm = dict(cur.execute("""
        SELECT m.id, m.title, m.type, m.format, m.language, t.name as teacher_name
        FROM media m LEFT JOIN teachers t ON m.teacher_id=t.id
        WHERE m.type='audio' AND m.format='mp3' AND length(m.title) > 160
        LIMIT 1
    """).fetchone())
    collections = [dict(r) for r in cur.execute("""
        SELECT col.id, col.name, col.type, t.name as teacher_name, COUNT(mc.media_id) as item_count
        FROM collections col LEFT JOIN teachers t ON col.teacher_id=t.id
        LEFT JOIN media_collections mc ON mc.collection_id=col.id
        GROUP BY col.id ORDER BY item_count DESC LIMIT 6
    """).fetchall()]
    col_tracks = [dict(r) for r in cur.execute("""
        SELECT mc.track_number, m.title, m.format, m.language
        FROM media_collections mc JOIN media m ON m.id=mc.media_id
        WHERE mc.collection_id = ?
        ORDER BY mc.track_number ASC LIMIT 6
    """, (collections[1]["id"],)).fetchall()]
    conn.close()
    return {
        "featured_teachers": featured_teachers,
        "teachers": ordered_teachers,
        "mogok_cols": mogok_cols,
        "audios": audios, "videos": videos, "ebooks": ebooks,
        "legacy": legacy, "long_mm": long_mm,
        "collections": collections, "col_tracks": col_tracks,
    }


class FigBuilder:
    def __init__(self):
        self.cmds = []
        self.nid = 2
        self.pages = []
        self.frame = None
        self.W = 390
        self.H = 844
        self.dark = False
        self.P = LIGHT

    def op(self, cmd: str, params: dict, create: bool = True):
        node = None
        if create:
            node = self.nid
            self.nid += 1
        self.cmds.append({"command": cmd, "params": params})
        return node

    def page(self, name: str, w: int = 390, h: int = 844, dark: bool = False, bg: str | None = None):
        self.W, self.H, self.dark = w, h, dark
        self.P = DARK if dark else LIGHT
        if not self.pages:
            self.op("page.rename", {"id": 1, "name": name}, False)
        else:
            self.op("page.add", {"name": name})
        self.frame = self.op("frame.create", {
            "name": name.replace(" • ", " — "),
            "x": 0, "y": 0, "width": w, "height": h,
            "props": {"fill": bg or self.P["paper"]},
            "select": False,
        })
        self.pages.append({"name": name, "width": w, "height": h, "frame_id": self.frame, "dark": dark})
        return self.frame

    def rect(self, x, y, w, h, fill=None, r=0, stroke=None, sw=1, name="Rect", parent=None):
        props = {"fill": fill if fill is not None else self.P["surface"], "cornerRadius": r}
        if stroke:
            props.update({"stroke": stroke, "strokeWeight": sw, "strokeAlign": "inside"})
        return self.op("shape.rectangle", {
            "parent": parent or self.frame, "x": x, "y": y, "width": w, "height": h,
            "name": name, "props": props, "select": False,
        })

    def ellipse(self, x, y, w, h, fill="none", stroke=None, sw=1, name="Ellipse", parent=None):
        props = {"fill": fill}
        if stroke:
            props.update({"stroke": stroke, "strokeWeight": sw})
        return self.op("shape.ellipse", {
            "parent": parent or self.frame, "x": x, "y": y, "width": w, "height": h,
            "name": name, "props": props, "select": False,
        })

    def icon(self, name: str, cx: float, cy: float, color: str | None = None, weight: float = 1.85, parent=None):
        """Place a crisp native 24x24 Lucide SVG vector icon centered at (cx, cy)."""
        col = color or self.P["ink"]
        holder = self.op("frame.create", {
            "name": f"Icon / Lucide / {name}",
            "x": round(cx - 12, 2), "y": round(cy - 12, 2), "width": 24, "height": 24,
            "parent": parent or self.frame, "props": {"fill": "none"}, "select": False,
        })
        for i, d in enumerate(lucide_paths(name)):
            self.op("vector.create", {
                "name": f"{name} / {i+1}", "path": d, "x": 0, "y": 0,
                "parent": holder,
                "props": {"fill": "none", "stroke": col, "strokeWeight": weight, "strokeCap": "round", "strokeJoin": "round"},
                "select": False,
            })
        return holder

    def text(self, s, x, y, w=340, size=14, color=None, bold=False, serif=False, lh=None, align=None, name=None, parent=None, h=None):
        s = str(s)
        mm = has_myanmar(s)
        ff = ("Noto Serif Myanmar" if mm else "PT Serif") if serif else ("Noto Sans Myanmar" if mm else "Avenir Next")
        props = {
            "fontFamily": ff, "fontSize": size,
            "fontStyle": "Bold" if bold else "Regular",
            "lineHeight": lh or ("165%" if mm else "135%"),
            "fill": color or self.P["ink"],
            "textAutoResize": "none" if h is not None else "height",
        }
        if align:
            props["textAlign"] = align
        tid = self.op("text.create", {
            "parent": parent or self.frame, "text": s, "x": x, "y": y, "width": w,
            "name": name or cut(s, 28), "props": props, "select": False,
        })
        if h is not None:
            self.op("node.set", {"id": tid, "height": h}, False)
        return tid

    def centered_text(self, s, x, y, w, h, size=13, color=None, bold=True, serif=False, parent=None):
        s = str(s)
        mm = has_myanmar(s)
        ff = ("Noto Serif Myanmar" if mm else "PT Serif") if serif else ("Noto Sans Myanmar" if mm else "Avenir Next")
        props = {
            "fontFamily": ff, "fontSize": size,
            "fontStyle": "Bold" if bold else "Regular",
            "lineHeight": "145%" if mm else "125%",
            "fill": color or self.P["ink"],
            "textAlign": "center", "textAlignVertical": "middle", "textAutoResize": "none",
        }
        tid = self.op("text.create", {
            "parent": parent or self.frame, "text": s, "x": x, "y": y, "width": w,
            "name": cut(s, 28), "props": props, "select": False,
        })
        self.op("node.set", {"id": tid, "height": h}, False)
        return tid

    def hline(self, x, y, w, color=None, parent=None):
        self.rect(x, y, w, 1, fill=color or self.P["rule"], r=0, name="Divider", parent=parent)

    def acoustic_mark(self, cx, cy, r_outer=18, primary=None, secondary=None, parent=None):
        p = primary or self.P["lacquer"]
        sec = secondary or self.P["gold"]
        for frac, col, sw in [(1.0, sec, max(1.2, r_outer*0.08)), (0.68, p, max(1.5, r_outer*0.11)), (0.39, p, max(1.6, r_outer*0.12))]:
            rr = r_outer * frac
            self.ellipse(cx - rr, cy - rr, rr * 2, rr * 2, fill="none", stroke=col, sw=sw, name="Echo Ring", parent=parent)
        r0 = max(2.2, r_outer * 0.14)
        self.ellipse(cx - r0, cy - r0, r0 * 2, r0 * 2, fill=p, name="Echo Core", parent=parent)

    def status_bar(self, ox=0, oy=0, w=390):
        self.text("9:41", ox + 22, oy + 14, w=46, size=13, bold=True, color=self.P["ink"], name="Time")
        self.rect(ox + (w - 104) / 2, oy + 11, 104, 24, fill="#0D0C0B" if not self.dark else "#000000", r=12, name="Island")
        self.rect(ox + w - 58, oy + 18, 22, 11, fill="none", r=3, stroke=self.P["inkMuted"], sw=1.2, name="Battery")
        self.rect(ox + w - 56, oy + 20, 16, 7, fill=self.P["ink"], r=1.5, name="Battery Fill")

    def chip_width(self, label: str, size: float = 11.5) -> int:
        per = 8.8 if has_myanmar(label) else (size * 0.62)
        return max(54, int(len(label) * per) + 24)

    def chip(self, label, x, y, w=None, active=False, accent=False, h=34, size=11.5):
        w = w or self.chip_width(label, size)
        fill = self.P["lacquer"] if accent else (self.P["lacquerSoft"] if active else self.P["surface"])
        stroke = None if (accent or active) else self.P["rule"]
        color = self.P["onLacquer"] if accent else (self.P["lacquer"] if active else self.P["inkMuted"])
        self.rect(x, y, w, h, fill=fill, r=h / 2, stroke=stroke, sw=1, name=f"Chip: {label}")
        self.centered_text(label, x, y, w, h, size=size, color=color, bold=(active or accent))
        return w

    def chip_row(self, items, x, y, gap=8, h=34, size=11.5, max_right=374):
        """Lay out a horizontal row of chips dynamically so they NEVER overlap or overflow."""
        cx = x
        for item in items:
            lbl = item[0]
            act = item[1] if len(item) > 1 else False
            acc = item[2] if len(item) > 2 else False
            w = self.chip_width(lbl, size)
            if cx + w > max_right:
                break
            self.chip(lbl, cx, y, w=w, active=act, accent=acc, h=h, size=size)
            cx += w + gap
        return cx

    def button(self, label, x, y, w, h=46, primary=True, soft=False, icon_name=None):
        fill = self.P["lacquer"] if primary else (self.P["lacquerSoft"] if soft else self.P["surface"])
        stroke = None if (primary or soft) else self.P["rule"]
        color = self.P["onLacquer"] if primary else (self.P["lacquer"] if soft else self.P["ink"])
        self.rect(x, y, w, h, fill=fill, r=12, stroke=stroke, sw=1, name=f"Btn: {label}")
        if icon_name:
            self.icon(icon_name, x + 22, y + h / 2, color=color, weight=2.0)
            self.centered_text(label, x + 30, y, w - 36, h, size=13, color=color, bold=True)
        else:
            self.centered_text(label, x, y, w, h, size=13, color=color, bold=True)

    def badge(self, label, x, y, tone="soft", w=None):
        tones = {
            "soft": (self.P["surfaceSoft"], self.P["inkMuted"]),
            "lacquer": (self.P["lacquerSoft"], self.P["lacquer"]),
            "sage": (self.P["sageSoft"], self.P["sage"]),
            "gold": (self.P["goldSoft"], self.P["gold"]),
            "danger": (self.P["dangerSoft"], self.P["danger"]),
        }
        bg, fg = tones.get(tone, tones["soft"])
        bw = w or max(44, int(len(label) * (8.5 if has_myanmar(label) else 6.8)) + 18)
        self.rect(x, y, bw, 22, fill=bg, r=6, name=f"Badge: {label}")
        self.centered_text(label, x, y, bw, 22, size=10, color=fg, bold=True)
        return bw

    def teacher_seal(self, name, x, y, size=48, idx=0):
        tones = SEAL_TONES_DARK if self.dark else SEAL_TONES_LIGHT
        bg, fg = tones[idx % len(tones)]
        self.rect(x, y, size, size, fill=bg, r=size * 0.32, stroke=self.P["rule"], sw=1, name=f"Seal: {cut(name, 14)}")
        pad = 4
        self.rect(x + pad, y + pad, size - pad * 2, size - pad * 2, fill="none", r=(size - pad * 2) * 0.28, stroke=fg, sw=0.8, name="Seal Ring")
        glyph = name.strip()[0] if name.strip() else "ဓ"
        self.centered_text(glyph, x, y, size, size, size=size * 0.40, color=fg, bold=True, serif=True)

    def back_header(self, label, ox=0, oy=0):
        self.icon("arrow-left", ox + 26, oy + 64, color=self.P["lacquer"], weight=2.1)
        self.text(label, ox + 44, oy + 54, w=200, size=14, bold=True, color=self.P["lacquer"])

    def mini_player(self, title, teacher, ox=0, y=686, w=390, playing=True):
        self.rect(ox + 12, y, w - 24, 66, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1, name="Mini Player")
        self.rect(ox + 26, y + 63, w - 52, 2.5, fill=self.P["surfaceSoft"], r=2, name="Mini Track")
        self.rect(ox + 26, y + 63, int((w - 52) * 0.38), 2.5, fill=self.P["lacquer"], r=2, name="Mini Progress")
        self.rect(ox + 22, y + 12, 42, 42, fill=self.P["lacquerSoft"], r=10, name="Mini Art")
        self.acoustic_mark(ox + 43, y + 33, r_outer=14)
        # Fixed single-line heights so Myanmar title & teacher NEVER overlap
        self.text(cut(title, 26), ox + 74, y + 11, w=w - 156, size=12, bold=True, color=self.P["ink"], h=22)
        self.text(cut(teacher, 26), ox + 74, y + 36, w=w - 156, size=10.5, color=self.P["inkMuted"], h=20)
        self.ellipse(ox + w - 68, y + 11, 44, 44, fill=self.P["lacquer"], name="Mini Play Btn")
        self.icon("pause" if playing else "play", ox + w - 46, y + 33, color=self.P["onLacquer"], weight=2.1)

    def bottom_nav(self, active="Home", ox=0, oy=760, w=390, myanmar=False):
        self.rect(ox, oy, w, 84, fill=self.P["surface"], r=0, name="Bottom Nav")
        self.hline(ox, oy, w)
        tabs = (
            [("Home", "ပင်မ", "house"), ("Browse", "စူးစမ်း", "compass"), ("Search", "ရှာဖွေ", "search"), ("Library", "စာကြည့်တိုက်", "library")]
            if myanmar else
            [("Home", "Home", "house"), ("Browse", "Browse", "compass"), ("Search", "Search", "search"), ("Library", "Library", "library")]
        )
        tw = w / 4
        for i, (key, lbl, ic) in enumerate(tabs):
            tx = ox + i * tw
            is_act = (key == active)
            col = self.P["lacquer"] if is_act else self.P["inkMuted"]
            if is_act:
                self.rect(tx + (tw - 54) / 2, oy + 8, 54, 30, fill=self.P["lacquerSoft"], r=15, name=f"Nav Pill {key}")
            self.icon(ic, tx + tw / 2, oy + 23, color=col, weight=2.1 if is_act else 1.8)
            self.centered_text(lbl, tx + 2, oy + 41, tw - 4, 22, size=10.5 if not myanmar else 9.5, color=col, bold=is_act)
        self.rect(ox + (w - 128) / 2, oy + 71, 128, 5, fill=self.P["inkSubtle"], r=3, name="Home Indicator")

    def media_row(self, title, teacher, fmt, y, ox=0, w=390, downloaded=False, playing=False, legacy=False, num=None):
        """74px high row with strict single-line title + subtitle clearance (ZERO overlap)."""
        pad = 16
        if playing:
            self.rect(ox + 10, y - 4, w - 20, 70, fill=self.P["lacquerSoft"], r=12, name="Active Row")
        if num is not None:
            self.centered_text(f"{num:02d}", ox + pad, y + 12, 30, 32, size=12, color=self.P["inkMuted"], bold=True)
            tx = ox + pad + 38
        else:
            badge_bg = self.P["dangerSoft"] if legacy else (self.P["lacquer"] if playing else self.P["surfaceSoft"])
            badge_fg = self.P["danger"] if legacy else (self.P["onLacquer"] if playing else self.P["lacquer"])
            ic = "external-link" if legacy else ("pause" if playing else ("play" if fmt in ("mp3", "mp4") else "book-open"))
            self.rect(ox + pad, y + 10, 42, 42, fill=badge_bg, r=10, name="Row Icon")
            self.icon(ic, ox + pad + 21, y + 31, color=badge_fg, weight=2.0)
            tx = ox + pad + 54
        right_edge = ox + w - pad - 36
        tw = max(120, right_edge - tx)
        # Explicit non-overlapping single-line boxes: title y+6..y+30, meta y+36..y+56
        self.text(cut(title, 32), tx, y + 6, w=tw, size=12.5, bold=True, color=self.P["lacquer"] if playing else self.P["ink"], h=24)
        meta = f"{cut(teacher, 22)} · {fmt.upper()}" + (" · Offline" if downloaded else (" · Browser" if legacy else ""))
        self.text(meta, tx, y + 36, w=tw, size=10.5, color=self.P["sage"] if downloaded else (self.P["danger"] if legacy else self.P["inkMuted"]), h=20)
        # Right action Lucide icon
        r_ic = "check-circle-2" if downloaded else ("arrow-up-right" if legacy else "download")
        r_col = self.P["sage"] if downloaded else (self.P["danger"] if legacy else self.P["inkMuted"])
        self.icon(r_ic, ox + w - pad - 14, y + 31, color=r_col, weight=1.85)
        self.hline(tx, y + 66, ox + w - pad - tx)

    def build_all(self, fx: dict):
        # ==========================================================
        # 00 • Foundation · Palette & Type
        # ==========================================================
        self.page("00 • Foundation · Palette & Type", 1120, 900, dark=False)
        self.acoustic_mark(56, 56, r_outer=20)
        self.text("DHAMMA ECHO MOBILE  ·  DESIGN SYSTEM v1.1", 90, 36, w=500, size=11, bold=True, color=self.P["lacquer"], h=18)
        self.text("Monastic Lacquer & Raw Cotton", 90, 56, w=680, size=26, bold=True, serif=True, h=34)
        self.text("Mobile-only Android & iOS system  ·  Lucide vector icons  ·  Featured Teachers parity  ·  Bilingual EN + MM", 90, 94, w=940, size=13, color=self.P["inkMuted"], h=20)
        self.hline(36, 128, 1048)

        self.text("LIGHT PALETTE  ·  RAW COTTON PAPER", 36, 146, w=480, size=11, bold=True, color=self.P["inkMuted"], h=18)
        light_swatches = [
            ("paper", LIGHT["paper"]), ("surface", LIGHT["surface"]), ("surfaceSoft", LIGHT["surfaceSoft"]),
            ("ink", LIGHT["ink"]), ("inkMuted", LIGHT["inkMuted"]), ("lacquer", LIGHT["lacquer"]),
            ("lacquerSoft", LIGHT["lacquerSoft"]), ("gold", LIGHT["gold"]), ("sage", LIGHT["sage"]), ("danger", LIGHT["danger"]),
        ]
        for i, (k, hx) in enumerate(light_swatches):
            col, row = i % 5, i // 5
            sx, sy = 36 + col * 102, 172 + row * 96
            self.rect(sx, sy, 90, 54, fill=hx, r=10, stroke=LIGHT["rule"], sw=1, name=f"Light {k}")
            self.text(k, sx, sy + 58, w=90, size=10.5, bold=True, h=15)
            self.text(hx, sx, sy + 75, w=90, size=9.5, color=self.P["inkMuted"], h=14)

        self.text("DARK PALETTE  ·  WARM OBSIDIAN", 576, 146, w=480, size=11, bold=True, color=self.P["inkMuted"], h=18)
        self.rect(570, 168, 514, 202, fill=DARK["paper"], r=14, name="Dark Swatch Tray")
        dark_swatches = [
            ("paper", DARK["paper"]), ("surface", DARK["surface"]), ("surfaceSoft", DARK["surfaceSoft"]),
            ("ink", DARK["ink"]), ("inkMuted", DARK["inkMuted"]), ("lacquer", DARK["lacquer"]),
            ("lacquerSoft", DARK["lacquerSoft"]), ("gold", DARK["gold"]), ("sage", DARK["sage"]), ("danger", DARK["danger"]),
        ]
        for i, (k, hx) in enumerate(dark_swatches):
            col, row = i % 5, i // 5
            sx, sy = 584 + col * 98, 180 + row * 92
            self.rect(sx, sy, 86, 48, fill=hx, r=8, stroke=DARK["rule"], sw=1, name=f"Dark {k}")
            self.text(k, sx, sy + 52, w=86, size=10, bold=True, color=DARK["ink"], h=15)
            self.text(hx, sx, sy + 68, w=86, size=9.5, color=DARK["inkMuted"], h=14)

        self.hline(36, 386, 1048)
        self.text("TYPOGRAPHY  ·  PT SERIF + AVENIR NEXT (LATIN)  /  NOTO SERIF + NOTO SANS MYANMAR", 36, 402, w=960, size=11, bold=True, color=self.P["inkMuted"], h=18)
        self.text("Discover Dhamma, at your pace", 36, 432, w=480, size=25, bold=True, serif=True, h=34)
        self.text("Display Serif · 25px · PT Serif Bold", 36, 468, w=480, size=11, color=self.P["inkMuted"], h=16)
        self.text("Continue Listening · Featured Teachers", 36, 494, w=480, size=17, bold=True, serif=True, h=24)
        self.text("Section Heading · 17px · PT Serif Bold", 36, 522, w=480, size=11, color=self.P["inkMuted"], h=16)
        self.text("47,960 authentic recordings, videos, and books organized locally.", 36, 548, w=480, size=13.5, color=self.P["ink"], h=20)
        self.text("Body UI · 13.5px · Avenir Next Regular", 36, 574, w=480, size=11, color=self.P["inkMuted"], h=16)

        self.text("တရားတော်များကို အေးချမ်းစွာ နားဆင်ပါ", 570, 428, w=500, size=20, bold=True, serif=True, h=36)
        self.text("Myanmar Display · 20px / 165% · Noto Serif Myanmar Bold", 570, 468, w=500, size=11, color=self.P["inkMuted"], h=16)
        self.text("မိုးကုတ်ဆရာတော်ဘုရားကြီး · ဖားအောက်တောရဆရာတော်ကြီး", 570, 492, w=500, size=14, bold=True, h=26)
        self.text("Myanmar Title · 14px / 165% · Noto Sans Myanmar Bold", 570, 522, w=500, size=11, color=self.P["inkMuted"], h=16)
        self.text("မူရင်းအသံဖိုင်၊ ဗီဒီယိုနှင့် စာအုပ်များကို အင်တာနက်မလိုဘဲ ရှာဖွေနိုင်သည်။", 570, 546, w=500, size=12.5, color=self.P["ink"], h=24)

        self.hline(36, 612, 1048)
        self.text("FEATURED TEACHER MONOGRAM SEALS (CANONICAL ORDER) & EDITORIAL EBOOK COVERS", 36, 630, w=960, size=11, bold=True, color=self.P["inkMuted"], h=18)
        for i in range(6):
            t = fx["featured_teachers"][i]
            tx = 36 + i * 86
            self.teacher_seal(t["name"], tx, 664, size=62, idx=i)
            self.text(cut(t["name"], 9), tx, 734, w=74, size=10, color=self.P["inkMuted"], h=20)
        for i in range(3):
            eb = fx["ebooks"][i]
            ex = 580 + i * 168
            self.rect(ex, 660, 152, 204, fill=self.P["surface"], r=10, stroke=self.P["rule"], sw=1, name=f"Book Sample {i}")
            self.rect(ex, 660, 14, 204, fill=self.P["lacquer"] if i == 0 else (self.P["gold"] if i == 1 else self.P["sage"]), r=4, name="Book Spine")
            self.text("PDF · EBOOK", ex + 24, 674, w=116, size=9.5, bold=True, color=self.P["inkMuted"], h=16)
            self.text(cut(eb["title"], 30), ex + 24, 698, w=116, size=11.5, bold=True, serif=True, h=86)
            self.text(cut(eb["teacher_name"], 18), ex + 24, 816, w=116, size=9.5, color=self.P["inkMuted"], h=22)

        # ==========================================================
        # 01 • Foundation · Components & Lucide Icons
        # ==========================================================
        self.page("01 • Foundation · Components & Lucide Icons", 1120, 900, dark=False)
        self.text("COMPONENT SYSTEM  ·  LUCIDE VECTOR ICONS  ·  44PX+ TOUCH TARGETS", 36, 32, w=700, size=11, bold=True, color=self.P["lacquer"], h=18)
        self.text("Core Mobile Controls, Rows & Navigation", 36, 52, w=600, size=24, bold=True, serif=True, h=32)
        self.hline(36, 94, 1048)

        self.text("BUTTONS & DYNAMIC FILTER CHIPS", 36, 112, w=480, size=11, bold=True, color=self.P["inkMuted"], h=18)
        self.button("Play Audio", 36, 138, 154, 46, primary=True, icon_name="play")
        self.button("Download Series", 202, 138, 174, 46, primary=False, soft=True, icon_name="download")
        self.button("Open Browser", 388, 138, 166, 46, primary=False, icon_name="external-link")
        self.chip_row([("All", True, True), ("Audio · 30.5k", True, False), ("Video · 14.8k", False, False), ("eBooks", False, False), ("Myanmar", False, False)], 36, 200, gap=8, h=34, max_right=554)

        self.text("LUCIDE VECTOR ICON SET & BADGES", 600, 112, w=460, size=11, bold=True, color=self.P["inkMuted"], h=18)
        lucide_showcase = ["house", "compass", "search", "library", "settings-2", "headphones", "video", "book-open", "play", "pause", "download", "heart", "clock-3", "list-music", "wifi-off", "external-link"]
        for i, ic in enumerate(lucide_showcase):
            col, row = i % 8, i // 8
            ix, iy = 600 + col * 60, 138 + row * 48
            self.rect(ix, iy, 44, 40, fill=self.P["surface"], r=10, stroke=self.P["rule"], sw=1)
            self.icon(ic, ix + 22, iy + 20, color=self.P["lacquer"] if col < 4 and row == 0 else self.P["ink"])

        self.badge("MP3", 600, 242, "lacquer")
        self.badge("MP4", 654, 242, "gold")
        self.badge("PDF", 708, 242, "sage")
        self.badge("OFFLINE READY", 762, 242, "sage", w=108)
        self.badge("WMA · BROWSER", 880, 242, "danger", w=116)

        self.text("PERSISTENT MINI-PLAYER & 4-TAB LUCIDE NAVIGATION (EN + MM)", 36, 286, w=700, size=11, bold=True, color=self.P["inkMuted"], h=18)
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], ox=36, y=312, w=390, playing=True)
        self.bottom_nav("Home", ox=36, oy=390, w=390, myanmar=False)
        self.bottom_nav("Home", ox=456, oy=390, w=390, myanmar=True)

        self.text("MEDIA ROW VARIANTS (PLAYING / OFFLINE / LEGACY)", 36, 496, w=490, size=11, bold=True, color=self.P["inkMuted"], h=18)
        self.rect(36, 522, 490, 248, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1, name="Row Sheet")
        self.media_row(fx["audios"][1]["title"], fx["audios"][1]["teacher_name"], "mp3", 536, ox=36, w=490, playing=True)
        self.media_row(fx["audios"][2]["title"], fx["audios"][2]["teacher_name"], "mp3", 610, ox=36, w=490, downloaded=True)
        self.media_row(fx["legacy"][0]["title"], fx["legacy"][0]["teacher_name"], fx["legacy"][0]["format"], 684, ox=36, w=490, legacy=True)

        self.text("DOWNLOAD PROGRESS & STORAGE CARD", 564, 496, w=480, size=11, bold=True, color=self.P["inkMuted"], h=18)
        self.rect(564, 522, 510, 128, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1, name="Download Card")
        self.text("Downloading offline talk (MP3)", 584, 538, w=270, size=13, bold=True, h=20)
        self.text("64% · 14.2 / 22.1 MB", 870, 538, w=184, size=12, color=self.P["lacquer"], bold=True, align="right", h=20)
        self.text(cut(fx["audios"][3]["title"], 40), 584, 566, w=460, size=12, color=self.P["inkMuted"], h=22)
        self.rect(584, 600, 470, 8, fill=self.P["surfaceSoft"], r=4, name="Prog Track")
        self.rect(584, 600, 300, 8, fill=self.P["lacquer"], r=4, name="Prog Fill")
        self.text("Wi-Fi only enabled · Tap to pause or cancel", 584, 618, w=380, size=11, color=self.P["inkSubtle"], h=18)

        # ==========================================================
        # 02 • Home · Light (EN)  &  03 • Home · Dark (EN)
        # ==========================================================
        for page_name, is_dark in [("02 • Home · Light (EN)", False), ("03 • Home · Dark (EN)", True)]:
            self.page(page_name, 390, 844, dark=is_dark)
            self.status_bar()
            self.acoustic_mark(34, 68, r_outer=14)
            self.text("Dhamma Echo", 58, 56, w=210, size=20, bold=True, serif=True, h=28)
            self.rect(334, 48, 40, 40, fill=self.P["surface"], r=12, stroke=self.P["rule"], sw=1, name="Settings Btn")
            self.icon("settings-2", 354, 68, color=self.P["inkMuted"], weight=1.9)

            # Continue Listening Card (strictly separated lines)
            self.text("CONTINUE LISTENING", 16, 102, w=240, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
            self.rect(16, 122, 358, 128, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1, name="Continue Card")
            self.badge("MP3 · RESUME", 30, 134, "lacquer", w=102)
            self.text(cut(fx["audios"][0]["title"], 30), 30, 164, w=264, size=13, bold=True, h=24)
            self.text(cut(fx["audios"][0]["teacher_name"], 28), 30, 194, w=264, size=11, color=self.P["inkMuted"], h=20)
            self.ellipse(314, 148, 46, 46, fill=self.P["lacquer"], name="Resume Play")
            self.icon("play", 337, 171, color=self.P["onLacquer"], weight=2.1)
            self.rect(30, 228, 330, 5, fill=self.P["surfaceSoft"], r=3)
            self.rect(30, 228, 138, 5, fill=self.P["lacquer"], r=3)

            # Quick Tri-Media 2x2 Grid with Lucide icons
            self.text("EXPLORE THE ARCHIVE", 16, 266, w=260, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
            tiles = [
                ("Audio Talks", "30,563 MP3/WMA", "headphones", self.P["lacquerSoft"], self.P["lacquer"]),
                ("Video Talks", "14,865 MP4/WMV", "video", self.P["goldSoft"], self.P["gold"]),
                ("eBooks", "2,532 PDF/DOC", "book-open", self.P["sageSoft"], self.P["sage"]),
                ("Abhidhamma", "1,194 Teachings", "book", self.P["surfaceSoft"], self.P["ink"]),
            ]
            for i, (t1, t2, ic, bg, fg) in enumerate(tiles):
                col, row = i % 2, i // 2
                tx, ty = 16 + col * 184, 288 + row * 74
                self.rect(tx, ty, 174, 64, fill=self.P["surface"], r=14, stroke=self.P["rule"], sw=1, name=f"Tile {t1}")
                self.rect(tx + 10, ty + 12, 40, 40, fill=bg, r=10)
                self.icon(ic, tx + 30, ty + 32, color=fg, weight=1.9)
                self.text(t1, tx + 58, ty + 13, w=108, size=12.5, bold=True, h=18)
                self.text(t2, tx + 58, ty + 35, w=108, size=10.5, color=self.P["inkMuted"], h=16)

            # Featured Teachers Rail (EXACT dhamma-echo order: 16, 42, 40, 53)
            self.text("FEATURED TEACHERS", 16, 448, w=220, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
            self.text("View all", 300, 448, w=74, size=11, bold=True, color=self.P["lacquer"], align="right", h=16)
            for i in range(4):
                t = fx["featured_teachers"][i]
                tx = 16 + i * 92
                self.teacher_seal(t["name"], tx + 10, 472, size=58, idx=i)
                self.text(cut(t["name"], 9), tx, 538, w=82, size=10, color=self.P["ink"], align="center", h=22)

            # Featured Collections
            self.text("FEATURED COLLECTIONS", 16, 578, w=240, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
            for i in range(2):
                c = fx["collections"][i]
                cy = 602 + i * 34
                self.text(f"{c['name']} · {cut(c['teacher_name'], 20)}", 16, cy, w=282, size=11.5, bold=True, h=22)
                self.text(f"{c['item_count']} items", 306, cy, w=68, size=10.5, color=self.P["inkMuted"], align="right", h=20)

            self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
            self.bottom_nav("Home")

        # ==========================================================
        # 04 • Home · Myanmar UI (MM)
        # ==========================================================
        self.page("04 • Home · Myanmar UI (MM)", 390, 844, dark=False)
        self.status_bar()
        self.acoustic_mark(34, 68, r_outer=14)
        self.text("ဓမ္မပဲ့တင်သံ", 58, 52, w=220, size=17, bold=True, serif=True, h=30)
        self.rect(334, 48, 40, 40, fill=self.P["surface"], r=12, stroke=self.P["rule"], sw=1)
        self.icon("settings-2", 354, 68, color=self.P["inkMuted"], weight=1.9)

        self.text("ဆက်လက်နားဆင်ရန်", 16, 100, w=240, size=11, bold=True, color=self.P["inkMuted"], h=20)
        self.rect(16, 124, 358, 128, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1)
        self.badge("MP3 · ပြန်ဖွင့်မည်", 30, 136, "lacquer", w=126)
        self.text(cut(fx["audios"][1]["title"], 28), 30, 166, w=264, size=12.5, bold=True, h=24)
        self.text(cut(fx["audios"][1]["teacher_name"], 26), 30, 196, w=264, size=11, color=self.P["inkMuted"], h=20)
        self.ellipse(314, 150, 46, 46, fill=self.P["lacquer"])
        self.icon("play", 337, 173, color=self.P["onLacquer"], weight=2.1)
        self.rect(30, 230, 330, 5, fill=self.P["surfaceSoft"], r=3)
        self.rect(30, 230, 160, 5, fill=self.P["lacquer"], r=3)

        self.text("တရားတော်အမျိုးအစားများ", 16, 268, w=260, size=11, bold=True, color=self.P["inkMuted"], h=20)
        mm_tiles = [
            ("အသံတရားတော်", "၃၀,၅၆၃ ခု", "headphones", self.P["lacquerSoft"], self.P["lacquer"]),
            ("ဗီဒီယိုတရား", "၁၄,၈၆၅ ခု", "video", self.P["goldSoft"], self.P["gold"]),
            ("ဓမ္မစာအုပ်", "၂,၅၃၂ အုပ်", "book-open", self.P["sageSoft"], self.P["sage"]),
            ("အဘိဓမ္မာ", "၁,၁၉၄ ခု", "book", self.P["surfaceSoft"], self.P["ink"]),
        ]
        for i, (t1, t2, ic, bg, fg) in enumerate(mm_tiles):
            col, row = i % 2, i // 2
            tx, ty = 16 + col * 184, 294 + row * 78
            self.rect(tx, ty, 174, 68, fill=self.P["surface"], r=14, stroke=self.P["rule"], sw=1)
            self.rect(tx + 10, ty + 14, 40, 40, fill=bg, r=10)
            self.icon(ic, tx + 30, ty + 34, color=fg, weight=1.9)
            self.text(t1, tx + 58, ty + 12, w=108, size=11.5, bold=True, h=22)
            self.text(t2, tx + 58, ty + 38, w=108, size=10, color=self.P["inkMuted"], h=18)

        self.text("အထူးတင်ဆက် ဆရာတော်များ", 16, 464, w=240, size=11, bold=True, color=self.P["inkMuted"], h=20)
        self.text("အားလုံးကြည့်မည်", 268, 464, w=106, size=10.5, bold=True, color=self.P["lacquer"], align="right", h=20)
        for i in range(4):
            t = fx["featured_teachers"][i]
            tx = 16 + i * 92
            self.teacher_seal(t["name"], tx + 10, 492, size=58, idx=i)
            self.text(cut(t["name"], 9), tx, 558, w=82, size=10, color=self.P["ink"], align="center", h=22)

        self.mini_player(fx["audios"][1]["title"], fx["audios"][1]["teacher_name"], y=686)
        self.bottom_nav("Home", myanmar=True)

        # ==========================================================
        # 05 • Browse · Audio & Tri-Media
        # ==========================================================
        self.page("05 • Browse · Audio & Tri-Media", 390, 844, dark=False)
        self.status_bar()
        self.text("Browse", 16, 52, w=220, size=24, bold=True, serif=True, h=32)
        self.text("47,960 items", 254, 60, w=120, size=12, color=self.P["inkMuted"], align="right", h=18)
        self.chip_row([("Audio", True, True), ("Video", False), ("eBooks", False), ("Teachers", False)], 16, 98, gap=8, h=34)
        self.chip_row([("All", True, False), ("Myanmar", False), ("English", False), ("MP3 only", False)], 16, 144, gap=8, h=30, size=11)
        self.hline(16, 186, 358)
        for i in range(6):
            a = fx["audios"][i]
            self.media_row(a["title"], a["teacher_name"], a["format"], 198 + i * 76, downloaded=(i == 1), playing=(i == 0))
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
        self.bottom_nav("Browse")

        # ==========================================================
        # 06 • Browse · eBooks Shelf
        # ==========================================================
        self.page("06 • Browse · eBooks Shelf", 390, 844, dark=False)
        self.status_bar()
        self.text("Browse", 16, 52, w=220, size=24, bold=True, serif=True, h=32)
        self.text("2,532 eBooks", 254, 60, w=120, size=12, color=self.P["inkMuted"], align="right", h=18)
        self.chip_row([("Audio", False), ("Video", False), ("eBooks", True, True), ("Teachers", False)], 16, 98, gap=8, h=34)
        self.chip_row([("All", True, False), ("PDF", False), ("Myanmar", False), ("English", False)], 16, 144, gap=8, h=30, size=11)
        spines = [self.P["lacquer"], self.P["gold"], self.P["sage"], self.P["inkMuted"]]
        for i in range(4):
            eb = fx["ebooks"][i]
            col, row = i % 2, i // 2
            bx, by = 16 + col * 184, 192 + row * 234
            self.rect(bx, by, 174, 218, fill=self.P["surface"], r=12, stroke=self.P["rule"], sw=1, name=f"Book Card {i}")
            self.rect(bx, by, 12, 218, fill=spines[i % len(spines)], r=4, name="Spine")
            self.badge("PDF", bx + 22, by + 14, "sage" if i == 0 else "soft", w=44)
            if i == 0:
                self.text("Offline", bx + 98, by + 17, w=62, size=10.5, bold=True, color=self.P["sage"], align="right", h=16)
            self.text(cut(eb["title"], 38), bx + 22, by + 48, w=138, size=12, bold=True, serif=True, h=106)
            self.hline(bx + 22, by + 166, 138)
            self.text(cut(eb["teacher_name"], 20), bx + 22, by + 176, w=138, size=10, color=self.P["inkMuted"], h=28)
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
        self.bottom_nav("Browse")

        # ==========================================================
        # 07 • Browse · Teachers & Sources (FEATURED PINNED AT TOP!)
        # ==========================================================
        self.page("07 • Browse · Teachers & Sources", 390, 844, dark=False)
        self.status_bar()
        self.text("Teachers & Sources", 16, 52, w=244, size=21, bold=True, serif=True, h=30)
        self.text("256 teachers", 274, 60, w=100, size=11.5, color=self.P["inkMuted"], align="right", h=18)
        self.chip_row([("Audio", False), ("Video", False), ("eBooks", False), ("Teachers", True, True)], 16, 98, gap=8, h=34)
        self.text("FEATURED TEACHERS  ·  TOP OF LIST", 16, 146, w=320, size=10.5, bold=True, color=self.P["lacquer"], h=16)
        self.hline(16, 168, 358)
        # Show top 6 Featured Teachers in exact dhamma-echo order [16, 42, 40, 53, 61, 8]
        for i in range(6):
            t = fx["featured_teachers"][i]
            ty = 178 + i * 82
            self.teacher_seal(t["name"], 16, ty + 8, size=52, idx=i)
            self.text(cut(t["name"], 26), 80, ty + 8, w=210, size=12.5, bold=True, h=24)
            self.badge("Featured", 296, ty + 8, "gold", w=60)
            self.text(f"{t['media_count']:,} teachings · {t['col_count']} collections", 80, ty + 38, w=256, size=11, color=self.P["inkMuted"], h=18)
            self.icon("chevron-right", 362, ty + 34, color=self.P["inkSubtle"], weight=1.8)
            self.hline(80, ty + 74, 294)
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
        self.bottom_nav("Browse")

        # ==========================================================
        # 08 • Search · Results & Filters
        # ==========================================================
        self.page("08 • Search · Results & Filters", 390, 844, dark=False)
        self.status_bar()
        self.text("Search", 16, 52, w=200, size=24, bold=True, serif=True, h=32)
        self.rect(16, 94, 358, 46, fill=self.P["surface"], r=12, stroke=self.P["lacquer"], sw=1.5, name="Search Input")
        self.icon("search", 38, 117, color=self.P["lacquer"], weight=2.0)
        self.text("ပဋ္ဌာန်း", 58, 105, w=256, size=14, bold=True, h=24)
        self.icon("x", 352, 117, color=self.P["inkMuted"], weight=1.9)
        self.chip_row([("All", True, True), ("Audio", False), ("Video", False), ("eBooks", False)], 16, 152, gap=8, h=32, size=11.5)
        self.text("142 results in local catalogue", 16, 196, w=280, size=11.5, color=self.P["inkMuted"], h=18)
        self.media_row(fx["audios"][1]["title"], fx["audios"][1]["teacher_name"], "mp3", 220, downloaded=True)
        self.media_row(fx["videos"][2]["title"], fx["videos"][2]["teacher_name"], "mp4", 296)
        self.media_row(fx["ebooks"][0]["title"], fx["ebooks"][0]["teacher_name"], "pdf", 372)
        self.media_row(fx["legacy"][0]["title"], fx["legacy"][0]["teacher_name"], fx["legacy"][0]["format"], 448, legacy=True)
        self.media_row(fx["audios"][2]["title"], fx["audios"][2]["teacher_name"], "mp3", 524)
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
        self.bottom_nav("Search")

        # ==========================================================
        # 09 • Detail · Teacher Profile (Featured #1: Mogok Sayadaw ID 16)
        # ==========================================================
        self.page("09 • Detail · Teacher Profile", 390, 844, dark=False)
        self.status_bar()
        self.back_header("Teachers")
        t0 = fx["featured_teachers"][0]
        self.teacher_seal(t0["name"], 157, 92, size=74, idx=0)
        self.badge("FEATURED TEACHER", 130, 176, "gold", w=130)
        self.text(t0["name"], 24, 206, w=342, size=15.5, bold=True, serif=True, align="center", h=30)
        self.text(f"{t0['media_count']:,} teachings · {t0['col_count']} collections · Myanmar", 24, 242, w=342, size=11.5, color=self.P["inkMuted"], align="center", h=18)
        self.chip_row([("Collections", True, True), ("Audio", False), ("Video", False), ("eBooks", False)], 16, 274, gap=8, h=34)
        self.hline(16, 320, 358)
        cols = fx["mogok_cols"] or fx["collections"]
        for i in range(min(4, len(cols))):
            c = cols[i]
            cy = 332 + i * 84
            self.rect(16, cy, 358, 72, fill=self.P["surface"], r=14, stroke=self.P["rule"], sw=1)
            self.badge((c["type"] or "audio").upper(), 30, cy + 14, "lacquer" if c["type"] == "audio" else "gold", w=56)
            self.text(cut(c["name"], 24), 96, cy + 13, w=230, size=13.5, bold=True, h=22)
            self.text(f"{c['item_count']} tracks · Ordered series", 30, cy + 44, w=260, size=11.5, color=self.P["inkMuted"], h=18)
            self.icon("chevron-right", 352, cy + 36, color=self.P["inkSubtle"], weight=1.8)
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
        self.bottom_nav("Browse")

        # ==========================================================
        # 10 • Detail · Collection & Bulk Download
        # ==========================================================
        self.page("10 • Detail · Collection & Bulk Download", 390, 844, dark=False)
        self.status_bar()
        self.back_header("Collection")
        col = fx["collections"][1]
        self.rect(16, 90, 358, 154, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1, name="Col Header")
        self.badge("AUDIO SERIES", 30, 104, "lacquer", w=98)
        self.text(col["name"], 30, 132, w=320, size=19, bold=True, serif=True, h=26)
        self.text(f"{cut(col['teacher_name'], 28)} · {col['item_count']} tracks", 30, 162, w=320, size=11.5, color=self.P["inkMuted"], h=20)
        self.button("Play All", 30, 192, 150, 40, primary=True, icon_name="play")
        self.button("Download Series", 190, 192, 170, 40, primary=False, soft=True, icon_name="download")
        self.text("TRACK ORDER  ·  1 – 50 OF 697", 16, 258, w=260, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        for i, tr in enumerate(fx["col_tracks"][:5]):
            self.media_row(tr["title"], col["teacher_name"], tr["format"] or "mp3", 282 + i * 76, num=tr["track_number"] or (i + 1), downloaded=(i < 2), playing=(i == 0))
        self.mini_player(fx["col_tracks"][0]["title"], col["teacher_name"], y=686)
        self.bottom_nav("Browse")

        # ==========================================================
        # 11 • Player · Audio Now Playing (Light)  &  12 • Dark
        # ==========================================================
        for pname, is_dark in [("11 • Player · Audio Now Playing (Light)", False), ("12 • Player · Audio Now Playing (Dark)", True)]:
            self.page(pname, 390, 844, dark=is_dark)
            self.status_bar()
            self.rect(175, 48, 40, 4, fill=self.P["rule"], r=2)
            self.icon("chevron-down", 32, 70, color=self.P["inkMuted"], weight=2.0)
            self.centered_text("NOW PLAYING · MP3", 95, 58, 200, 24, size=11, color=self.P["inkMuted"], bold=True)
            self.icon("more-horizontal", 358, 70, color=self.P["inkMuted"], weight=2.0)

            self.rect(45, 102, 300, 276, fill=self.P["surface"], r=24, stroke=self.P["rule"], sw=1, name="Artwork Card")
            self.acoustic_mark(195, 224, r_outer=78)
            self.badge("OFFLINE READY", 140, 336, "sage", w=110)

            self.text(cut(fx["audios"][1]["title"], 48), 24, 398, w=342, size=15.5, bold=True, serif=True, align="center", h=54)
            self.text(cut(fx["audios"][1]["teacher_name"], 38), 24, 462, w=342, size=12, color=self.P["inkMuted"], align="center", h=22)

            self.rect(24, 512, 342, 6, fill=self.P["surfaceSoft"], r=3, name="Scrub Track")
            self.rect(24, 512, 146, 6, fill=self.P["lacquer"], r=3, name="Scrub Fill")
            self.ellipse(162, 506, 18, 18, fill=self.P["lacquer"], stroke=self.P["paper"], sw=2, name="Scrub Thumb")
            self.text("18:42", 24, 528, w=80, size=11.5, color=self.P["inkMuted"], h=18)
            self.text("48:15", 286, 528, w=80, size=11.5, color=self.P["inkMuted"], align="right", h=18)

            # Transport controls using Lucide icons
            self.icon("skip-back", 52, 602, color=self.P["ink"], weight=2.0)
            self.icon("rotate-ccw", 112, 602, color=self.P["ink"], weight=2.0)
            self.ellipse(159, 566, 72, 72, fill=self.P["lacquer"], name="Play Pause Big")
            self.icon("pause", 195, 602, color=self.P["onLacquer"], weight=2.3)
            self.icon("refresh-ccw", 278, 602, color=self.P["ink"], weight=2.0)
            self.icon("skip-forward", 338, 602, color=self.P["ink"], weight=2.0)

            # Utility bar with Lucide icons
            self.rect(16, 672, 358, 76, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1, name="Utility Bar")
            utils = [("1.0×", None, "Speed", self.P["ink"]), (None, "clock-3", "Sleep 30m", self.P["lacquer"]), (None, "list-music", "Queue", self.P["ink"]), (None, "heart", "Saved", self.P["lacquer"]), (None, "check-circle-2", "Offline", self.P["sage"])]
            uw = 358 / 5
            for i, (txt, ic, lbl, col) in enumerate(utils):
                ux = 16 + i * uw
                if ic:
                    self.icon(ic, ux + uw / 2, 696, color=col, weight=1.9)
                else:
                    self.centered_text(txt, ux, 682, uw, 28, size=13, color=col, bold=True)
                self.centered_text(lbl, ux, 718, uw, 20, size=10, color=self.P["inkMuted"], bold=False)
            self.rect(131, 822, 128, 5, fill=self.P["inkSubtle"], r=3)

        # ==========================================================
        # 13 • Player · Queue & Sleep Timer
        # ==========================================================
        self.page("13 • Player · Queue & Sleep Timer", 390, 844, dark=False)
        self.status_bar()
        self.back_header("Now Playing")
        self.text("Queue & Sleep Timer", 16, 90, w=300, size=22, bold=True, serif=True, h=30)
        self.rect(16, 132, 358, 126, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1)
        self.text("SLEEP TIMER  ·  STOPS PLAYBACK AUTOMATICALLY", 30, 146, w=320, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.chip_row([("Off", False), ("15m", False), ("30m", True, True), ("45m", False), ("End", False)], 30, 172, gap=6, h=32, size=11, max_right=360)
        self.icon("clock-3", 42, 232, color=self.P["lacquer"], weight=1.9)
        self.text("24 min remaining on timer", 60, 222, w=260, size=12, bold=True, color=self.P["lacquer"], h=20)
        self.text("UP NEXT  ·  5 TALKS IN QUEUE", 16, 280, w=240, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.text("Clear", 314, 280, w=60, size=11.5, bold=True, color=self.P["danger"], align="right", h=16)
        for i in range(5):
            a = fx["audios"][i + 1]
            self.media_row(a["title"], a["teacher_name"], "mp3", 306 + i * 76, num=i + 1, playing=(i == 0))
        self.rect(131, 822, 128, 5, fill=self.P["inkSubtle"], r=3)

        # ==========================================================
        # 14 • Player · Video Player
        # ==========================================================
        self.page("14 • Player · Video Player", 390, 844, dark=False)
        self.status_bar()
        self.back_header("Video")
        self.rect(0, 92, 390, 220, fill="#0F0E0D", r=0, name="Video Viewport")
        self.acoustic_mark(195, 186, r_outer=34, primary="#FAF8F3", secondary="#E38A6B")
        self.icon("play", 195, 186, color="#FAF8F3", weight=2.3)
        self.rect(16, 276, 358, 4, fill="#45403B", r=2)
        self.rect(16, 276, 124, 4, fill=self.P["lacquer"], r=2)
        self.text("12:08 / 44:30", 16, 288, w=120, size=11, color="#FAF8F3", h=16)
        self.text("1.0× · Fullscreen", 240, 288, w=134, size=11, bold=True, color="#FAF8F3", align="right", h=16)
        v0 = fx["videos"][2]
        self.badge("VIDEO · MP4", 16, 328, "gold", w=96)
        self.badge("MYANMAR", 120, 328, "soft", w=80)
        self.text(v0["title"], 16, 360, w=358, size=16.5, bold=True, serif=True, h=32)
        self.text(v0["teacher_name"], 16, 398, w=358, size=12, color=self.P["inkMuted"], h=24)
        self.button("Download MP4", 16, 444, 174, 44, primary=True, icon_name="download")
        self.button("Save", 200, 444, 82, 44, primary=False, soft=True)
        self.button("Source", 290, 444, 84, 44, primary=False)
        self.hline(16, 508, 358)
        self.text("MORE VIDEOS FROM THIS TEACHER", 16, 524, w=280, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        for i in range(3):
            v = fx["videos"][i]
            self.media_row(v["title"], v["teacher_name"], "mp4", 550 + i * 76)
        self.rect(131, 822, 128, 5, fill=self.P["inkSubtle"], r=3)

        # ==========================================================
        # 15 • Reader · eBook PDF (Sepia)
        # ==========================================================
        self.page("15 • Reader · eBook PDF (Sepia)", 390, 844, dark=False, bg="#F4ECD8")
        self.status_bar()
        self.rect(0, 46, 390, 56, fill="#EFE4CB", r=0, name="Reader Topbar")
        self.icon("arrow-left", 28, 74, color=self.P["lacquer"], weight=2.0)
        self.text(cut(fx["ebooks"][0]["title"], 26), 50, 62, w=238, size=12.5, bold=True, h=24)
        self.icon("download", 322, 74, color=self.P["inkMuted"], weight=1.9)
        self.icon("heart", 360, 74, color=self.P["lacquer"], weight=1.9)
        self.hline(0, 102, 390, color="#DDD0B3")
        self.rect(18, 120, 354, 594, fill="#FAF4E4", r=8, stroke="#DDD0B3", sw=1, name="PDF Page")
        self.text("မဟာသမယသုတ် ပါဠိတော် (မြန်မာပြန်)", 38, 152, w=314, size=15.5, bold=True, serif=True, align="center", h=32)
        self.hline(115, 200, 160, color="#C9B996")
        sample_p = (
            "ဧဝံ မေ သုတံ — ဧကံ သမယံ ဘဂဝါ သက္ကေသု ဝိဟရတိ ကပိလဝတ္ထုသ္မိံ မဟာဝနေ "
            "မဟတာ ဘိက္ခုသံဃေန သဒ္ဓိံ ပဉ္စမတ္တေဟိ ဘိက္ခုသတေဟိ သဗ္ဗေဟေဝ အရဟန္တေဟိ။"
            + chr(10) + chr(10)
            + "အခါတစ်ပါး၌ မြတ်စွာဘုရားသည် သက္ကတိုင်း ကပိလဝတ်ပြည် မဟာဝုန်တောကြီး၌ "
            + "ရဟန္တာချည်းဖြစ်ကုန်သော ရဟန်းငါးရာခန့် များစွာသော ရဟန်းသံဃာနှင့်အတူ "
            + "သီတင်းသုံးနေတော်မူ၏။"
        )
        self.text(sample_p, 38, 224, w=314, size=13, color="#2B251B", lh="180%", h=410)
        self.text("14", 38, 678, w=314, size=11, color="#7A6D55", align="center", h=18)
        self.rect(0, 732, 390, 112, fill="#EFE4CB", r=0, name="Reader Bottom")
        self.hline(0, 732, 390, color="#DDD0B3")
        self.text("Page 14 of 128", 16, 748, w=130, size=12, bold=True, color="#2B251B", h=18)
        self.ellipse(258, 742, 26, 26, fill="#FFFFFF", stroke="#C9B996", sw=1.5)
        self.ellipse(294, 742, 26, 26, fill="#F4ECD8", stroke=self.P["lacquer"], sw=2.5)
        self.ellipse(330, 742, 26, 26, fill="#1D1A17", stroke="#595043", sw=1.5)
        self.rect(16, 784, 358, 6, fill="#DDD0B3", r=3)
        self.rect(16, 784, 48, 6, fill=self.P["lacquer"], r=3)
        self.rect(131, 822, 128, 5, fill="#9C8D70", r=3)

        # ==========================================================
        # 16 • Library · Saved, History & Downloads
        # ==========================================================
        self.page("16 • Library · Saved, History & Downloads", 390, 844, dark=False)
        self.status_bar()
        self.text("My Library", 16, 52, w=220, size=24, bold=True, serif=True, h=32)
        self.rect(334, 48, 40, 40, fill=self.P["surface"], r=12, stroke=self.P["rule"], sw=1)
        self.icon("settings-2", 354, 68, color=self.P["inkMuted"], weight=1.9)
        self.chip_row([("Saved (12)", False), ("History", False), ("Downloads (4)", True, True)], 16, 98, gap=8, h=34)
        self.rect(16, 146, 358, 92, fill=self.P["surface"], r=14, stroke=self.P["rule"], sw=1)
        self.text("OFFLINE STORAGE · APP-PRIVATE", 30, 160, w=224, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.text("142 MB used", 268, 160, w=92, size=12, bold=True, color=self.P["lacquer"], align="right", h=18)
        self.rect(30, 188, 330, 8, fill=self.P["surfaceSoft"], r=4)
        self.rect(30, 188, 104, 8, fill=self.P["sage"], r=4)
        self.text("3 MP3 talks · 1 PDF · Wi-Fi only ON", 30, 206, w=266, size=11, color=self.P["inkMuted"], h=18)
        self.text("Clear", 316, 206, w=44, size=11, bold=True, color=self.P["danger"], align="right", h=18)
        self.rect(16, 252, 358, 86, fill=self.P["lacquerSoft"], r=14, name="Active DL")
        self.text("Downloading… 64%", 30, 264, w=180, size=11.5, bold=True, color=self.P["lacquer"], h=18)
        self.text("Cancel", 306, 264, w=54, size=11.5, bold=True, color=self.P["inkMuted"], align="right", h=18)
        self.text(cut(fx["audios"][3]["title"], 34), 30, 286, w=326, size=12, bold=True, h=22)
        self.rect(30, 320, 330, 5, fill=self.P["surface"], r=3)
        self.rect(30, 320, 210, 5, fill=self.P["lacquer"], r=3)
        self.text("READY OFFLINE", 16, 354, w=200, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.media_row(fx["audios"][1]["title"], fx["audios"][1]["teacher_name"], "mp3", 378, downloaded=True)
        self.media_row(fx["audios"][2]["title"], fx["audios"][2]["teacher_name"], "mp3", 454, downloaded=True)
        self.media_row(fx["ebooks"][0]["title"], fx["ebooks"][0]["teacher_name"], "pdf", 530, downloaded=True)
        self.mini_player(fx["audios"][0]["title"], fx["audios"][0]["teacher_name"], y=686)
        self.bottom_nav("Library")

        # ==========================================================
        # 17 • Settings · Bilingual & Offline
        # ==========================================================
        self.page("17 • Settings · Bilingual & Offline", 390, 844, dark=False)
        self.status_bar()
        self.back_header("Back")
        self.text("Settings", 16, 88, w=240, size=24, bold=True, serif=True, h=32)
        self.text("LANGUAGE & APPEARANCE", 16, 134, w=260, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.rect(16, 154, 358, 128, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1)
        self.text("App Language", 30, 170, w=156, size=13.5, bold=True, h=20)
        self.chip("English", 200, 164, w=76, active=True, accent=True, h=32, size=11.5)
        self.chip("မြန်မာ", 284, 164, w=76, h=32, size=11.5)
        self.hline(30, 214, 330)
        self.text("Theme", 30, 234, w=96, size=13.5, bold=True, h=20)
        self.chip("System", 142, 228, w=70, active=True, accent=True, h=32, size=11)
        self.chip("Light", 218, 228, w=66, h=32, size=11)
        self.chip("Dark", 290, 228, w=70, h=32, size=11)
        self.text("PLAYBACK & OFFLINE", 16, 304, w=260, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.rect(16, 324, 358, 190, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1)
        rows = [("Default playback speed", "1.0×"), ("Download over Wi-Fi only", "ON"), ("Show legacy formats (WMA/WMV)", "ON")]
        for i, (k, v) in enumerate(rows):
            ry = 342 + i * 60
            self.text(k, 30, ry, w=260, size=13, bold=True, h=20)
            if v == "ON":
                self.rect(314, ry - 4, 46, 26, fill=self.P["lacquer"], r=13)
                self.ellipse(336, ry - 1, 20, 20, fill="#FFFFFF")
            else:
                self.text(v, 296, ry, w=64, size=13, color=self.P["lacquer"], bold=True, align="right", h=20)
            if i < 2:
                self.hline(30, ry + 40, 330)
        self.text("ABOUT & PRIVACY", 16, 536, w=260, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
        self.rect(16, 556, 358, 152, fill=self.P["surface"], r=16, stroke=self.P["rule"], sw=1)
        self.badge("100% LOCAL · ZERO TRACKING", 30, 572, "sage", w=196)
        self.text("Bundled catalogue: 47,960 items", 30, 608, w=320, size=13.5, bold=True, h=20)
        self.text("256 teachers · 1,315 collections · No accounts, no ads, no analytics. Favorites, resume positions, and downloads stay on your device.", 30, 634, w=326, size=12, color=self.P["inkMuted"], h=60)
        self.rect(131, 822, 128, 5, fill=self.P["inkSubtle"], r=3)

        # ==========================================================
        # 18 • States · Legacy, Offline & Long Myanmar (Triptych 1240x880)
        # ==========================================================
        self.page("18 • States · Legacy, Offline & Long Myanmar", 1240, 880, dark=False, bg="#EAE5D9")
        panels = [(20, "A) LEGACY FORMAT FALLBACK (WMV/WMA/DOC)"), (425, "B) OFFLINE & TRUTHFUL EMPTY LIBRARY"), (830, "C) LONG 250-CHAR MYANMAR TITLE STRESS")]
        for px, plbl in panels:
            self.text(plbl, px, 6, w=390, size=10.5, bold=True, color=self.P["inkMuted"], h=16)
            self.rect(px, 26, 390, 844, fill=self.P["paper"], r=24, stroke=self.P["rule"], sw=1, name=plbl)
            self.status_bar(ox=px, oy=26)

        px = 20
        leg = fx["legacy"][0]
        self.back_header("Media Detail", ox=px, oy=26)
        self.badge(f"LEGACY · {leg['format'].upper()}", px + 16, 122, "danger", w=116)
        self.text(leg["title"], px + 16, 156, w=358, size=17, bold=True, serif=True, h=52)
        self.text(leg["teacher_name"], px + 16, 218, w=358, size=12.5, color=self.P["inkMuted"], h=20)
        self.rect(px + 16, 256, 358, 152, fill=self.P["dangerSoft"], r=14, stroke=self.P["danger"], sw=1)
        self.icon("circle-alert", px + 44, 282, color=self.P["danger"], weight=2.0)
        self.text("Playback not supported in-app", px + 64, 272, w=290, size=13.5, bold=True, color=self.P["danger"], h=22)
        self.text("WMV, WMA, and DOC files cannot be decoded natively on mobile. Open the original source link in your browser or external player.", px + 32, 304, w=326, size=12.5, color=self.P["ink"], h=88)
        self.button("Open Original in Browser", px + 16, 430, 358, 48, primary=True, icon_name="external-link")
        self.button("Copy Source URL", px + 16, 490, 358, 46, primary=False)

        px = 425
        self.text("My Library", px + 16, 78, w=200, size=24, bold=True, serif=True, h=32)
        self.rect(px + 16, 124, 358, 76, fill=self.P["goldSoft"], r=12, stroke=self.P["gold"], sw=1)
        self.icon("wifi-off", px + 42, 150, color=self.P["gold"], weight=2.0)
        self.text("You are offline", px + 62, 136, w=280, size=13, bold=True, color=self.P["gold"], h=20)
        self.text("Browse all 47,960 catalogue entries anytime. Play downloaded talks or reconnect to stream.", px + 30, 160, w=330, size=11, color=self.P["ink"], h=34)
        self.acoustic_mark(px + 195, 340, r_outer=42, primary=self.P["inkSubtle"], secondary=self.P["rule"])
        self.text("Nothing saved yet", px + 40, 408, w=310, size=18, bold=True, serif=True, align="center", h=26)
        self.text("Bookmark any audio talk, video, or eBook to keep it here locally on your device.", px + 40, 442, w=310, size=13, color=self.P["inkMuted"], align="center", h=44)
        self.button("Browse the Catalogue", px + 85, 504, 220, 46, primary=True)
        self.bottom_nav("Library", ox=px, oy=786)

        px = 830
        lm = fx["long_mm"]
        self.back_header("Audio Detail", ox=px, oy=26)
        self.badge("MP3 · MYANMAR", px + 16, 120, "lacquer", w=120)
        self.text(lm["title"], px + 16, 152, w=358, size=13.5, bold=True, lh="170%", h=276)
        self.hline(px + 16, 444, 358)
        self.text(lm["teacher_name"], px + 16, 458, w=358, size=12.5, bold=True, color=self.P["inkMuted"], h=24)
        self.button("Play Talk", px + 16, 500, 174, 46, primary=True, icon_name="play")
        self.button("Download", px + 200, 500, 174, 46, primary=False, soft=True, icon_name="download")
        self.text("Full title wraps freely at 170% line-height with zero vertical clipping or overlap.", px + 16, 566, w=358, size=12, color=self.P["inkMuted"], h=40)

        # ==========================================================
        # 19 • Store · App Store & Play Store Showcase (1920x1080)
        # ==========================================================
        self.page("19 • Store · App Store & Play Store Showcase", 1920, 1080, dark=False, bg="#EAE5D9")
        cards = [
            ("47,960 Authentic" + chr(10) + "Dhamma Teachings", "Audio, video & eBooks from 256 respected teachers — offline-searchable.", LIGHT["paper"], LIGHT["ink"], LIGHT["lacquer"], False),
            ("Listen, Watch &" + chr(10) + "Read Anywhere", "Background audio, sleep timer, built-in PDF reader & offline downloads.", "#B24A2B", "#FAF8F3", "#F4ECDB", False),
            ("Built for Myanmar" + chr(10) + "& English", "Bilingual UI with crisp Myanmar script rendering & zero clipping.", LIGHT["paper"], LIGHT["ink"], LIGHT["lacquer"], False),
            ("Calm, Private." + chr(10) + "Zero Accounts.", "No ads, no tracking, no login. Night-ready dark mode included.", DARK["paper"], DARK["ink"], DARK["lacquer"], True),
        ]
        for i, (headline, sub, bg, fg, acc, is_dk) in enumerate(cards):
            cx = 40 + i * 465
            self.rect(cx, 40, 445, 1000, fill=bg, r=28, stroke=self.P["rule"], sw=1, name=f"Store Card {i+1}")
            self.acoustic_mark(cx + 56, 98, r_outer=18, primary=acc, secondary=fg)
            self.text("DHAMMA ECHO", cx + 84, 88, w=200, size=12, bold=True, color=acc, h=18)
            self.text(headline, cx + 32, 134, w=381, size=33, bold=True, serif=True, color=fg, h=96)
            self.text(sub, cx + 32, 240, w=381, size=14, color=fg if bg == "#B24A2B" else (DARK["inkMuted"] if is_dk else LIGHT["inkMuted"]), h=56)
            px, py = cx + 47, 344
            self.rect(px, py, 350, 696, fill="#141210", r=40, name=f"Phone Bezel {i+1}")
            inner_bg = DARK["paper"] if is_dk else LIGHT["paper"]
            inner_surf = DARK["surface"] if is_dk else LIGHT["surface"]
            inner_ink = DARK["ink"] if is_dk else LIGHT["ink"]
            inner_mut = DARK["inkMuted"] if is_dk else LIGHT["inkMuted"]
            inner_acc = DARK["lacquer"] if is_dk else LIGHT["lacquer"]
            self.rect(px + 10, py + 10, 330, 676, fill=inner_bg, r=32, name=f"Phone Screen {i+1}")
            self.rect(px + 125, py + 22, 100, 20, fill="#000000", r=10)
            if i == 0:
                self.text("Dhamma Echo", px + 28, py + 62, w=220, size=20, bold=True, serif=True, color=inner_ink, h=28)
                self.rect(px + 28, py + 104, 294, 112, fill=inner_surf, r=14, stroke=LIGHT["rule"], sw=1)
                self.text("CONTINUE LISTENING", px + 42, py + 118, w=200, size=10, bold=True, color=inner_acc, h=16)
                self.text(cut(fx["audios"][0]["title"], 28), px + 42, py + 144, w=240, size=12.5, bold=True, color=inner_ink, h=24)
                for j, lbl in enumerate(["Audio · 30.5k", "Video · 14.8k", "eBooks · 2.5k", "Abhidhamma"]):
                    tx, ty = px + 28 + (j % 2) * 152, py + 236 + (j // 2) * 76
                    self.rect(tx, ty, 142, 64, fill=inner_surf, r=12, stroke=LIGHT["rule"], sw=1)
                    self.text(lbl, tx + 14, ty + 22, w=116, size=12, bold=True, color=inner_ink, h=20)
            elif i == 1:
                self.rect(px + 55, py + 84, 240, 220, fill=inner_surf, r=20, stroke=LIGHT["rule"], sw=1)
                self.acoustic_mark(px + 175, py + 194, r_outer=64, primary=LIGHT["lacquer"], secondary=LIGHT["gold"])
                self.text(cut(fx["audios"][1]["title"], 34), px + 28, py + 328, w=294, size=14.5, bold=True, serif=True, color=inner_ink, align="center", h=52)
                self.rect(px + 28, py + 410, 294, 6, fill=LIGHT["surfaceSoft"], r=3)
                self.rect(px + 28, py + 410, 140, 6, fill=LIGHT["lacquer"], r=3)
                self.ellipse(px + 143, py + 448, 64, 64, fill=LIGHT["lacquer"])
                self.icon("pause", px + 175, py + 480, color=LIGHT["onLacquer"], weight=2.3)
            elif i == 2:
                self.text("ဓမ္မပဲ့တင်သံ", px + 28, py + 60, w=240, size=17, bold=True, serif=True, color=inner_ink, h=30)
                for j in range(4):
                    eb = fx["ebooks"][j]
                    tx, ty = px + 28 + (j % 2) * 152, py + 116 + (j // 2) * 194
                    self.rect(tx, ty, 142, 180, fill=inner_surf, r=10, stroke=LIGHT["rule"], sw=1)
                    self.rect(tx, ty, 10, 180, fill=LIGHT["lacquer"] if j % 2 == 0 else LIGHT["gold"], r=4)
                    self.text(cut(eb["title"], 28), tx + 18, ty + 24, w=114, size=11, bold=True, serif=True, color=inner_ink, h=120)
            else:
                self.text("Dhamma Echo", px + 28, py + 62, w=220, size=20, bold=True, serif=True, color=inner_ink, h=28)
                self.rect(px + 55, py + 116, 240, 220, fill=inner_surf, r=20, stroke=DARK["rule"], sw=1)
                self.acoustic_mark(px + 175, py + 226, r_outer=64, primary=DARK["lacquer"], secondary=DARK["gold"])
                self.text("100% Local & Private", px + 28, py + 362, w=294, size=16, bold=True, serif=True, color=inner_ink, align="center", h=26)
                self.text("Dark mode crafted for calm evening and dawn listening.", px + 36, py + 398, w=278, size=12.5, color=inner_mut, align="center", h=44)

def main():
    fx = load_fixtures()
    fb = FigBuilder()
    fb.build_all(fx)
    cmd_path = DESIGN / "tools" / "mobile-commands.json"
    cmd_path.write_text(json.dumps(fb.cmds, indent=2, ensure_ascii=False), encoding="utf-8")
    manifest_path = DESIGN / "screen-manifest.json"
    manifest_path.write_text(json.dumps({"pages": fb.pages, "featured_teachers": FEATURED_TEACHERS}, indent=2, ensure_ascii=False), encoding="utf-8")
    master_path = DESIGN / "dhamma-echo-mobile.figcraft"
    if master_path.exists():
        master_path.unlink()
    p = subprocess.run(["figcraft-cli", "run", str(cmd_path), "--out", str(master_path), "--automation-write-root", str(DESIGN)], capture_output=True, text=True)
    if p.returncode != 0:
        print("FIGCRAFT RUN ERROR:", p.stderr, p.stdout[:1000], file=sys.stderr)
        sys.exit(p.returncode)
    info = subprocess.run(["figcraft-cli", "info", str(master_path), "--json", "--automation-read-root", str(DESIGN)], capture_output=True, text=True)
    info_obj = json.loads(info.stdout)
    print(f"BUILT MASTER: {master_path} | pages={len(info_obj['pages'])} | nodes={info_obj['nodes']} | missingFonts={info_obj['missingFonts']}")
    rendered = []
    for idx, pg in enumerate(fb.pages):
        slug = re.sub(r"[^a-z0-9]+", "-", pg["name"].lower().replace("•", "-").replace("·", "-")).strip("-")[:50]
        fname = f"{idx:02d}-{slug}.png"
        out_png = SCREENS_DIR / fname
        rp = subprocess.run(["figcraft-cli", "render", str(master_path), "--page", pg["name"], "--out", str(out_png), "--scale", "1", "--automation-read-root", str(DESIGN), "--automation-write-root", str(DESIGN)], capture_output=True, text=True)
        if rp.returncode != 0:
            print(f"RENDER ERROR {pg['name']}:", rp.stderr, file=sys.stderr)
            sys.exit(rp.returncode)
        with Image.open(out_png) as im:
            assert im.size == (pg["width"], pg["height"]), f"{fname}: {im.size}"
            rng = im.convert("L").resize((64, 64)).getextrema()
            assert rng[1] - rng[0] > 18, f"Blank render {fname}: {rng}"
        rendered.append({"index": idx, "page": pg["name"], "file": str(out_png.relative_to(ROOT)), "w": pg["width"], "h": pg["height"], "bytes": out_png.stat().st_size})
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    except Exception:
        font = ImageFont.load_default()
    CW, CH, COLS, ROWS = 340, 440, 5, 2
    for si in range(0, len(rendered), COLS * ROWS):
        batch = rendered[si:si + COLS * ROWS]
        sheet = Image.new("RGB", (CW * COLS, CH * ROWS), (236, 232, 224))
        draw = ImageDraw.Draw(sheet)
        for n, item in enumerate(batch):
            with Image.open(ROOT / item["file"]) as im:
                th = ImageOps.contain(im.convert("RGB"), (CW - 24, CH - 54), Image.Resampling.LANCZOS)
                x0 = (n % COLS) * CW + (CW - th.width) // 2
                y0 = (n // COLS) * CH + 12 + (CH - 54 - th.height) // 2
                sheet.paste(th, (x0, y0))
                draw.rectangle([x0 - 1, y0 - 1, x0 + th.width, y0 + th.height], outline=(180, 174, 162), width=1)
                lbl = item["page"].split(" • ", 1)[-1]
                draw.text(((n % COLS) * CW + 12, (n // COLS + 1) * CH - 34), f"{item['index']:02d} {lbl[:34]}", fill=(26, 25, 24), font=font)
        sheet_out = PREVIEWS_DIR / f"contact-{si // (COLS * ROWS) + 1:02d}.jpg"
        sheet.save(sheet_out, quality=92)
    sha = hashlib.sha256(master_path.read_bytes()).hexdigest()
    (SCREENS_DIR / "index.json").write_text(json.dumps({"master": "design/dhamma-echo-mobile.figcraft", "sha256": sha, "pages": len(rendered), "nodes": info_obj["nodes"], "missingFonts": info_obj["missingFonts"], "featured_teachers": FEATURED_TEACHERS, "screens": rendered}, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"ALL {len(rendered)} PAGES RENDERED. SHA256={sha[:16]}...")

if __name__ == "__main__":
    main()