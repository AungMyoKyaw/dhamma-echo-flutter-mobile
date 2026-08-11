# Flutter Mobile Requirements Extracted from Desktop v0.4.0

This document records the product behavior extracted from the supplied `dhamma-echo` desktop Git bundle. The desktop application is the source of truth; mobile layout decisions adapt that behavior to Android and iOS without adding unrelated product scope.

## Product goal

Dhamma Echo is a quiet, local-first mobile library for discovering and listening to Dhamma audio talks from an immutable SQLite catalogue.

## Catalogue behavior

- Treat the catalogue as read-only application data.
- Preserve the desktop summary baseline: 30,563 audio talks, 257 teachers, and 429 audio collections when the current production database is installed.
- Search audio by talk title or teacher name.
- Filter audio by Myanmar/English language, MP3/WMA format, teacher, category, and collection.
- Show 50 audio results initially and load 50 more only after an explicit user action.
- Show 24 collections initially and load 24 more only after an explicit user action.
- Search collection names and optionally filter collections by teacher.
- Group unfiltered collections by teacher, put unknown teacher last, and use natural numeric ordering inside groups.
- Preserve duplicate collection names as distinct records by collection ID.
- In collection detail, order tracks by `media_collections.track_number`, put null track numbers last, then break ties by media ID.
- Search teachers by English or Myanmar name.
- Preserve curated teacher order `[16, 42, 40, 53, 61, 8]`, skipping IDs absent from the current catalogue.
- In teacher detail, show only biography fields that exist in the database; do not invent artwork or biography text.
- Use neutral fallbacks: `Untitled talk`, `Unknown teacher`, and omit missing collection labels.
- Do not hide playable audio merely because optional metadata is incomplete.

## Playback

- MP3 is playable only when the source host is `dhammadownload.com` or `www.dhammadownload.com`.
- Upgrade approved HTTP URLs to HTTPS before playback.
- Remove URL fragments, reject credentials/custom ports, and retry once against the alternate approved hostname.
- Keep WMA searchable but unavailable in the Flutter player.
- Support play/pause, seeking, 15-second backward/forward jumps, playback rate, volume, queue, and next-track playback.
- Playback rates are exactly `0.75`, `1`, `1.25`, `1.5`, `1.75`, and `2`.
- Default playback rate is `1`; default volume is `0.8`.
- Do not add a background playback service in this release.

## Personal library

- Store favorites, listening history, resume positions, and settings only on the device.
- Keep history unique by media ID, most recent first, capped at 100 entries.
- Keep resume positions capped at 500 entries.
- Do not add accounts, cloud sync, analytics, telemetry, or downloads.

## Mobile information architecture

Primary bottom navigation:

1. Home
2. Explore
3. Collections
4. Teachers
5. Library

Settings opens from the app bar. A persistent mini-player sits above bottom navigation whenever a track is selected. Teacher, collection, and full-player screens are pushed as mobile detail routes.

## Visual direction

- Light-only Material 3.
- Neutral off-white surfaces with a restrained forest-green primary, clear Material 3 role contrast, and subtle borders.
- System fonts, including platform Myanmar font support; no font files are bundled.
- Avoid desktop sidebar layouts and generic dashboard cards.
- Favor large touch targets, clear hierarchy, low-shadow search/input surfaces, explicit loading/empty/error states, and safe-area-aware mobile composition.

## Explicit exclusions

- React Native / Expo
- WebView wrappers
- Account system
- Cloud synchronization
- Analytics or telemetry
- Offline media downloads
- Background audio service
- Fabricated teacher biographies or catalogue metadata
