# CI Coverage Publishing and Safe Local Persistence

## Goal

Publish the repository's existing enforced Flutter coverage through a useful README badge, and eliminate the unhandled iOS exception caused by overlapping local-state saves.

## Existing behavior

The repository already has a GitHub Actions workflow with Ubuntu and macOS jobs. It verifies the catalogue and repository contract, checks generated platform configuration, formatting, analysis, and disabled tests, enforces every LCOV metric emitted by Flutter at 100%, and builds Android and unsigned iOS releases.

`AppController` deliberately starts some persistence work without awaiting it so playback notifications do not block the UI. `LocalStateRepository.save` writes every snapshot through the same `state.json.tmp` path before renaming it to `state.json`. When saves overlap, one invocation can rename the shared temporary file before another invocation reaches its rename. The second invocation then throws `PathNotFoundException`. Giving each invocation a distinct temporary path would prevent that exception but could allow an older write to replace newer state out of order.

## CI and coverage design

The existing job structure and quality gates remain authoritative. Immediately after `make coverage` succeeds in the Ubuntu job, CI uploads `coverage/lcov.info` to Codecov using a pinned Codecov GitHub Action. Upload failure fails the step so a silently broken badge cannot persist unnoticed.

The README places two badges below its title:

- GitHub Actions status for `.github/workflows/ci.yml` on `master`.
- Codecov line coverage for `AungMyoKyaw/dhamma-echo-flutter-mobile` on `master`.

The repository will be public, so the design does not add or document a Codecov token. Until the GitHub repository exists and its first workflow completes, the external badges may report an unknown state.

Codecov publishes the result but does not replace the local coverage policy. `make coverage` continues to fail below 100% for each metric Flutter's LCOV report actually emits.

## Persistence design

`LocalStateRepository` serializes save operations in invocation order. Each public `save` request captures its sanitized snapshot, waits for the repository's preceding save operation, and then performs the existing directory creation, flushed temporary write, and final replacement. A failed operation is returned to its own caller but is converted into a completed predecessor for queue progression, so one filesystem failure cannot prevent all later saves from running.

Serialization belongs in the repository because the fixed temporary file and atomic replacement protocol are repository implementation details. `AppController` may continue using both awaited and unawaited persistence calls without coordinating filesystem access itself.

The implementation does not debounce or discard snapshots. Once all returned save futures complete successfully, the persisted file represents the most recently invoked save.

## Error handling

Filesystem failures still propagate through the `Future` returned by `save`; the repository does not misreport a failed write as successful. The internal save queue recovers after such a failure and permits subsequent requests to execute. Existing tolerant load behavior for missing, corrupt, or unreadable state remains unchanged.

The reported unawaited call sites can still surface unrelated filesystem failures as unhandled asynchronous errors. This change specifically removes failures caused by the repository's own overlapping access while preserving error visibility for genuine storage failures.

## Testing and verification

A repository regression test launches multiple saves without awaiting between invocations, awaits all returned futures, and verifies that no `PathNotFoundException` occurs and that the last requested snapshot is loaded. The test must fail against the current shared-temp implementation before production code changes.

A second test forces one queued save to fail if a deterministic, platform-independent filesystem setup can express that condition, then verifies a later save still runs. If Flutter's filesystem APIs cannot make this deterministic without implementation-specific hooks, queue recovery is covered through the serialized helper's control flow and the overlapping-save regression remains the required behavioral test.

Verification runs the focused local-state repository tests first, followed by formatting, analysis, disabled-test checks, and the complete coverage suite. The workflow YAML and README badge URLs receive direct inspection because their external status cannot become live until the GitHub repository is created.

## Scope boundaries

- Do not restructure the existing CI jobs or change their branch from `master`.
- Do not lower or delegate the repository's 100% coverage threshold to Codecov.
- Do not add secrets, deployment workflows, generated badge commits, or GitHub Pages.
- Do not change application state semantics, persistence format, or load sanitization.
- Do not perform unrelated controller or filesystem refactoring.
