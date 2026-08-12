# Now Playing, Background Playback, and Offline Downloads Design

## Goal

Make Dhamma Echo behave like a focused audio application: starting a talk immediately creates visible now-playing state, playback survives normal app backgrounding with system media controls, the current player remains reachable while navigating detail screens, playback updates do not make catalogue screens flicker, and playable talks can be downloaded for offline listening.

## Confirmed defects

### Now-playing state appears too late

`PlaybackController.play()` currently awaits `PlaybackPort.play()` before assigning `_current`. The production port delegates to `just_audio`'s `AudioPlayer.play()`, whose returned future completes when playback completes or is paused/stopped. The stream can therefore be audibly playing while Dhamma Echo still reports `current == null`, so the existing mini player stays hidden.

Expected: selecting a valid talk establishes the current track and visible playback state as soon as the source is prepared and playback is started.

Actual: the UI can remain in the pre-play state until the `play()` future finishes.

### Playback position updates rebuild whole catalogue detail screens

`AppController` listens to every `PlaybackController` notification and forwards each one with `notifyListeners()`. Position changes are high-frequency. Teacher and collection detail screens listen to the whole `AppController`, so playback continuously rebuilds unrelated catalogue UI. `CollectionDetailScreen` additionally creates a new `getCollection()` future from its build method, which can re-enter the loading state during those rebuilds.

Expected: player progress should rebuild only playback-owned surfaces.

Actual: unrelated catalogue screens rebuild while audio plays, producing visible flicker and redundant work.

## Product behavior

### Persistent now playing

- Keep one application-wide `PlaybackController` as the single playback source of truth.
- The mini player appears immediately after a valid talk is selected.
- The mini player remains visible above the main navigation bar and at the bottom of pushed teacher, collection, and settings routes.
- It shows the current talk, teacher, play/pause, next-queue action, and a thin progress indicator when duration is known.
- Tapping the mini player opens the full Now Playing screen.
- The full Now Playing screen keeps seek, ±15 seconds, queue, rate, volume, and favorite actions and adds download/offline state.
- Player-only updates listen directly to `PlaybackController` instead of forcing application-wide rebuilds.

### Background playback

Use `just_audio_background` around the existing single `just_audio` player. It is the smallest companion implementation for this app's current one-player architecture.

- Initialize the background service before `runApp`.
- Load every local or remote source as `AudioSource.uri` with a `MediaItem` tag containing a stable ID, title, artist/teacher, and album label.
- iOS enables the `audio` background mode.
- Android gets the foreground media playback service, media-button receiver, wake-lock permission, foreground-service permission, and media-playback foreground-service permission.
- The generated platform folders remain source-of-truth-compatible: `tool/configure_platforms.py` applies the required configuration after `flutter create`.
- System media controls drive the same `AudioPlayer`; emitted state flows back into `PlaybackController`.

This slice does not redesign the app-level queue into a system-managed playlist. In-app next/queue behavior remains as-is; system background controls cover the current media session's supported play/pause/seek behavior.

## Playback architecture change

### Playback port

`PlaybackPort.load` receives both `AudioTrack` metadata and the URI. `JustAudioPlaybackPort` converts them into a tagged `AudioSource.uri`.

### Start semantics

Loading/preparation remains awaited. Starting playback does not block `PlaybackController.play()` until the audio session eventually pauses or completes.

The controller will:

1. validate allowed remote candidates;
2. prepend a valid downloaded local URI when one exists;
3. load the first successful source;
4. restore rate, volume, and resume position;
5. establish current-track/UI state;
6. start the port asynchronously and observe subsequent state through port events;
7. retain approved-host fallback for remote sources.

A playback generation token prevents an old asynchronous `play()` failure from overwriting the state of a newer track.

Resume/toggle follows the same rule: UI state is updated when resume begins rather than waiting until a later pause.

## Flicker fix

- `AppController._onPlaybackChanged()` retains persistence/history/completion orchestration but stops broadcasting every raw playback tick to all app listeners.
- `MiniPlayer`, `TrackTile`, and playback portions of `PlayerScreen` listen directly to `PlaybackController`.
- `CollectionDetailScreen` becomes stateful and caches its detail future in `initState`, matching the teacher detail pattern.
- Teacher and collection detail screens no longer depend on global playback ticks for their body rebuilds.
- App-owned state changes such as favorite/settings/search still notify `AppController` normally.

## Offline downloads

### Storage

- Store downloaded media in an app-private `downloads` directory under the platform application-support directory.
- Use deterministic file names: `<trackId>.mp3`.
- Write into `<trackId>.mp3.part` first, then rename only after a successful complete response.
- Delete stale `.part` files during download-manager initialization.
- No shared/public storage permission is requested.

### Trust boundary

Downloads reuse `mediaUrlCandidates`; only playable MP3 sources on the existing approved Dhamma Download hosts can be downloaded. Redirect following is disabled so an approved origin cannot silently redirect the downloader to an unapproved host. Alternate approved-host retry remains allowed.

### State model

Create a focused `DownloadManager extends ChangeNotifier` with:

- downloaded track IDs;
- per-track progress;
- per-track error state;
- download and delete operations;
- local URI lookup;
- an injected HTTP client abstraction for deterministic tests.

`AppController` coordinates catalogue resolution for the Library Downloads list and chooses the local URI as the preferred source for playback. If that local source is unusable, normal approved remote candidates remain the fallback.

### UI

- Playable track rows expose a download button.
- Active downloads show progress.
- Downloaded tracks show an offline/downloaded state and allow removal.
- The full player exposes the same download/remove action.
- Library gains a Downloads section listing local talks.
- Download failures remain visible to the user and do not create a fake downloaded state.

## Error handling and reliability

- Unsupported WMA stays searchable and remains neither playable nor downloadable.
- Untrusted URLs are rejected before network or file creation.
- Non-2xx responses and zero-byte responses fail the candidate and clean up temporary files.
- Network errors retry only the approved alternate host.
- Duplicate download taps do not create concurrent writers for the same track.
- Failed local playback falls back to trusted remote media.
- Download and playback resources are disposed with the app controller.

## UI specification

Preserve the existing calm, light Material 3 visual system shown in the supplied screenshots: neutral surface, forest-green accent, rounded cards, simple line icons, and compact information density. Do not redesign the catalogue screens.

- Mini player: white/surface container, minimum 48 dp controls, one-line title and teacher, progress rail at the bottom.
- Download controls: standard Material download/download-done/delete semantics; disabled for unplayable formats.
- Full player: keep current hierarchy; add offline action near favorite in the app bar rather than adding a new heavy panel.
- Detail routes: mini player sits in `Scaffold.bottomNavigationBar`, with safe-area handling matching the main shell.
- Text continues to wrap/truncate using current rules; no new font assets.

## Accessibility

- Every playback/download icon has a contextual tooltip.
- Controls remain at least 48 dp through Material buttons/IconButtons.
- Progress is not the only signal for downloaded state; icon/tooltip state also changes.
- Error messages are textual, not color-only.

## Dependencies

- `just_audio_background ^0.0.1-beta.17`: official companion add-on for simple background playback/media notification on top of the existing `just_audio` player.
- `path_provider ^2.1.6`: app-private application-support directory. This version is already present transitively in the current lockfile; it becomes a direct production dependency because app code will import it.

No general-purpose state-management package or download framework is added.

## Testing strategy

Regression tests cover:

- play state becomes current before a long-running port `play()` future completes;
- resume toggle does not block UI state on a long-running `play()` future;
- local URI is attempted before approved remote candidates;
- stale playback errors cannot overwrite a newer track;
- pure position events do not trigger `AppController`-wide notifications;
- collection detail does not refetch/re-enter loading on playback events;
- mini player remains present on detail routes;
- download success, progress, alternate-host retry, cleanup, rejection, duplicate suppression, initialization scan, and deletion;
- AppController resolves downloaded tracks and prefers their local URI;
- Library and full-player download states render correctly;
- generated Android/iOS configuration contains required background-audio declarations.

## Scope exclusions

- No account/cloud download sync.
- No public-filesystem export.
- No custom DRM/caching proxy.
- No WMA transcoding.
- No full Spotify-style recommendation or playlist service.
- No unrelated visual redesign.
