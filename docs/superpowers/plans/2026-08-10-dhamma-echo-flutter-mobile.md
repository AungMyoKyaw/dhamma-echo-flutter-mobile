# Dhamma Echo Flutter Mobile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Android/iOS Dhamma Echo in Flutter with feature parity to the current desktop audio application.

**Architecture:** Framework-native Flutter UI and `ChangeNotifier` state wrap a read-only SQLite catalogue repository, a small local state store, and a narrow `just_audio` playback adapter. All user-controlled catalogue queries remain parameterized and playback URLs pass a strict host/format policy before reaching the player.

**Tech Stack:** Flutter 3.44.x / Dart 3.12+, Material 3, sqflite 2.4.3, just_audio 0.10.6, path 1.9.1, flutter_test, integration_test, sqflite_common_ffi 2.4.2.

## Global Constraints

- Flutter only for application UI/runtime.
- Android and iOS only for release targets.
- Light theme only.
- No account, cloud sync, analytics, telemetry, downloads, or background-audio service.
- Preserve desktop catalogue semantics and URL trust policy.
- 50-talk and 24-collection explicit load-more batches.
- Curated teacher order: `16, 42, 40, 53, 61, 8`.
- Zero analyzer errors and warnings in CI.
- Zero skipped/disabled/focused required tests.
- 100% project-owned executable-code coverage gate.

---

### Task 1: Domain contracts and core policies

**Files:** `lib/domain/models.dart`, `lib/core/*.dart`, `test/core/*_test.dart`, `test/domain/*_test.dart`

- [ ] Write tests for normalization, validation, natural collection sorting, curated teachers, and trusted media URL candidates.
- [ ] Run focused tests and confirm RED.
- [ ] Implement the minimum domain/core code.
- [ ] Run focused tests and confirm GREEN.
- [ ] Commit.

### Task 2: Catalogue repository

**Files:** `lib/data/catalogue_repository.dart`, `lib/data/sqflite_catalogue_repository.dart`, `test/data/catalogue_repository_test.dart`

- [ ] Write fixture-database behavior tests matching desktop SQL semantics.
- [ ] Run and confirm RED.
- [ ] Implement summary/category/teacher/collection/audio queries with placeholders and input validation.
- [ ] Run and confirm GREEN.
- [ ] Commit.

### Task 3: Local state and catalogue installation

**Files:** `lib/data/local_state_repository.dart`, `lib/data/catalogue_asset_installer.dart`, `tool/fetch_catalogue.py`, tests.

- [ ] Write tests for corrupt/default state, dedupe, history <=100, resume <=500, rate/volume bounds, and release fixture rejection.
- [ ] Run and confirm RED.
- [ ] Implement atomic local JSON persistence and read-only asset copy.
- [ ] Run and confirm GREEN.
- [ ] Commit.

### Task 4: Playback and application controller

**Files:** `lib/player/*`, `lib/app/app_controller.dart`, tests.

- [ ] Write tests for queue uniqueness/order, resume, next/previous, playback state, alternate URL retries, filters, load-more append/retry, and favorites/history.
- [ ] Run and confirm RED.
- [ ] Implement interfaces, just_audio adapter, and controller state transitions.
- [ ] Run and confirm GREEN.
- [ ] Commit.

### Task 5: Material 3 mobile shell and screens

**Files:** `lib/ui/**`, `lib/app/dhamma_echo_app.dart`, widget tests.

- [ ] Write widget tests for root navigation, settings access, async states, search/filter controls, details, library, mini-player, queue, and player controls.
- [ ] Run and confirm RED.
- [ ] Implement the light-only mobile UI from the Design.md palette.
- [ ] Run and confirm GREEN.
- [ ] Commit.

### Task 6: Platform/bootstrap, documentation, CI and release

**Files:** `tool/bootstrap_platforms.sh`, `.github/workflows/ci.yml`, `README.md`, OSS docs, architecture diagrams.

- [ ] Add deterministic Flutter platform bootstrap and Android/iOS overrides.
- [ ] Add CI format/analyze/test/coverage/build gates.
- [ ] Add README, security, contribution, conduct, changelog, MIT license, and Mermaid diagrams.
- [ ] Run the full release Ralph Loop.
- [ ] Create and verify a complete Git bundle and clone-test it.
