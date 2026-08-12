# Dhamma Echo Flutter Production Readiness Design

Date: 2026-08-12

## Goal

Harden the existing Flutter mobile app for production without changing its product scope, catalogue semantics, trust boundaries, package manager, Flutter version, or established visual identity.

## Audited Baseline

- Flutter is pinned to 3.44.9 stable / Dart 3.12.x in the repository and CI.
- Runtime dependencies remain intentionally small: Flutter SDK, `just_audio`, `just_audio_background`, `path`, `path_provider`, and `sqflite`.
- The forest/parchment Material 3 palette has already been visually certified and should not be replaced.
- The existing screenshots show one clear interaction-density issue: each track row dedicates three trailing icon buttons plus a leading play button, causing aggressive title truncation on narrow phones.
- AppController searches can resolve out of order because concurrent requests have no stale-result guard.
- PlaybackController already has a generation counter for asynchronous playback startup, but `play()` can still commit stale track state after a newer load starts.
- The existing download/remove widget regression uses `pumpAndSettle()` around an asynchronously animated progress indicator; the prior release report records this test as hanging.
- Repository-only checks pass. Flutter/Dart executables are not available in the current sandbox, so local Flutter analysis/build/runtime verification is an external gate unless a toolchain becomes available.

## Design Direction

### Visual identity

Preserve the existing Material 3 forest/parchment system. Design.md was consulted with the existing forest, neutral, brick-error, and parchment keys. The generated roles confirm the same overall family, but the current manually certified white-on-forest and dark-on-sage pairs have stronger established contrast and product continuity, so they remain canonical.

### Track rows

Keep the primary play/pause affordance visible at the leading edge. Replace the three trailing actions with one overflow menu containing Download/Remove download, Favorite/Remove favorite, and Add to queue. This gives track title and metadata more horizontal space while preserving 48dp Material controls and tooltips/labels.

For the current track, the leading control must toggle pause/resume instead of reloading the same source. The icon and tooltip must describe the action the user will trigger, not the current state.

### Search consistency

Audio, collection, and teacher searches use last-request-wins semantics. A slower earlier request must never replace data or error state produced by a newer request. Existing pagination and filters remain unchanged.

### Playback consistency

Only the newest `play()` request may commit controller state. If an earlier `load()` resumes after a newer play request has started, it exits without replacing the current track, position, loading, or playing state.

### Test reliability and accessibility

Replace `pumpAndSettle()` in the download/remove row regression with bounded, state-driven pumping so an indeterminate/determinate progress indicator cannot keep the test alive forever.

Add accessibility guideline assertions to the compact track-row surface for labeled tap targets and Android/iOS minimum tap sizes. Keep all icon-only controls labeled through tooltips.

## Architecture

No new production dependency is required. Existing boundaries remain:

- `AppController`: app-level query/state orchestration.
- `PlaybackController`: platform-independent playback state machine.
- `PlaybackPort`: just_audio adapter boundary.
- `DownloadManager`: app-private offline media.
- UI widgets/screens: Material 3 presentation.

The change adds request-generation guards inside existing controllers and compacts only the track-row action presentation. No routing, state-management, storage, or database migration is introduced.

## Error Handling

- Stale async successes and errors are ignored.
- Current request failures continue using existing user-visible error fields.
- Playback source fallback remains restricted to the existing local-file candidate plus approved Dhamma Download hosts.
- Download action failures continue to surface through the existing SnackBar/error state.

## Accessibility

- Minimum Material tap targets remain 48dp or larger.
- Every icon-only action has a semantic tooltip or menu label.
- The track title remains two lines with ellipsis, but receives materially more width on narrow screens.
- Existing large-text navigation behavior remains unchanged.
- No information is encoded only by color.

## Performance / Lightweight Constraints

- Add zero production dependencies.
- Keep the existing six runtime dependency entries (including Flutter SDK).
- Avoid app-wide playback-position notifications.
- Keep search concurrency protection O(1) with integer generations.
- Reduce per-track action widget density from three trailing buttons to one overflow control.

## Ralph Loop

### Goal

Ship the smallest verified hardening pass that fixes the audited production and UI/UX risks without scope creep.

### Current state

- Clean Git bundle clone on branch `production-readiness-2026-08-12`.
- Repository contract, platform-config Python tests, disabled-test check, and catalogue verification pass.
- Flutter/Dart commands are not currently available locally.

### Acceptance criteria

- Latest search request wins for audio, collections, and teachers.
- Latest playback request wins when loads overlap.
- Current-track leading action pauses/resumes without reloading.
- Track rows use a single overflow action surface and retain all actions.
- Download/remove widget test uses bounded pumping.
- Accessibility tests cover labels and target size for the revised track row.
- No new production dependency.
- Repository docs/diagrams/CI remain valid.
- Full Flutter gates are executed if a toolchain becomes available; otherwise they are reported BLOCKED, never assumed PASS.

### Fast inner-loop validation

```bash
python3 tool/check_tests.py
python3 tool/repository_check.py
python3 tool/test_configure_platforms.py
python3 tool/catalogue.py verify
git diff --check
```

When Flutter is available:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test test/app/app_controller_test.dart
flutter test test/player/playback_controller_test.dart
flutter test test/ui/detail_settings_regression_test.dart
```

### Full release-loop validation

```bash
make bootstrap
make deps
make repository-check
make platform-config-test
make format-check
make lint
make check-tests
make coverage
make build-android
make build-ios
```

Then inspect generated platform configuration, dependency/lockfile diff, artifacts, UI at compact/standard/large text sizes, and create/verify/clone the Git bundle.

### Known risks

- Flutter SDK is absent in the sandbox, which can block Dart formatting, analyzer, widget tests, coverage, platform generation, packaging, and fresh visual runtime inspection.
- UI changes are intentionally limited to a well-contained track row to minimize unverified layout risk.

### Exit conditions

The change is only called fully production-ready if every applicable Flutter gate passes. If the environment prevents a required gate, the source hardening and bundle can still be delivered, but the affected gate remains `BLOCKED`.
