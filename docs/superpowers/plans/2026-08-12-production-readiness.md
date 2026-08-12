# Dhamma Echo Production Readiness Implementation Plan

> **For agentic workers:** Execute test-first in small slices. Do not broaden scope beyond the audited production-readiness issues.

**Goal:** Harden asynchronous state, playback ordering, track-row UX, test reliability, and accessibility without new production dependencies.

**Architecture:** Preserve the existing Flutter + ChangeNotifier architecture. Add last-request-wins generation guards inside existing controllers, keep just_audio behind the existing PlaybackPort, and compact track actions in the existing TrackTile.

**Tech Stack:** Flutter 3.44.9, Dart 3.12.x, Material 3, flutter_test, just_audio 0.10.6, just_audio_background 0.0.1-beta.17.

## Global Constraints

- No production dependency additions.
- Keep existing Flutter/Dart version constraints and `pubspec.lock` strategy.
- Preserve the approved-host media URL policy and local-first playback behavior.
- Preserve the existing forest/parchment color system.
- Keep Android/iOS as the release targets.
- Keep all required tests enabled.

---

### Task 1: Last-request-wins app searches

**Files:**
- Modify: `test/app/app_controller_test.dart`
- Modify: `lib/app/app_controller.dart`

**Interfaces:**
- Existing public search/filter methods stay unchanged.
- Concurrent audio, collection, and teacher searches commit only if they are still the newest request for that search family.

- [ ] Add regression tests using deferred catalogue responses that resolve newer requests before older requests.
- [ ] Verify the new tests fail against the baseline when Flutter is available; otherwise record the environment blocker before production edits.
- [ ] Add minimal generation counters and stale-result guards.
- [ ] Re-run focused tests when Flutter is available; otherwise run repository-only inner-loop checks.

### Task 2: Latest playback request wins

**Files:**
- Modify: `test/player/playback_controller_test.dart`
- Modify: `lib/player/playback_controller.dart`

**Interfaces:**
- `PlaybackController.play()` keeps its existing signature.
- A stale overlapping play returns `false` and cannot replace current state from a newer play.

- [ ] Add a controlled-port regression where track 2 finishes loading before track 1.
- [ ] Verify baseline failure when Flutter is available; otherwise document the blocker.
- [ ] Add generation checks after asynchronous load/setup boundaries and before state commit.
- [ ] Re-run focused playback tests when possible.

### Task 3: Track-row interaction density and current-track behavior

**Files:**
- Modify: `test/ui/detail_settings_regression_test.dart`
- Modify: `lib/ui/components/track_tile.dart`

**Interfaces:**
- Leading action plays a new track or toggles the current track.
- Trailing overflow menu exposes download/remove, favorite/unfavorite, and queue actions.

- [ ] Add a regression proving the current-track leading control pauses without a second load.
- [ ] Add a narrow-layout regression/accessibility assertions for labeled and minimum-size tap targets.
- [ ] Replace three trailing icon actions with a single labeled overflow menu.
- [ ] Keep download errors surfaced through the existing SnackBar.
- [ ] Preserve all existing commands and state behavior.

### Task 4: Bounded download widget test

**Files:**
- Modify: `test/ui/detail_settings_regression_test.dart`

**Interfaces:**
- Test-only helper pumps frames until an explicit predicate is true or a bounded timeout expires.

- [ ] Replace `pumpAndSettle()` only in the download/remove regression.
- [ ] Keep the product progress indicator unchanged.
- [ ] Assert both download completion and removal states explicitly.

### Task 5: Documentation and release evidence

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `README.md` only where production-readiness behavior/verification changes need documentation.
- Create: `docs/reports/2026-08-12-production-readiness.md`

- [ ] Record Context7/Design.md decisions and dependency rationale.
- [ ] Record measured dependency count and repository/bundle size before/after.
- [ ] Run every locally available repository gate.
- [ ] Attempt Flutter release gates and report genuine blockers precisely.
- [ ] Validate Mermaid docs/references via repository inspection.
- [ ] Create a complete Git bundle, verify it, clone it, and re-run repository-only checks from the clone.
