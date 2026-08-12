# System Context

```mermaid
flowchart LR
    U[Android / iOS user] --> A[Flutter Dhamma Echo]
    A --> C[(Bundled read-only SQLite catalogue)]
    A --> L[(On-device JSON library state)]
    A --> O[(App-private offline MP3 files)]
    A --> H[HTTPS Dhamma Download audio hosts]
    A --> S[Android / iOS media session]
    B[Desktop release package] -->|verified catalogue extraction at build time| C
```

Trust boundaries:

- Catalogue text is untrusted data and is never executed.
- Stream/download URLs are accepted only through the explicit Dhamma Download host allowlist.
- Downloads do not follow redirects and become visible only after complete atomic local promotion.
- Personal library state and offline media never leave the device.
- Background media controls operate on the same single in-app audio player; no account or remote-control service is introduced.
