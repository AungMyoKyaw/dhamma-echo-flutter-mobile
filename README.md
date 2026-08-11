# Dhamma Echo — Flutter Mobile

A quiet Flutter mobile library for discovering and listening to Dhamma talks on Android and iOS.

This is a native Flutter port of the current Dhamma Echo desktop product. The supplied desktop Git bundle was used as the product source of truth; the mobile app preserves catalogue semantics, search/filter behavior, collections, teachers, local favorites/history/resume state, queue behavior, and the approved-host playback policy while adapting navigation and player surfaces for phones.

## Features

- Home, Explore, Collections, Teachers, Library, Settings, collection detail, teacher detail, and full-player screens.
- Search 30,563 audio talks from the current production catalogue and browse 257 teachers / 429 audio collections.
- Filter by language, format, teacher, category, and collection.
- Explicit 50-talk and 24-collection pagination.
- Curated teacher ordering with IDs `16, 42, 40, 53, 61, 8`.
- Local favorites, 100-entry listening history, 500-entry resume map, rate, and volume settings.
- Queue, next track, seek, 15-second jumps, volume, and rates from `0.75×` through `2×`.
- MP3 playback only from approved Dhamma Download hosts, with HTTP-to-HTTPS normalization and alternate-host retry.
- WMA remains searchable but intentionally unavailable in the mobile player.
- No accounts, analytics, telemetry, cloud sync, offline downloads, background playback service, or bundled fonts.

## Technology

- Flutter 3.44.9 baseline / Dart 3.12+
- Material 3
- `sqflite 2.4.3`
- `just_audio 0.10.6`
- `path 1.9.1`
- `flutter_lints 6.0.0`

The production dependencies are intentionally small. No router package or external state-management framework is used; `Navigator`, `ChangeNotifier`, and platform capabilities are enough for this scope.

## Repository layout

```text
lib/                    Flutter production code
  app/                  orchestration and app shell
  core/                 validation and policy
  data/                 SQLite and local persistence
  domain/               immutable models
  player/               playback state and just_audio adapter
  ui/                   screens and components
test/                   unit, repository, controller, and widget tests
assets/catalogue/       bundled catalogue slot
assets/images/          source app icon
docs/architecture/      Mermaid engineering diagrams
tool/                   reproducible catalogue/platform/quality tooling
.github/workflows/      CI
```

## Requirements

- Flutter 3.44.9 stable with Dart 3.12+
- Android SDK for Android builds
- Xcode on macOS for iOS builds
- Python 3.13+ for repository/release tooling

Install the pinned tooling-only Python packages:

```bash
python3 -m pip install -r requirements-tooling.txt
```

## Catalogue

The Git repository ships the verified production SQLite catalogue at `assets/catalogue/dhamma.db`. Browsing metadata is local application data; the network is only used when the player opens an approved audio URL stored in SQLite.

Verify the checked-in catalogue before building:

```bash
make verify-catalogue
```

`make catalogue` remains an explicit maintenance command for refreshing the asset from the public desktop release. It is not part of normal development or CI.

Production identity:

```text
size    27750400 bytes
sha256  d88cfda6d761d0e682dac3bf29ab3b1d7019496a114defe057bfc55a6e746d31
```

`tool/catalogue.py` verifies the bundled database by exact byte length and SHA-256. Its optional `fetch` path extracts the database from a packaged desktop `.app.tar.gz`, reads the file in memory rather than extracting arbitrary archive paths, verifies identity, and replaces the asset atomically. The app copies the bundled database into its database directory only when needed and opens it read-only.

## Bootstrap Android and iOS

Platform folders are generated from the installed Flutter SDK so Gradle/Xcode templates stay aligned with the selected Flutter version:

```bash
make bootstrap
```

The bootstrap step then applies:

- bundle/application ID `com.aungmyokyaw.dhammaecho`
- display name `Dhamma Echo`
- Android Internet permission
- Android and iOS app-icon variants generated from `assets/images/app-icon.png`

## Development

```bash
make bootstrap
make deps
flutter run
```

## Quality commands

```bash
make format
make format-check
make lint
make typecheck
make check-tests
make test
make coverage
make repository-check
make verify
```

`make check-tests` rejects skipped, disabled, and focused tests. `make coverage` enforces 100% for every metric emitted by Flutter's LCOV output. Flutter's standard LCOV report does not expose a distinct statement metric on every toolchain; the release report must not claim a statement/branch/function metric that the actual report did not produce.

## Build

A production database must pass `make verify-catalogue` first.

Android:

```bash
make build-android
```

iOS compilation without signing:

```bash
make build-ios
```

Store signing and publication remain external release steps.

## Security and privacy

- Catalogue queries are parameterized.
- Catalogue database is opened read-only.
- Audio URLs are allowlisted to `dhammadownload.com` / `www.dhammadownload.com`; custom ports and URL credentials are rejected.
- Approved HTTP catalogue URLs are upgraded to HTTPS.
- No application secrets or user accounts exist.
- Favorites, history, resume positions, and preferences remain on-device.

See [SECURITY.md](SECURITY.md) and the [system context diagram](docs/architecture/context.md).

## Architecture

- [Extracted mobile requirements](docs/requirements.md)
- [System context](docs/architecture/context.md)
- [Module architecture](docs/architecture/modules.md)
- [Catalogue and local-state flow](docs/architecture/data-flow.md)
- [Playback sequence](docs/architecture/playback-sequence.md)
- [Build/release flow](docs/architecture/release.md)
- [Mobile design specification](docs/superpowers/specs/2026-08-10-dhamma-echo-flutter-mobile-design.md)
- [Implementation plan](docs/superpowers/plans/2026-08-10-dhamma-echo-flutter-mobile.md)

## Troubleshooting

**Catalogue verification fails** — restore the checked-in production `assets/catalogue/dhamma.db` or explicitly refresh it with `make catalogue`, then run `make verify-catalogue`.

**Network MP3 does not play** — the player intentionally rejects any host outside the two approved Dhamma Download hostnames and rejects WMA.

**Android/iOS folders are absent** — run `make bootstrap` with Flutter 3.44.9 installed.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All changes must keep format/analyze/tests clean, preserve the no-skipped-tests rule, and avoid weakening the media URL trust boundary.

## License

MIT. See [LICENSE](LICENSE).
