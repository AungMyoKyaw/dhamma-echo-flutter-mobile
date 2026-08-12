# Catalogue and Library Data Flow

```mermaid
flowchart LR
    A[Bundled production dhamma.db] --> I[CatalogueAssetInstaller]
    I -->|copy only when missing or identity changed| DB[(App database directory)]
    Q[User query/filter] --> AC[AppController]
    AC --> R[SqfliteCatalogueRepository]
    R -->|parameterized read-only SELECT| DB
    DB --> R --> M[Typed domain models]
    M --> AC --> UI[Flutter UI]

    UI --> F[Favorite/history/resume action]
    F --> AC --> S[LocalStateRepository]
    S --> J[(state.json)]

    UI --> P[PlaybackController]
    AC --> O[(App-private offline MP3)]
    O --> P
    P --> U[Approved media URL from SQLite]
    U --> N[dhammadownload.com HTTPS]

    UI --> D[DownloadManager]
    D --> U
    D --> O
```

The catalogue is immutable application data and is opened read-only. Search, teachers, collections, categories, formats, languages, titles, and media URLs all come from SQLite. Runtime network access is confined to approved audio streaming/downloads. Personal state and offline media remain separate from the catalogue; state JSON and completed MP3 downloads both use temporary-file-first local persistence.
