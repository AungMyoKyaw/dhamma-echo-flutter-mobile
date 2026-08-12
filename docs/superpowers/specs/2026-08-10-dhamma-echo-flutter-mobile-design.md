# Dhamma Echo Flutter Mobile Design

## Goal

Rebuild the current Dhamma Echo desktop product as a native Flutter mobile application for Android and iOS, using the desktop v0.4.0 repository as the product-behavior source of truth.

## Source requirements extracted from desktop

- Audio-only catalogue: 30,563 talks, 257 teachers, four meaningful audio/Abhidhamma categories, and 429 collections containing audio in the current database.
- Search titles and teachers; filter by language, format, teacher, category, and collection.
- Explore pagination: initial 50 talks, explicit `Load more`, append without losing existing results, retry the same offset after append failures.
- Collections: initial 24, search by collection name, teacher filter, group by teacher when unfiltered, natural numeric name ordering, separate duplicate collection IDs.
- Collection detail: description, teacher, audio count, and collection tracks ordered by track number with missing track numbers last and media ID as tiebreaker.
- Teachers: curated teacher IDs `16, 42, 40, 53, 61, 8` first on Home/Teachers, search by English/Myanmar name, detail page with collections and complete paginated talks.
- Local favorites, bounded history (100), bounded resume map (500), queue, playback rate, and volume.
- MP3 playback only from `dhammadownload.com` or `www.dhammadownload.com`; approved HTTP MP3 sources are upgraded to HTTPS and alternate host candidates are retried. WMA remains searchable but is unavailable for playback.
- Light-only interface. Myanmar text uses platform/system fonts; no font files are bundled.
- No video player, ebook reader, accounts, cloud sync, analytics, telemetry, offline downloads, or background daemon/service.

## Mobile adaptation

### Navigation

Use a Material 3 `NavigationBar` with five frequent destinations:

1. Home
2. Explore
3. Collections
4. Teachers
5. Library

Settings remains a full feature but moves to an app-bar settings action because six persistent bottom destinations are too dense on phones.

Detail screens push above the root navigator and restore the originating tab state when popped.

### Playback

A persistent mini-player appears directly above bottom navigation when a track is selected. Tapping it opens a full player sheet/page with:

- play/pause
- next queued item
- ±15 second jump
- seek slider
- playback speed
- volume
- favorite toggle
- queue list

No background-audio package is added in v1. Playback behavior remains foreground-oriented to preserve desktop scope.

## Architecture

Use Flutter framework primitives plus three focused runtime packages only:

- `sqflite` for the copied read-only catalogue database.
- `just_audio` for network MP3 playback.
- `path` for portable filesystem path construction.

No external state-management or routing framework. `ChangeNotifier` controllers and `Navigator` are sufficient and keep the app small.

Modules:

- `domain/`: immutable models and request/value objects.
- `core/`: normalization, natural sorting, URL trust policy, validation.
- `data/`: catalogue repository, bundled asset installer, local JSON state store.
- `player/`: just_audio adapter and queue/resume behavior.
- `app/`: application controller and dependency composition.
- `ui/`: screens and reusable widgets.

## Catalogue asset strategy

The supplied desktop Git bundle contains a Git LFS pointer for the current 27,750,400-byte database, SHA-256 `d88cfda6d761d0e682dac3bf29ab3b1d7019496a114defe057bfc55a6e746d31`, not the LFS object bytes.

The mobile source therefore contains a tiny deterministic fixture database for tests and debug preview. Release bootstrap must replace it with the exact production database. `tool/catalogue.py` downloads the latest desktop macOS app archive from the public GitHub release, extracts `dhamma.db`, and verifies both exact size and SHA-256 before replacement. Release mode rejects the fixture database.

## Visual design

Material 3 light-only palette derived from the desktop tokens through Design.md:

- primary `#8c3f08`
- secondary `#485b37`
- tertiary `#6e5014`
- surface/background `#fcf9f2`
- surface container `#f0eee7`
- text `#2e2e2a`
- muted text `#565550`
- border/outline `#d5d1c8`
- error `#8d3531`

Use generous 16/20/24 spacing, rounded 16–20 dp cards, minimum 48 dp touch targets, semantic labels, visible loading/error/empty states, no decorative gradients, no bundled fonts, and reduced-motion-safe transitions.

## Error handling

- Distinguish initial loading, empty, not-found, and retryable errors.
- Append failures keep already loaded results and expose inline retry.
- Invalid filters/IDs fail before SQL execution.
- Catalogue SQL uses placeholders for every user-controlled value.
- Unsafe/untrusted media URLs never reach `just_audio`.
- Alternate approved host retry is bounded to generated candidates.
- Corrupt local state falls back to safe defaults.

## Testing

- Unit: normalization, validation, natural sorting, URL policy, local state bounds, controller transitions.
- SQLite repository: run against deterministic in-memory/fixture database via `sqflite_common_ffi`.
- Widget: navigation, empty/error states, filters, track rows, mini-player, settings.
- Integration: smoke journey with injected fixture repository/audio adapter.
- Required final gate: zero skipped/disabled/focused tests and 100% project-owned executable-code coverage.

## Accessibility

- Semantics for icon-only controls.
- 48 dp minimum targets.
- Text scaling without clipping.
- System font fallback for Myanmar script.
- High-enough generated Material scheme contrast.
- Screen-reader names for player controls and filters.
