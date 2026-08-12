# Async Request Concurrency

Dhamma Echo uses small generation counters instead of a cancellation framework. A request may still finish at the repository or playback-port boundary, but only the newest request is allowed to commit controller state.

## Search requests

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Search UI
    participant A as AppController
    participant R as CatalogueRepository

    U->>UI: Search "older"
    UI->>A: setAudioQuery("older")
    A->>A: audio generation = 1
    A->>R: searchAudio(older)

    U->>UI: Search "newer"
    UI->>A: setAudioQuery("newer")
    A->>A: audio generation = 2
    A->>R: searchAudio(newer)
    R-->>A: newer result
    A->>A: generation 2 is current
    A-->>UI: commit newer result

    R-->>A: older result or error
    A->>A: generation 1 is stale
    A-->>UI: ignore stale completion
```

Audio, collection, and teacher searches maintain independent generations so unrelated search surfaces do not invalidate one another. Clearing teacher search also advances its generation, preventing an older network/database completion from restoring stale results.

## Playback requests

```mermaid
sequenceDiagram
    participant U as User
    participant P as PlaybackController
    participant O as PlaybackPort

    U->>P: play(track A)
    P->>P: play generation = 1
    P->>O: load(A)

    U->>P: play(track B)
    P->>P: play generation = 2
    P->>O: load(B)
    O-->>P: B load completes
    P->>P: generation 2 is current
    P->>O: volume / speed / seek
    P->>P: commit B as current
    P->>O: play()

    O-->>P: A load completes later
    P->>P: generation 1 is stale
    P-->>U: return false without replacing B state
```

Generation checks run after asynchronous preparation boundaries. This complements `just_audio`'s own source-load cancellation behavior while keeping product state deterministic at the controller boundary.
