# Background Playback and Offline Downloads

```mermaid
flowchart LR
    T[Playable MP3 track] --> P[Approved media URL policy]
    P -->|reject| X[No network or file write]
    P -->|approved HTTPS candidates| D[DownloadManager]
    D --> C[DownloadClient / HttpClient]
    C -->|redirect disabled| H[Approved Dhamma Download host]
    H --> B[Byte stream]
    B --> TMP[(trackId.mp3.part)]
    TMP -->|2xx + non-empty + complete length| F[(trackId.mp3)]
    TMP -->|failure| DEL[Delete partial]
    F --> L[Library Downloads]
    F --> A[AppController local-first source]
    A --> J[just_audio AudioSource + MediaItem]
    J --> S[Android/iOS background media session]
```

Trust and lifecycle rules:

- Only media accepted by `mediaUrlCandidates` can reach the downloader.
- HTTP catalogue URLs are normalized to HTTPS before download.
- Redirect following is disabled at the `HttpClientRequest` boundary.
- A completed file is never exposed until the temporary stream is closed and validated.
- App-private storage avoids shared-storage permissions and keeps offline media scoped to Dhamma Echo.
- If a local file cannot be loaded, playback falls back only to the existing approved remote candidates.
