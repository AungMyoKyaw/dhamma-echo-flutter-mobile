# Changelog

## Unreleased

- Replaced the five-talk development fixture with the verified 27,750,400-byte production SQLite catalogue (30,563 audio talks, 257 teachers, 429 audio collections).
- Fixed teacher loading so the Teachers and Collections surfaces use the complete catalogue rather than a 100-row subset.
- Reworked the light Material 3 theme for neutral surfaces, readable selected navigation states, flat search fields, and clearer metadata hierarchy.
- Clarified Explore filter grouping and Library empty states, and changed CI to verify the checked-in catalogue rather than fetching it.
- Rebuilt Dhamma Echo as a native Flutter Android/iOS application from the current desktop behavior.
- Added mobile Material 3 navigation, search/filter flows, collections, teachers, library, settings, mini-player, and full player.
- Added read-only SQLite catalogue access and bounded on-device state persistence.
- Added approved-host HTTPS MP3 playback policy and deterministic WMA unavailability.
- Added tests, strict analysis configuration, engineering diagrams, CI, catalogue verification, platform bootstrap, and Git-bundle-ready project structure.
