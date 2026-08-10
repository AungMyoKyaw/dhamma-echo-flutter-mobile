# System Context

```mermaid
flowchart LR
    U[Android / iOS user] --> A[Flutter Dhamma Echo]
    A --> C[(Bundled read-only SQLite catalogue)]
    A --> L[(On-device JSON library state)]
    A --> H[HTTPS Dhamma Download audio hosts]
    B[Desktop release package] -->|verified catalogue extraction at build time| C
```

Trust boundaries:

- Catalogue text is untrusted data and is never executed.
- Playback URLs are accepted only through the explicit Dhamma Download host allowlist.
- Personal library state never leaves the device.
