# Playback Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant A as AppController
    participant O as Offline Download Store
    participant P as PlaybackController
    participant H as Media URL policy
    participant J as just_audio
    participant S as System media session
    participant D as Dhamma Download

    U->>A: Play track
    A->>O: localUriFor(track.id)
    O-->>A: local URI or none
    A->>P: play(track, resumeAt, preferredUri)
    P->>H: validate + build HTTPS candidates
    H-->>P: www + bare host candidates
    alt downloaded file exists
      P->>J: load local tagged AudioSource
    else no local file / local load fails
      P->>J: load approved remote tagged AudioSource
      J->>D: HTTPS request
      alt first host fails
        P->>J: load alternate approved host
        J->>D: HTTPS retry
      end
    end
    P->>J: seek resume / set rate / set volume
    P-->>A: current track ready
    P->>J: start play asynchronously
    J->>S: publish MediaItem + playback state
    A->>A: record local history
```

`AudioPlayer.play()` is intentionally not awaited as the definition of "playback started" because its future stays alive until playback later pauses, stops, or completes. UI state is established after source preparation and before the long-lived play future is observed asynchronously.
