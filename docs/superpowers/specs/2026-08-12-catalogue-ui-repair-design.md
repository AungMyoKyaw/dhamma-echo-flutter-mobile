# Dhamma Echo Catalogue and UI Repair Design

## Goal

Repair the Flutter mobile build so it ships and reads the real local SQLite catalogue, uses the network only when an approved audio URL is played, and presents the catalogue with a clean, readable, calm mobile UI instead of the current brown/cream low-contrast treatment.

## Confirmed root causes

1. `assets/catalogue/dhamma.db` in the supplied Git bundle is a 28,672-byte development fixture containing 5 audio talks, 3 teachers, and 3 audio collections.
2. The supplied `dhamma(1).db` is the production catalogue already described by the repository constants: 27,750,400 bytes, SHA-256 `d88cfda6d761d0e682dac3bf29ab3b1d7019496a114defe057bfc55a6e746d31`. It contains 30,563 audio talks, 257 teachers, and 429 collections containing audio.
3. Debug mode accepts the fixture asset, so a normal `flutter run` can silently show fixture data even though release tooling expects the production database.
4. The navigation theme overrides the Material 3 selection indicator with a near-white color while the scheme supplies a light selected icon color. The result is a washed-out selected destination, visible in the supplied screenshots.
5. The manual brown/cream `ColorScheme` and default elevated `SearchBar` produce the muddy “tea color” appearance and weak hierarchy reported in the screenshots.

## Data architecture

- Bundle the supplied production `dhamma.db` as the application catalogue asset.
- Copy that immutable asset into the app database directory only when the versioned destination does not exist or is invalid.
- Open the copied database read-only with `sqflite`.
- Read summary, categories, teachers, collections, talks, URLs, and all optional metadata from SQLite.
- Do not fetch catalogue metadata at runtime.
- Keep local favorites/history/resume/settings in the existing on-device state file.
- The only runtime network operation remains foreground playback of an MP3 URL that passes the existing allowlist and normalization policy.

## Catalogue safety

- Runtime asset validation rejects a fixture-sized catalogue in both debug and release builds.
- Repository/CI verification checks the production database size and SHA-256 before tests/builds.
- The deterministic in-memory fixture used by repository unit tests remains test-only; it is no longer the packaged app asset.

## Visual direction

Use a light Material 3 design generated from a forest-green seed instead of hand-pairing brown and cream roles.

Design.md keys:

- primary key: `#2F5D50`
- secondary key: `#6C7B63`
- tertiary key: `#8A6A3D`
- background key: `#F7F8F5`

Implementation direction:

- Neutral near-white app surface; white content surfaces.
- Forest green for primary actions and selection.
- Muted sage/gray containers for secondary emphasis.
- No brown page background, orange avatars, or cream navigation selection.
- Derive paired Material roles from a single `ColorScheme.fromSeed` and only override neutral surfaces where necessary.
- Zero-elevation search bars with a subtle outline.
- Consistent 16 dp page gutter, 8/12/16/24 dp vertical rhythm, 18–20 dp cards.
- Preserve system fonts so Burmese text uses platform script support.
- Keep touch targets at least 48 dp.

## Component changes

### App shell

- Keep the five existing destinations.
- Use `secondaryContainer` and `onSecondaryContainer` as a matched selected indicator/icon pair.
- Keep settings in the app bar.
- Keep the mini-player directly above the navigation bar.

### Home

- Preserve summary counts and featured teachers.
- Use neutral metric surfaces and green emphasis.
- Render the curated teacher order from the production catalogue.

### Explore

- Keep search, language, format, category, teacher, and collection filtering.
- Flatten visual hierarchy: search/filter controls first, result count second, then a readable list surface.
- Keep 50-result explicit pagination.
- Preserve playable/unplayable state and favorite/queue actions.

### Collections and Teachers

- Keep current search/filter behavior and grouping semantics.
- Use production Burmese/English names exactly as stored in SQLite.
- Keep missing metadata neutral; do not invent teacher artwork or biography text.

### Library

- Keep favorites and recent history local-only.
- Use compact neutral empty-state surfaces with green icons instead of large brown icon emphasis.

## Error and empty states

- Initial catalogue failure remains blocking with Retry.
- Search/filter empty states remain distinct from loading and errors.
- Playback failures do not remove catalogue metadata from the UI.
- No runtime network error should prevent browsing the local catalogue.

## Accessibility

- Preserve system text scaling and system fonts.
- Pair Material color roles rather than manually mixing foreground/background colors.
- Keep semantic tooltips on icon-only controls.
- Maintain minimum 48 dp interactive targets.
- Avoid text encoded only by color; selected chips/navigation retain shape/icon state.

## Testing and verification

Regression evidence must cover:

- Packaged catalogue has 30,563 audio talks and 257 teachers.
- Packaged catalogue yields 429 audio collections containing audio.
- Runtime asset validation rejects the small fixture.
- Existing SQLite repository behavior still passes against its isolated fixture.
- Theme uses a neutral surface and a matched navigation indicator/foreground pair.
- Search bars are not elevated.
- Existing navigation, player, detail, filters, favorites, and queue widget tests remain valid.
- Formatter, analyzer, zero-skipped-test scan, coverage, builds, security/repository checks, catalogue SHA verification, visual verification, and Git bundle verification are run when the required toolchain is available.
