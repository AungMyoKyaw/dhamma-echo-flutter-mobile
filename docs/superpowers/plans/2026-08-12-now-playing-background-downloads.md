# Now Playing, Background Playback, and Offline Downloads Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make playback state immediately visible and persistent, eliminate playback-induced detail-screen flicker, support OS background media controls, and add trusted app-private offline downloads.

**Architecture:** Keep `PlaybackController` as the single player state owner, stop forwarding high-frequency player ticks through `AppController`, and let playback UI listen directly to the player. Add the official `just_audio_background` adapter configuration and a small app-private `DownloadManager` that reuses the existing media allowlist and supplies a preferred local URI to playback.

**Tech Stack:** Flutter/Dart, Material 3, `just_audio 0.10.6`, `just_audio_background 0.0.1-beta.17`, `path_provider 2.1.6`, `dart:io`, existing `sqflite` catalogue/local state.

## Global Constraints

- Preserve existing approved-host playback policy and MP3-only playback.
- WMA stays searchable but unavailable for playback/download.
- Preserve generated Android/iOS folder strategy; platform changes belong in `tool/configure_platforms.py`.
- Add no general-purpose state-management or download package.
- Keep current light-only visual direction and existing screen hierarchy.
- Keep all app media/user state on-device.
- Every production dependency change must be justified and lockfile diff inspected after `flutter pub get`.
- Required release gates remain format, zero-error analyze, no skipped tests, 100% project-owned coverage, production builds, security checks, visual verification, documentation, and valid clone-tested Git bundle.

---

## Project-specific Ralph Loop

### Goal

Prove that audio immediately surfaces now-playing UI, detail screens remain stable while progress changes, background audio is configured for Android/iOS, and downloads are safe/local-first without breaking catalogue behavior.

### Current state

- Existing `MiniPlayer` exists but its visibility depends on `PlaybackController.current`.
- `PlaybackController.play()` awaits the long-running `just_audio.play()` future before setting current state.
- `AppController` forwards every playback notification to all UI listeners.
- Collection detail creates a data future inside `build()`.
- No background-service platform configuration or download manager exists.

### Acceptance criteria

- A valid play request returns after source preparation/start, not after later pause/completion, and current track is visible.
- Mini player remains accessible on main and pushed detail/settings routes.
- Playback position events do not cause global catalogue rebuild/refetch.
- Background audio metadata and Android/iOS configuration match official `just_audio_background` requirements.
- Playable approved MP3s can download atomically into app-private storage, delete, and play local-first.
- Download failure/untrusted/unsupported paths leave no completed file.
- Existing favorites/history/resume/queue/search/detail behavior remains intact.

### Fast inner-loop validation commands

```bash
dart format lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test test/player/playback_controller_test.dart
flutter test test/downloads/download_manager_test.dart
flutter test test/app/app_controller_test.dart
flutter test test/ui/detail_settings_regression_test.dart
python3 -m py_compile tool/configure_platforms.py
python3 tool/repository_check.py
```

When Flutter/Dart are unavailable in the execution environment, mark those gates `BLOCKED`; do not convert source inspection into a pass.

### Full release-loop validation commands

```bash
make bootstrap
flutter pub get
make format-check
make lint
make check-tests
make coverage
make verify-catalogue
make repository-check
make build-android
make build-ios
python3 -m py_compile tool/configure_platforms.py
git diff --check
git status --short
git bundle create dhamma-echo-flutter-mobile.bundle --all
git bundle verify dhamma-echo-flutter-mobile.bundle
git clone dhamma-echo-flutter-mobile.bundle /tmp/dhamma-echo-bundle-clone
```

### Known risks

- Background media service setup is platform-sensitive and generated folders are absent until bootstrap.
- The execution container may lack Flutter/Dart and simulator runtimes.
- Remote download integration depends on production host/network behavior and cannot be proven with live network when unavailable; deterministic fake-client tests cover app logic.
- A long-running `just_audio.play()` future must not be awaited in user-facing start/toggle paths.

### Exit conditions

- Requested behavior implemented with regression tests committed.
- Every executable release gate has real evidence and is `PASS`, `FAIL`, `BLOCKED`, or `NOT APPLICABLE`.
- No in-scope `FAIL` remains.
- External environment limitations are reported as `BLOCKED` rather than guessed.
- Git bundle verifies and clone-tests successfully.

---

### Task 1: Playback start semantics and background metadata

**Files:**
- Modify: `lib/player/playback_port.dart`
- Modify: `lib/player/playback_controller.dart`
- Modify: `test/player/playback_controller_test.dart`

**Interfaces:**
- `PlaybackPort.load(AudioTrack track, Uri uri)` prepares a tagged local/remote source.
- `PlaybackController.play(AudioTrack track, {double resumeAt = 0, Uri? preferredUri})` tries preferred local then trusted remote sources.
- `PlaybackController.toggle()` must update resume state without awaiting the lifetime of port playback.

- [ ] Add failing regression tests using a fake port whose `play()` future remains pending and assert `current/playing` become visible before that future completes.
- [ ] Add a failing test that `preferredUri` is attempted first and remote trust candidates remain fallback.
- [ ] Run focused player tests and record the expected failure. If Flutter is unavailable, record the gate as `BLOCKED`.
- [ ] Change the port load API to include track metadata and make `JustAudioPlaybackPort` use `AudioSource.uri(..., tag: MediaItem(...))`.
- [ ] Refactor start/resume into generation-guarded asynchronous helpers so successful source preparation establishes current state immediately.
- [ ] Run focused player tests and analyze; keep only the minimal state changes needed for green behavior.
- [ ] Commit playback changes.

### Task 2: Stop high-frequency app rebuilds and detail refetch

**Files:**
- Modify: `lib/app/app_controller.dart`
- Modify: `lib/ui/components/mini_player.dart`
- Modify: `lib/ui/components/track_tile.dart`
- Modify: `lib/ui/screens/player_screen.dart`
- Modify: `lib/ui/screens/teacher_detail_screen.dart`
- Modify: `lib/ui/screens/collection_detail_screen.dart`
- Modify: `lib/ui/screens/settings_screen.dart`
- Modify: `test/app/app_controller_test.dart`
- Modify: `test/ui/detail_settings_regression_test.dart`

**Interfaces:**
- `AppController` keeps playback orchestration but does not proxy every raw player notification.
- Playback-owned widgets subscribe directly to `controller.playback`.

- [ ] Add a failing AppController regression test proving a pure position event does not notify global listeners.
- [ ] Add a collection-detail regression test with a counting catalogue proving a playback tick does not issue a second detail fetch.
- [ ] Add a route regression test proving an active `MiniPlayer` remains visible on detail/settings surfaces.
- [ ] Cache collection detail future in state and remove playback-tick dependence from detail bodies.
- [ ] Make mini player, track row playback indicator, and full-player controls listen directly to `PlaybackController`.
- [ ] Add a thin mini-player progress rail while preserving current spacing and Material semantics.
- [ ] Add mini player to pushed detail/settings `Scaffold.bottomNavigationBar`.
- [ ] Run focused controller/widget tests and analyzer.
- [ ] Commit flicker/persistent-player changes.

### Task 3: Trusted offline download manager

**Files:**
- Create: `lib/downloads/download_client.dart`
- Create: `lib/downloads/download_manager.dart`
- Create: `test/downloads/download_manager_test.dart`

**Interfaces:**
- `DownloadClient.get(Uri)` returns status, content length, and a byte stream without following redirects.
- `DownloadManager.initialize()` scans completed files and removes stale partials.
- `DownloadManager.download(AudioTrack)` returns `Future<bool>`.
- `DownloadManager.delete(int trackId)` removes the completed local file.
- `DownloadManager.localUriFor(int trackId)` returns a file URI only for known completed downloads.
- `DownloadManager.progressFor(int trackId)` and `errorFor(int trackId)` expose UI state.

- [ ] Write failing tests for successful atomic write/progress, approved-host fallback, untrusted/WMA rejection, failed cleanup, duplicate suppression, initialization scan/stale `.part` cleanup, and delete.
- [ ] Run download tests and record expected failures or environment blocker.
- [ ] Implement the injected client abstraction and `dart:io HttpClient` production client with redirects disabled.
- [ ] Implement deterministic `.part` to `.mp3` download lifecycle and state notifications.
- [ ] Run focused tests/analyzer.
- [ ] Commit download core.

### Task 4: Integrate offline library and local-first playback

**Files:**
- Modify: `lib/app/app_controller.dart`
- Modify: `lib/main.dart`
- Modify: `lib/ui/components/track_tile.dart`
- Modify: `lib/ui/screens/player_screen.dart`
- Modify: `lib/ui/screens/library_screen.dart`
- Modify: `test/app/app_controller_test.dart`
- Modify: `test/ui/app_smoke_test.dart`
- Modify: `test/ui/detail_settings_regression_test.dart`

**Interfaces:**
- `AppController.downloadManager` exposes `DownloadManager` for scoped UI listeners.
- `AppController.downloadedTracks` is catalogue-resolved local media.
- `AppController.downloadTrack/removeDownload` coordinate manager + library list.
- `AppController.play` supplies a downloaded local URI as `preferredUri`.

- [ ] Add failing controller tests for downloaded-track resolution and local-first playback.
- [ ] Add failing widget tests for download action state and Library Downloads section.
- [ ] Initialize `DownloadManager` from an app-support directory in `main` and inject it into `AppController`.
- [ ] Add row/full-player download/remove controls and progress state.
- [ ] Add Library Downloads section with empty and populated states.
- [ ] Run focused tests/analyzer.
- [ ] Commit integration/UI changes.

### Task 5: Platform background-audio bootstrap

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock` only through `flutter pub get`
- Modify: `tool/configure_platforms.py`
- Modify: `test` or tooling fixtures if required to validate string transforms

**Interfaces:**
- `main()` initializes `JustAudioBackground` before constructing/running the app.
- `tool/configure_platforms.py` idempotently applies Android foreground-media-service and iOS background-audio declarations.

- [ ] Add `just_audio_background ^0.0.1-beta.17` and direct `path_provider ^2.1.6` dependencies.
- [ ] Extend Android manifest configuration with wake lock, foreground service/media playback permissions, `AudioServiceActivity`, `AudioService`, and `MediaButtonReceiver`.
- [ ] Extend iOS plist configuration with `UIBackgroundModes` → `audio`.
- [ ] Extend verification to fail if required declarations are absent.
- [ ] Run `flutter pub get`, inspect the exact dependency/lockfile diff, and run platform bootstrap verification. If the Flutter SDK/network is unavailable, leave the lockfile un-fabricated and mark this release gate `BLOCKED`.
- [ ] Commit platform/dependency changes.

### Task 6: Documentation, architecture, and release proof

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture/modules.md`
- Modify: `docs/architecture/playback-sequence.md`
- Modify/Create: download/background playback Mermaid flow under `docs/architecture/`
- Modify relevant contributor/security docs only where behavior changed.

**Interfaces:**
- Documentation commands must match the repository.
- Architecture diagrams must show local download trust/storage and background media-service boundaries.

- [ ] Update README features, privacy/security, dependencies, bootstrap behavior, and troubleshooting.
- [ ] Update architecture diagrams for playback/background/download data flow.
- [ ] Run repository/documentation checks and Mermaid/source sanity review.
- [ ] Run the complete release Ralph Loop from the strongest reproducible state available.
- [ ] Mark every gate exactly `PASS`, `FAIL`, `BLOCKED`, or `NOT APPLICABLE` with evidence.
- [ ] Create the final Git bundle with `--all`, verify it, clone it, and inspect the clone.
- [ ] Commit release/docs changes and recreate the final bundle after that commit.
