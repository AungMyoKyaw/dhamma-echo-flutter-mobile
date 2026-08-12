# Dhamma Echo Flutter Production Readiness Hardening

Date: 2026-08-12
Branch: `production-readiness-2026-08-12`

## Result

This pass hardens the production source and repository, but it does **not** certify the release as fully production-ready in the current sandbox. The Flutter and Dart executables are absent, so the mandatory formatter, analyzer/type checker, Flutter test suite, coverage, Android/iOS builds, package-size measurement, and fresh rendered UI inspection cannot execute here.

Repository-only validation is reproducible and passes. Flutter-only gates are reported as `BLOCKED`, never inferred from source review.

## Scoped research

The repository was inspected before implementation. Current documentation was then queried only for technologies touched by this change:

- Flutter official documentation through Context7 (`/flutter/website`): Material 3, `ChangeNotifier`, accessibility guideline testing, labeled tap targets, and Android/iOS minimum touch-target checks.
- `just_audio` documentation through Context7 (`/websites/pub_dev_just_audio_0_10_5`): `playing` versus `processingState`, async source preparation, state streams, and disposal lifecycle.
- `just_audio_background` documentation through Context7 (`/ryanheise/just_audio`): initialization, `MediaItem` tagging, Android foreground media service requirements, and iOS background audio mode.
- The official Flutter release index was checked against the repository pin. Flutter 3.44.9 / Dart 3.12.2 is the selected stable toolchain for this repository, so no framework upgrade was introduced.
- Design.md was used with the existing forest, neutral, brick-error, and parchment keys. The generated family confirmed the established direction; the already-certified app palette was preserved rather than replaced.

No new production dependency was needed.

## Root-cause findings and fixes

### 1. Stale search results

**Expected:** the newest audio, collection, or teacher search represents the user's current intent.

**Actual baseline:** concurrent repository calls had no request identity. A slower earlier request could overwrite a newer result or error state.

**Root cause:** `AppController` committed every async search completion unconditionally.

**Fix:** independent generation counters now provide last-request-wins semantics for audio, collection, and teacher searches. Stale successes and stale errors are ignored. Clearing teacher search also invalidates an older in-flight request.

**Regression coverage added:** deferred-search tests for out-of-order audio/collection completion, stale errors, teacher stale errors, and teacher-clear invalidation.

### 2. Overlapping playback requests

**Expected:** when the user selects track B after track A, track A must not reclaim controller state if its async load completes later.

**Actual baseline:** `_playGeneration` protected asynchronous `play()` startup and final failure, but `play()` did not re-check the generation after `load`, volume, speed, or seek preparation.

**Root cause:** stale async preparation could continue into state commit after newer user intent existed.

**Fix:** `PlaybackController.play()` checks the generation after asynchronous preparation boundaries and after candidate failures before continuing or committing state.

**Regression coverage added:** a controlled playback port completes track B before track A and asserts that B remains current while A returns `false`.

### 3. Current-track row behavior and action density

**Expected:** the current track's primary control pauses/resumes; secondary actions remain accessible without consuming most of a phone row.

**Actual baseline:** the current row showed an equalizer icon with a `Play` tooltip, and pressing it called `AppController.play(track)` again, reloading the same source. Three trailing icon buttons also left little width for title/metadata on compact phones.

**Root cause:** the row represented playback state instead of the next action and treated current-track activation the same as a new source selection.

**Fix:** the leading control now shows loading/play/pause state with action-correct labels and toggles current playback without reloading. Download, favorite, and queue actions moved into one labeled `PopupMenuButton`.

**Accessibility coverage added:** compact 320 px widget test with Flutter's Android/iOS touch-target and labeled-target guidelines, plus explicit menu-label assertions.

### 4. Download/remove widget test settling

**Expected:** the regression terminates after the download state reaches downloaded or removed.

**Actual baseline evidence:** the earlier color-system certification recorded this widget test hanging in `pumpAndSettle()` while a progress indicator could remain animated.

**Fix:** only the post-download/post-remove settle steps were replaced with a bounded, state-driven pump helper. Normal popup open/close animation can still use `pumpAndSettle()`.

## Architecture

The existing architecture remains unchanged: `AppController` orchestrates app/search state, `PlaybackController` owns playback state, `PlaybackPort` isolates `just_audio`, and `DownloadManager` owns app-private offline media.

New concurrency behavior is documented in [Async Request Concurrency](../architecture/concurrency.md). Existing diagrams remain under `docs/architecture/` and are linked from the README.

## Ralph Loop evidence

### Fast inner loop

Repeated after implementation slices:

```text
python3 tool/check_tests.py                 PASS
python3 tool/repository_check.py            PASS
python3 tool/test_configure_platforms.py    PASS (6 tests)
python3 tool/catalogue.py verify            PASS
git diff --check                            PASS
```

Flutter RED/GREEN execution for the new Dart/widget regressions is `BLOCKED`: `flutter` is not installed in the sandbox. The tests were authored before their corresponding production edits, but their runtime failure/pass cycle cannot be claimed.

### Full release loop

Observed final environment state:

```text
flutter: MISSING
dart:    MISSING
```

Repository/tooling gates:

```text
python3 -m pip install -r requirements-tooling.txt   PASS (pinned packages already satisfied)
make verify-catalogue                               PASS
make repository-check                              PASS
make platform-config-test                          PASS (6 tests)
make check-tests                                    PASS (zero skipped/disabled/focused tests)
python3 -m compileall -q tool                       PASS
CI / Dependabot YAML parse                          PASS
Mermaid structural validation                       PASS
git diff --check                                    PASS
```

Flutter gates:

```text
make bootstrap       BLOCKED: flutter executable not found
make deps            BLOCKED: flutter executable not found
make format-check    BLOCKED: dart executable not found
make lint            BLOCKED: flutter executable not found
make typecheck       BLOCKED: flutter executable not found
make test            BLOCKED: flutter executable not found
make coverage        BLOCKED: flutter executable not found
make build-android   BLOCKED: flutter executable not found
make build-aab       BLOCKED: flutter executable not found
make build-ios       BLOCKED: flutter executable not found
```

Fresh runtime/simulator visual verification is therefore also `BLOCKED`.

## Security and dependency evidence

- `pubspec.yaml` and `pubspec.lock` are unchanged from the baseline commit.
- Direct production dependency entries remain 6: Flutter, `just_audio`, `just_audio_background`, `path`, `path_provider`, and `sqflite`.
- Repository secret-pattern checking passes; a second scan excluding the scanner's own regex definition found no candidate API keys/private-key headers.
- No debug printing was introduced in production Dart code.
- The existing host allowlist, HTTPS normalization, redirect prohibition, app-private download storage, and read-only catalogue boundaries were preserved.
- Dependabot remains configured for both Pub and GitHub Actions.
- A shared-environment `pip check` reports an unrelated globally installed `moviepy` constraint against Pillow 12.3.0. `moviepy` is not a project dependency; the project's exact tooling packages import at the required versions. This shared-environment result is not treated as a repository dependency failure.
- A clean Dart/Flutter dependency advisory audit cannot run without the Flutter/Dart toolchain, so the complete security/dependency-audit gate remains `BLOCKED`.

## Lightweight measurements

Measured from the original supplied bundle checkout versus the implementation snapshot before adding this report:

| Metric | Baseline | Hardened source | Delta |
| --- | ---: | ---: | ---: |
| Direct production dependency entries | 6 | 6 | 0 |
| Production Dart source (`lib/**/*.dart`) | 142,597 B | 146,012 B | +3,415 B |
| Dart tests (`test/**/*.dart`) | 59,464 B | 71,091 B | +11,627 B |
| Application assets | 30,843,471 B | 30,843,471 B | 0 B |
| Tracked repository bytes | 31,916,549 B | 31,946,505 B | +29,956 B |

No visual asset or production package dependency was added. APK/AAB/IPA-size comparison is `BLOCKED` because builds cannot run.

## Quality-gate status

| Gate | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Repository contract | `PASS` | `make repository-check` | Required OSS/docs/tooling files and secret-pattern contract pass. |
| Catalogue integrity | `PASS` | `make verify-catalogue` | Bundled production SQLite identity verified. |
| Platform-config tooling tests | `PASS` | `make platform-config-test` | 6/6 Python tests pass. |
| Disabled/focused test check | `PASS` | `make check-tests` | Zero skipped/disabled/focused required tests detected. |
| Formatter | `BLOCKED` | `make format-check` | `dart` executable is absent. |
| Linter | `BLOCKED` | `make lint` | `flutter` executable is absent. |
| Type checker | `BLOCKED` | `make typecheck` | `flutter` executable is absent. |
| Flutter tests | `BLOCKED` | `make test` | `flutter` executable is absent. |
| Coverage | `BLOCKED` | `make coverage` | No LCOV report can be generated without Flutter. No percentage is claimed. |
| Android build | `BLOCKED` | `make build-android` / `make build-aab` | Catalogue gate passes first; Flutter executable is absent. |
| iOS build | `BLOCKED` | `make build-ios` | Catalogue gate passes first; Flutter executable is absent. |
| Security/dependency audit | `BLOCKED` | source/secret checks pass; Flutter audit unavailable | Complete dependency advisory verification requires the missing toolchain/networked resolver. |
| UI visual verification | `BLOCKED` | no runnable Flutter target | Existing screenshots are baseline evidence, not proof of the changed row. |
| Lightweight measurements | `PASS` | byte/dependency comparison above | No production dependency or asset increase; binary size remains build-blocked. |
| Dependency/lockfile verification | `PASS` | `git diff 94067f9..HEAD -- pubspec.yaml pubspec.lock` | No changes. |
| CI/document validation | `PASS` | YAML parse, repository check, Mermaid structural check | CI execution itself requires GitHub/Flutter. |
| Git bundle verification | `BLOCKED` | performed after this report commit | Final bundle evidence is intentionally recorded in the external handoff log so editing this file cannot invalidate the verified bundle. |

## Remaining release work

On a machine with Flutter 3.44.9 / Dart 3.12.2, run the full release loop from a clean clone:

```bash
make bootstrap
make deps
make format-check
make lint
make typecheck
make check-tests
make coverage
make build-android
make build-aab
make build-ios
```

Then run the changed UI on Android/iOS at compact, standard, and large accessibility text sizes and inspect the track row, popup actions, loading state, paused/resumed current track, download/remove flow, focus/semantics, overflow, and text truncation. Only after those blocked gates pass should this revision be called fully production-ready.
