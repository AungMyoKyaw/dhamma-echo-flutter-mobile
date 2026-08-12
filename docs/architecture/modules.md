# Module Architecture

```mermaid
flowchart TB
    UI[Material 3 screens + components] --> AC[AppController]
    UI --> PC[PlaybackController]
    UI --> DM[DownloadManager]
    AC --> CR[CatalogueRepository]
    AC --> LS[LocalStateRepository]
    AC --> DM
    PC --> PP[PlaybackPort]
    CR --> SQ[SqfliteCatalogueRepository]
    SQ --> DB[(Read-only SQLite)]
    PP --> JA[just_audio]
    JA --> BG[just_audio_background / system media session]
    JA --> NET[Approved HTTPS hosts]
    DM --> HTTP[dart:io HttpClient]
    HTTP --> NET
    DM --> OFF[(App-private MP3 files)]
    PC --> OFF
```

- `domain/`: immutable product models.
- `core/`: text normalization, catalogue policy, and media URL trust policy.
- `data/`: SQLite catalogue reads and bounded local state persistence.
- `downloads/`: allowlisted atomic offline-download state and `dart:io` adapter.
- `player/`: playback policy/state plus the `just_audio`/background-media adapter.
- `app/`: application orchestration and top-level Material 3 shell.
- `ui/`: mobile screens and reusable presentational components.
