# Changelog

## Unreleased

- Prevented stale audio, collection, and teacher searches from overwriting newer results or errors.
- Prevented overlapping playback requests from committing stale track state after a newer play request starts.
- Reduced track-row action density to one accessible overflow menu and made the current-track control pause/resume without reloading audio.
- Replaced the download/remove widget regression's unbounded settling step with a bounded state-driven wait and added compact-width accessibility coverage.
- Aligned the Flutter Material 3 palette with the current desktop saffron/olive/cream brand tokens and added regression coverage for the exact theme roles.
- Regenerated the application icon with AI to match the desktop saffron/cream/olive identity and derived Android adaptive/monochrome layers from the new artwork.
- Fixed now-playing state so the mini player appears as soon as playback starts instead of waiting for the long-lived audio `play()` future to finish.
- Added persistent Now Playing access on detail/settings routes and removed playback-position rebuilds that could make teacher/collection screens flicker.
- Added background playback metadata and generated Android/iOS media-service configuration.
- Added trusted app-private offline MP3 downloads, Library Downloads, local-first playback, progress, failure cleanup, and removal.
- Replaced the five-talk development fixture with the verified 27,750,400-byte production SQLite catalogue (30,563 audio talks, 257 teachers, 429 audio collections).
- Fixed teacher loading so the Teachers and Collections surfaces use the complete catalogue rather than a 100-row subset.
- Reworked the light Material 3 theme for neutral surfaces, readable selected navigation states, flat search fields, and clearer metadata hierarchy.
- Clarified Explore filter grouping and Library empty states, and changed CI to verify the checked-in catalogue rather than fetching it.
- Rebuilt Dhamma Echo as a native Flutter Android/iOS application from the current desktop behavior.
- Added mobile Material 3 navigation, search/filter flows, collections, teachers, library, settings, mini-player, and full player.
- Added read-only SQLite catalogue access and bounded on-device state persistence.
- Added approved-host HTTPS MP3 playback policy and deterministic WMA unavailability.
- Added tests, strict analysis configuration, engineering diagrams, CI, catalogue verification, platform bootstrap, and Git-bundle-ready project structure.
