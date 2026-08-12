# Dhamma Echo — Flutter Mobile

A quiet Flutter mobile library for discovering and listening to Dhamma talks on Android and iOS.

This is a native Flutter port of the current Dhamma Echo desktop product. The supplied desktop Git bundle was used as the product source of truth; the mobile app preserves catalogue semantics, search/filter behavior, collections, teachers, local favorites/history/resume state, queue behavior, and the approved-host playback policy while adapting navigation and player surfaces for phones.

## Features

- Home, Explore, Collections, Teachers, Library, Settings, collection detail, teacher detail, and full-player screens.
- Search 30,563 audio talks from the current production catalogue and browse 257 teachers / 429 audio collections.
- Filter by language, format, teacher, category, and collection.
- Explicit 50-talk and 24-collection pagination.
- Last-request-wins search and playback orchestration prevents stale asynchronous completions from replacing newer user intent.
- Curated teacher ordering with IDs `16, 42, 40, 53, 61, 8`.
- Local favorites, 100-entry listening history, 500-entry resume map, rate, and volume settings.
- Persistent mini-player plus a full Now Playing screen with queue, next track, seek, 15-second jumps, volume, and rates from `0.75×` through `2×`.
- Tap anywhere on a playable talk row to start playback; download, favorite, and queue controls remain independent actions.
- Source duration emitted during loading is preserved, keeping elapsed time, total time, and seek progress synchronized.
- Background playback with lock-screen, notification, headset, and supported system media controls through `just_audio_background`.
- App-private offline MP3 downloads with progress, local-first playback, removal, and a Downloads section in Library.
- MP3 playback only from approved Dhamma Download hosts, with HTTP-to-HTTPS normalization and alternate-host retry.
- WMA remains searchable but intentionally unavailable in the mobile player.
- Forest-and-parchment Material 3 color system with WCAG AA-certified semantic color pairs and adaptive bottom-navigation labels at accessibility text sizes.
- Serialized atomic local-state saves prevent overlapping playback updates from racing over the shared temporary file.
- No accounts, analytics, telemetry, cloud sync, public-storage export, or bundled fonts.

## Technology

- Flutter 3.44.9 baseline / Dart 3.12+
- Material 3
- `sqflite 2.4.3`
- `just_audio 0.10.6`
- `just_audio_background 0.0.1-beta.17`
- `path 1.9.1`
- `path_provider 2.1.6`
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
assets/images/          AI-generated app-icon source, master, and Android adaptive layers
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

The Git repository ships the verified production SQLite catalogue at `assets/catalogue/dhamma.db`. Browsing metadata is local application data; network access is limited to streaming or downloading approved audio URLs stored in SQLite.

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
- Android Internet, wake-lock, and foreground media-playback permissions
- Android audio service, media-button receiver, and foreground playback service declaration
- iOS `audio` background mode
- iOS app-icon variants generated from an opaque 1024 px full-bleed master
- Android legacy launcher icons plus adaptive foreground/background/monochrome layers
- AI-generated icon source retained as `assets/images/app-icon-ai-source.png`; platform masters/layers are derived from it

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
make platform-config-test
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
- Stream and download URLs are allowlisted to `dhammadownload.com` / `www.dhammadownload.com`; custom ports and URL credentials are rejected.
- Approved HTTP catalogue URLs are upgraded to HTTPS; download redirects are not followed.
- Offline media is written to app-private storage through a temporary `.part` file and only promoted after a complete successful response.
- No application secrets or user accounts exist.
- Favorites, history, resume positions, and preferences remain on-device.

Local state is written atomically through `state.json.tmp` and then promoted to `state.json`. Save requests are serialized in call order so rapid playback events cannot remove another request's temporary file or allow an older snapshot to overwrite newer state.

See [SECURITY.md](SECURITY.md) and the [system context diagram](docs/architecture/context.md).

## Architecture

- [Extracted mobile requirements](docs/requirements.md)
- [System context](docs/architecture/context.md)
- [Module architecture](docs/architecture/modules.md)
- [Catalogue and local-state flow](docs/architecture/data-flow.md)
- [Playback sequence](docs/architecture/playback-sequence.md)
- [Async request concurrency](docs/architecture/concurrency.md)
- [Background playback and offline downloads](docs/architecture/offline-playback.md)
- [Forest-and-parchment color-system design](docs/superpowers/specs/2026-08-12-forest-parchment-color-system-design.md)
- [Color-system implementation plan](docs/superpowers/plans/2026-08-12-forest-parchment-color-system.md)
- [Color and reflow certification](docs/reports/2026-08-12-color-system-certification.md)
- [Build/release flow](docs/architecture/release.md)
- [Mobile design specification](docs/superpowers/specs/2026-08-10-dhamma-echo-flutter-mobile-design.md)
- [Implementation plan](docs/superpowers/plans/2026-08-10-dhamma-echo-flutter-mobile.md)
- [Production-readiness design](docs/superpowers/specs/2026-08-12-production-readiness-design.md)
- [Production-readiness Ralph Loop](docs/superpowers/plans/2026-08-12-production-readiness.md)

## Troubleshooting

**Catalogue verification fails** — restore the checked-in production `assets/catalogue/dhamma.db` or explicitly refresh it with `make catalogue`, then run `make verify-catalogue`.

**Network MP3 does not play** — the player intentionally rejects any host outside the two approved Dhamma Download hostnames and rejects WMA.

**A download fails** — only playable approved-host MP3 talks can be stored offline. Failed or incomplete responses are cleaned up and the app retries only the alternate approved Dhamma Download hostname.

**Background controls are missing** — rerun `make bootstrap` so the generated Android/iOS projects receive the media-service and iOS background-audio declarations.

**Now Playing shows `0:00` total duration** — stop the running app and launch a freshly built version. Current playback preserves duration metadata emitted while the source loads.

**A `state.json.tmp` rename throws `PathNotFoundException`** — stop the running app and launch a freshly built version. Current persistence serializes overlapping state saves; the error indicates an older build is still running.

**Android/iOS folders are absent** — run `make bootstrap` with Flutter 3.44.9 installed.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All changes must keep format/analyze/tests clean, preserve the no-skipped-tests rule, and avoid weakening the media URL trust boundary.

## License

MIT. See [LICENSE](LICENSE).
