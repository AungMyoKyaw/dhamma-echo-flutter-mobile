# Dhamma Echo Catalogue and UI Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the real local SQLite catalogue and repair the low-contrast brown/cream mobile UI while preserving existing Dhamma Echo behavior.

**Architecture:** Keep the existing Flutter + `ChangeNotifier` architecture. The production SQLite database becomes the packaged immutable catalogue, is copied to a versioned app-local path, and is opened read-only. UI changes stay in the app theme and existing widgets/screens; no new production package is required.

**Tech Stack:** Flutter 3.44.9 / Dart 3.12+, Material 3, sqflite 2.4.3, just_audio 0.10.6, path 1.9.1, flutter_test, sqflite_common_ffi 2.4.2.

## Global Constraints

- Flutter only; Android and iOS release targets.
- Runtime catalogue metadata is local SQLite only.
- Runtime network access is limited to approved foreground MP3 playback.
- Production catalogue identity is 27,750,400 bytes and SHA-256 `d88cfda6d761d0e682dac3bf29ab3b1d7019496a114defe057bfc55a6e746d31`.
- Expected catalogue baseline: 30,563 audio talks, 257 teachers, 429 audio collections.
- Preserve curated teacher order `[16, 42, 40, 53, 61, 8]`.
- No new state-management, routing, font, analytics, download, account, or background-audio dependency.
- Light-only Material 3; system fonts; minimum 48 dp targets.
- Formatter clean, analyzer zero errors/warnings, zero skipped/focused tests, and repository coverage gate retained.

## Project-specific Ralph Loop

**Goal:** prove the catalogue and UI regressions are removed without changing unrelated behavior.

**Current state:** the packaged asset is a 28,672-byte fixture, `tool/catalogue.py verify` fails, screenshots show 5 talks/3 teachers and a washed-out brown/cream UI.

**Acceptance criteria:**

- `python3 tool/catalogue.py verify` passes on the packaged database.
- SQLite inspection returns 30,563 audio rows, 257 teachers, and 429 audio collections.
- Debug and release runtime validation reject fixture-sized assets.
- Navigation selection uses a matched Material container/foreground pair.
- App surfaces are neutral, primary emphasis is forest green, and search bars have no default heavy elevation.
- Existing behavior and tests remain intact.

**Fast inner-loop commands:**

```bash
python3 tool/catalogue.py verify
python3 tool/repository_check.py
flutter test test/data/production_catalogue_regression_test.dart
flutter test test/data/catalogue_asset_installer_test.dart
flutter test test/ui/app_smoke_test.dart
flutter analyze --fatal-infos --fatal-warnings
```

**Full release-loop commands:**

```bash
make verify-catalogue
make repository-check
make format-check
make lint
make check-tests
make coverage
make build-android
make build-ios
git bundle verify dhamma-echo-flutter-mobile-fixed.bundle
```

**Known risks:** Flutter/Dart/iOS toolchains may be unavailable in the execution environment; those gates must be reported `BLOCKED`, never assumed.

**Exit conditions:** all executable gates available in the environment pass; unavailable platform gates are explicitly `BLOCKED`; the Git bundle is verified and clone-tested.

---

### Task 1: Add a production-catalogue regression guard

**Files:**
- Create: `test/data/production_catalogue_regression_test.dart`
- Modify: `test/data/catalogue_asset_installer_test.dart`

**Interfaces:**
- Consumes: `CatalogueAssetInstaller.productionByteLength`, `SqfliteCatalogueRepository`.
- Produces: a regression suite that fails when the packaged asset is a fixture or has the wrong baseline counts.

- [ ] **Step 1: Add a failing packaged-catalogue test**

Create a test that opens `assets/catalogue/dhamma.db` read-only with `databaseFactoryFfi`, calls `getSummary()`, calls `searchCollections(const CollectionSearchRequest(limit: 24))`, and asserts:

```dart
expect(summary.totalAudio, 30563);
expect(summary.totalTeachers, 257);
expect(collections.total, 429);
```

Also assert `File('assets/catalogue/dhamma.db').lengthSync()` equals `CatalogueAssetInstaller.productionByteLength`.

- [ ] **Step 2: Verify RED**

Run:

```bash
flutter test test/data/production_catalogue_regression_test.dart
```

Expected before the asset replacement: FAIL because the current fixture reports 5 audio talks, 3 teachers, 3 collections, and 28,672 bytes.

- [ ] **Step 3: Tighten installer regression expectations**

Change the small structurally-valid SQLite test so `validateReleaseAsset` must throw for a fixture-sized database. Add an asset-backed test that passes for the real packaged database.

- [ ] **Step 4: Verify the focused tests still fail only because the real asset is not installed**

Run:

```bash
flutter test test/data/catalogue_asset_installer_test.dart test/data/production_catalogue_regression_test.dart
```

- [ ] **Step 5: Commit tests**

```bash
git add test/data/catalogue_asset_installer_test.dart test/data/production_catalogue_regression_test.dart
git commit -m "test: guard the production catalogue asset"
```

### Task 2: Package and enforce the production SQLite catalogue

**Files:**
- Replace: `assets/catalogue/dhamma.db`
- Modify: `lib/data/catalogue_asset_installer.dart`
- Modify: `Makefile`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: the user-supplied database with the production size/SHA identity.
- Produces: a packaged production database opened read-only by the existing `main.dart` composition root.

- [ ] **Step 1: Replace the fixture asset with the verified production database**

Copy the supplied database to `assets/catalogue/dhamma.db` without transforming it.

- [ ] **Step 2: Make runtime size validation apply in debug and release**

In `CatalogueAssetInstaller.validateReleaseAsset`, keep the SQLite header check and replace the release-only size branch with an unconditional size check:

```dart
if (bytes.lengthInBytes != productionByteLength) {
  throw StateError(
    'The production Dhamma catalogue is missing or invalid. Verify assets/catalogue/dhamma.db before running the app.',
  );
}
```

- [ ] **Step 3: Avoid recopying 27 MB on every debug launch**

Because the destination filename is already versioned from `productionSha256`, copy only when the destination is missing or its size differs:

```dart
if (!await destination.exists() ||
    await destination.length() != bytes.length) {
  await destination.writeAsBytes(bytes, flush: true);
}
```

- [ ] **Step 4: Make the production asset part of normal verification**

Add `verify-catalogue` to the `verify` target and change CI from `make catalogue` to `make verify-catalogue`, so CI proves the checked-in database rather than silently downloading a replacement.

- [ ] **Step 5: Verify GREEN**

Run:

```bash
python3 tool/catalogue.py verify
flutter test test/data/catalogue_asset_installer_test.dart test/data/production_catalogue_regression_test.dart
```

Expected: both commands pass.

- [ ] **Step 6: Commit**

```bash
git add assets/catalogue/dhamma.db lib/data/catalogue_asset_installer.dart Makefile .github/workflows/ci.yml
git commit -m "fix: ship the production SQLite catalogue"
```

### Task 3: Repair the Material 3 theme regression

**Files:**
- Modify: `lib/app/dhamma_echo_app.dart`
- Modify: `test/ui/app_smoke_test.dart`

**Interfaces:**
- Consumes: Material 3 theme APIs already provided by Flutter.
- Produces: neutral light surfaces, forest-green selection/action colors, zero-elevation search bars, and matched navigation selection colors.

- [ ] **Step 1: Add a failing theme regression test**

After pumping `DhammaEchoApp`, inspect `ThemeData` and assert the primary seed direction and matched navigation roles:

```dart
expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAF7));
expect(theme.navigationBarTheme.indicatorColor, theme.colorScheme.secondaryContainer);
expect(theme.searchBarTheme.elevation?.resolve(<WidgetState>{}), 0);
```

- [ ] **Step 2: Verify RED**

Run:

```bash
flutter test test/ui/app_smoke_test.dart
```

Expected before the theme change: FAIL because the scaffold is `#FCF9F2`, navigation uses `#F0EEE7`, and SearchBar keeps default elevation.

- [ ] **Step 3: Replace the hand-built brown scheme**

Build the scheme from a forest-green seed and neutral surface:

```dart
final scheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF2F5D50),
  brightness: Brightness.light,
).copyWith(surface: const Color(0xFFF8FAF7));
```

Use `scheme.secondaryContainer` for `NavigationBarThemeData.indicatorColor` rather than an unrelated neutral color. Keep white content cards with `scheme.outlineVariant` borders. Add `SearchBarThemeData` with zero elevation, white background, and a subtle outline. Keep system fonts.

- [ ] **Step 4: Verify GREEN**

Run:

```bash
flutter test test/ui/app_smoke_test.dart
flutter analyze --fatal-infos --fatal-warnings
```

- [ ] **Step 5: Commit**

```bash
git add lib/app/dhamma_echo_app.dart test/ui/app_smoke_test.dart
git commit -m "fix: restore readable Material 3 theming"
```

### Task 4: Clean the high-traffic list and empty-state surfaces

**Files:**
- Modify: `lib/ui/components/teacher_card.dart`
- Modify: `lib/ui/components/track_tile.dart`
- Modify: `lib/ui/components/async_message.dart`
- Modify: `lib/ui/screens/home_screen.dart`
- Modify: `lib/ui/screens/library_screen.dart`
- Modify: `test/ui/detail_settings_regression_test.dart`

**Interfaces:**
- Consumes: the repaired app theme and existing controllers/models.
- Produces: consistent neutral cards/empty states and readable metadata without changing navigation or catalogue semantics.

- [ ] **Step 1: Add widget regression assertions**

Assert that featured teacher surfaces use the current theme primary container rather than a hard-coded orange role and that empty states render within a neutral surface with the same existing copy and semantics.

- [ ] **Step 2: Verify RED**

Run the focused UI test file and confirm the new expectations fail against the current components.

- [ ] **Step 3: Implement the smallest visual cleanup**

Use theme roles only, remove brown-specific emphasis, preserve 48 dp controls, keep two-line title truncation, and keep favorite/queue behavior unchanged. Do not add a new UI package or invented teacher artwork.

- [ ] **Step 4: Verify GREEN and adjacent behavior**

Run:

```bash
flutter test test/ui/app_smoke_test.dart test/ui/detail_settings_regression_test.dart
flutter analyze --fatal-infos --fatal-warnings
```

- [ ] **Step 5: Commit**

```bash
git add lib/ui test/ui
git commit -m "fix: clean catalogue reading surfaces"
```

### Task 5: Update documentation, run release gates, and create the bundle

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture/data-flow.md`
- Modify: `docs/architecture/release.md`
- Modify: `CHANGELOG.md`
- Create: `dhamma-echo-flutter-mobile-fixed.bundle`

**Interfaces:**
- Consumes: the final source tree and quality scripts.
- Produces: accurate local-catalogue documentation and the requested cloneable Git bundle.

- [ ] **Step 1: Document the bundled production database**

State that normal development/builds use the checked-in verified production catalogue and that `make catalogue` is only an explicit refresh mechanism. Document that runtime metadata browsing is offline/local and only approved audio playback uses the network.

- [ ] **Step 2: Run Python/repository gates**

```bash
make verify-catalogue
make repository-check
python3 tool/check_tests.py
```

- [ ] **Step 3: Run Flutter release gates when the toolchain is available**

```bash
make format-check
make lint
make coverage
make build-android
make build-ios
```

Record unavailable toolchain/platform gates as `BLOCKED` rather than `PASS`.

- [ ] **Step 4: Perform simulator visual verification when available**

Inspect Home, Explore, Collections, Teachers, Library, search/filter states, selected navigation states, empty states, Burmese text wrapping, scrolling, and mini-player. If no Flutter simulator/runtime is available, mark the visual gate `BLOCKED`.

- [ ] **Step 5: Commit documentation and final source changes**

```bash
git add README.md docs CHANGELOG.md
git commit -m "docs: describe local production catalogue flow"
```

- [ ] **Step 6: Create, verify, and clone-test the bundle**

```bash
git bundle create /mnt/data/dhamma-echo-flutter-mobile-fixed.bundle --all
git bundle verify /mnt/data/dhamma-echo-flutter-mobile-fixed.bundle
rm -rf /mnt/data/dhamma-echo-flutter-mobile-fixed-clone
git clone /mnt/data/dhamma-echo-flutter-mobile-fixed.bundle /mnt/data/dhamma-echo-flutter-mobile-fixed-clone
git -C /mnt/data/dhamma-echo-flutter-mobile-fixed-clone log -1 --oneline
python3 /mnt/data/dhamma-echo-flutter-mobile-fixed-clone/tool/catalogue.py verify --output /mnt/data/dhamma-echo-flutter-mobile-fixed-clone/assets/catalogue/dhamma.db
```
