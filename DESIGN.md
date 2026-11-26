# Dhamma Echo Mobile — Design System v1.0 ("Bagan Manuscript")

**Canonical FigCraft Master:** `design/dhamma-echo-mobile.figcraft` (20 pages, 1,957 nodes, 206 native Lucide vector icons, `missingFonts: []`, `0` text overlaps, `0` frame overflows, `0` wrap clips)
**Canonical App Icon Master:** `design/dhamma-echo-icon.vectorcraft` (4 artboards: iOS 1024, Android Adaptive Foreground/Background/Monochrome)
**Platforms:** Android + iOS (single calm custom Flutter design language, 390×844 canonical phone frame, 44px+ touch targets)
**Scope:** Full tri-media (MP3 audio, MP4 foreground video, PDF eBook) + external browser fallback for legacy WMA/WMV/DOC
**Language:** Bilingual UI (English + Myanmar toggle, defaulting to English), preserving all 47,960 authentic Myanmar/Pali/English source titles verbatim
**Privacy:** 100% local-first, zero-account, zero-telemetry, free and ad-free

---

## Visual Direction — Monastic Lacquer & Raw Cotton

A fresh mobile-only aesthetic distinct from both the desktop forest-parchment and atelier bronze/sage systems. Built around warm raw-cotton paper, deep charcoal ink, hairline rules, and a single disciplined **monastic lacquer terracotta** accent.

### Color Tokens

| Token | Light (Raw Cotton) | Dark (Warm Obsidian) | Usage |
|---|---|---|---|
| `paper` | `#FAF8F3` | `#141210` | Screen background canvas |
| `surface` | `#FFFFFF` | `#1D1A17` | Cards, bottom nav, sheets |
| `surfaceSoft` | `#F2EFE7` | `#26221E` | Recessed tracks, inactive pills |
| `ink` | `#1A1918` | `#F3EFE8` | Primary headings and body |
| `inkMuted` | `#635E57` | `#A69E92` | Secondary labels, teacher metadata |
| `inkSubtle` | `#8A8378` | `#7A7368` | Dividers, indicators, tertiary hints |
| `lacquer` | `#B24A2B` | `#E38A6B` | Primary CTA, active tab, playhead |
| `lacquerStrong` | `#8F371D` | `#F0A58B` | Pressed / high-contrast accent |
| `lacquerSoft` | `#F5E4DC` | `#3A241C` | Active nav pill, playing row tint |
| `onLacquer` | `#FAF8F3` | `#141210` | Text/icons on lacquer fill |
| `gold` | `#9A742B` | `#D4B06A` | Video / Abhidhamma / offline banner |
| `goldSoft` | `#F4ECDB` | `#332B1B` | Gold badge / banner tint |
| `sage` | `#4E6E58` | `#86B394` | Offline-ready & eBook indicator |
| `sageSoft` | `#E4EFE7` | `#1F3025` | Offline badge tint |
| `rule` | `#E3DDD2` | `#332E28` | 1px hairline borders & dividers |
| `danger` | `#A63329` | `#F28B82` | Legacy format fallback, destructive actions |
| `dangerSoft` | `#F8E2DF` | `#3B1E1C` | Legacy format / error card fill |

PDF Reader Sepia theme: canvas `#F4ECD8`, page sheet `#FAF4E4`, chrome `#EFE4CB`, border `#DDD0B3`, ink `#2B251B`.

---

## Typography (Bilingual EN + Myanmar)

- **Display / Screen Headings:** `PT Serif` (Latin) / `Noto Serif Myanmar` (Myanmar)
- **Body / UI Controls:** `Avenir Next` (Latin) / `Noto Sans Myanmar` (Myanmar)
- **Line-height discipline:** `135%` for Latin, `165%–180%` for Myanmar so Burmese vowels, medials, and stacked consonants never clip vertically.
- **Detail views:** Long Myanmar titles wrap freely with zero ellipsis truncation.

---

## Information Architecture & Navigation

- **4 Bottom Tabs:** `Home` · `Browse` · `Search` · `Library` (`ပင်မ` · `စူးစမ်း` · `ရှာဖွေ` · `စာကြည့်တိုက်`). Settings lives in the top-right header of Home and Library.
- **Home (Resume-First Companion):** Continue card → Quick 2×2 tri-media & Abhidhamma tiles → Curated Teachers monogram rail → Featured Collections.
- **Persistent Mini-Player:** 62px floating card docked above the bottom tab bar with live progress hairline and 44px play/pause hit target.
- **No-Art Visual Identity (0 DB photos):** Deterministic geometric monogram seals for the 256 teachers; tactile editorial spine cover cards for the 2,532 eBooks; concentric acoustic resonance emblem for Now Playing.

---

## Tri-Media & Offline Specifications

1. **Audio (MP3 — 29,070 items):** Background playback, lock-screen/notification controls, persistent mini-player, full Now Playing sheet (Light & Dark), ±15s skip, scrub bar, speed (`0.75×–2.0×`), Sleep Timer (`Off / 15m / 30m / 45m / End`), Queue drawer, single-item and bulk Collection downloads.
2. **Video (MP4 — 14,474 items):** Foreground-only focused player (portrait + fullscreen landscape), ±15s skip, speed, resume position, single-item download, source link.
3. **eBook (PDF — 2,486 items):** Built-in PDF reader with Light / Sepia / Dark reading tint switcher, page-number resume, page scrubber, zoom, offline download.
4. **Legacy Formats (WMA/WMV/DOC — 1,929 items):** Kept visible and searchable with explicit format badges and an honest **"Open Original in Browser ↗"** + **"Copy Source URL"** detail view.
5. **Offline & Downloads:** App-private storage meter in Library → Downloads, active progress/cancel/retry, Wi-Fi-only toggle (default ON) in Settings, bulk "Download Series" on Audio/eBook collections with confirmation.

---

## FigCraft Screen Inventory (20 Pages)

| # | Page | Size | Purpose |
|---|---|---|---|
| 00 | Foundation · Palette & Type | 1120×900 | Light/Dark tokens, EN+MM type scale, Teacher seals & eBook spines |
| 01 | Foundation · Components & Navigation | 1120×900 | Buttons, chips, badges, EN/MM nav, rows, download progress |
| 02 | Home · Light (EN) | 390×844 | Resume-first companion home |
| 03 | Home · Dark (EN) | 390×844 | Warm obsidian dark mode home |
| 04 | Home · Myanmar UI (MM) | 390×844 | Bilingual Myanmar UI chrome verification |
| 05 | Browse · Audio & Tri-Media | 390×844 | Segmented tri-media browse & filters |
| 06 | Browse · eBooks Shelf | 390×844 | 2-column editorial spine cover cards |
| 07 | Browse · Teachers & Sources | 390×844 | 256 teachers with geometric monogram seals |
| 08 | Search · Results & Filters | 390×844 | Instant local search with mixed MP3/MP4/PDF/Legacy results |
| 09 | Detail · Teacher Profile | 390×844 | Teacher seal header, counts, segmented Collections/Media |
| 10 | Detail · Collection & Bulk Download | 390×844 | Ordered series tracks + Play All / Download Series |
| 11 | Player · Audio Now Playing (Light) | 390×844 | Full audio player sheet |
| 12 | Player · Audio Now Playing (Dark) | 390×844 | Nighttime listening dark player |
| 13 | Player · Queue & Sleep Timer | 390×844 | Sleep timer pills + Up Next queue |
| 14 | Player · Video Player | 390×844 | 16:9 foreground MP4 player + related videos |
| 15 | Reader · eBook PDF (Sepia) | 390×844 | Sepia PDF reader with tint switcher & page scrubber |
| 16 | Library · Saved, History & Downloads | 390×844 | Offline storage meter, active download & ready items |
| 17 | Settings · Bilingual & Offline | 390×844 | EN/MM toggle, Theme, Wi-Fi-only, Legacy toggle, Privacy |
| 18 | States · Legacy, Offline & Long Myanmar | 1240×880 | Edge-state triptych verification |
| 19 | Store · App Store & Play Store Showcase | 1920×1080 | 4 store listing marketing frames |

## Reproducible Generators

- `python3 design/tools/build_icon_vectorcraft.py` → rebuilds `design/dhamma-echo-icon.vectorcraft` and all icon exports under `design/exports/icon/`.
- `python3 design/tools/build_mobile_figcraft.py` → rebuilds `design/dhamma-echo-mobile.figcraft`, renders all 20 PNGs under `design/exports/screens/`, and compiles contact sheets under `design/exports/previews/`.

## Featured Teachers Ordering (Parity with `dhamma-echo`)

Pinned at the top of both the Home Featured Teachers rail and the **Browse → Teachers & Sources** list in exact canonical order from `projects/life/dhamma-echo/src/views.rs`:

`FEATURED_TEACHERS = [16, 42, 40, 53, 61, 8, 55, 1307]`

1. `16` — မိုးကုတ်ဆရာတော်ဘုရားကြီး
2. `42` — သဲအင်းဂူဆရာတော်ဘုရားကြီး ဦးဥက္ကဋ္ဌ
3. `40` — ဖားအောက်တောရဆရာတော်ကြီး ဘဒ္ဒန္တအာစိဏ္ဏ
4. `53` — မဟာဗောဓိမြိုင် ဆရာတော် ဝနဝါသီ အရှင်ဉေယျဓမ္မသာမိမထေရ်
5. `61` — ဆရာတော်ဦးဇောတိက (မဟာမြိုင်တောရ)
6. `8` — ပါမောက္ခချုပ်ဆရာတော်ကြီး ဘဒ္ဒန္တ ဒေါက်တာ နန္ဒမာလာဘိဝံသ
7. `55` — တောင်တန်းသာသနာပြု ဆရာတော်ဘုရားကြီး ဦးဥတ္တမသာရ
8. `1307` — Dr. Mehm Tin Mon

## Iconography & Verification

- **Icon Library:** Lucide SVG (`design/assets/lucide/`, ISC license) compiled as native FigCraft vector nodes (206 icon instances, zero Unicode glyph substitutes).
- **Programmatic Audit:** `python3 design/tools/audit_mobile_figcraft.py` verifies 0 text overlaps, 0 frame overflows, 0 Unicode glyph hacks, native Lucide icon count, and Featured Teachers ordering.
