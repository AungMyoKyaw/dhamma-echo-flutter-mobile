# Security Policy

## Supported branch

Security fixes target the current `main` branch.

## Report a vulnerability

Report vulnerabilities privately through GitHub's private vulnerability reporting for the repository when available. Do not publish secrets, exploit details, or personal data in a public issue.

## Security boundaries

- The SQLite catalogue is read-only.
- SQL values are parameterized.
- Streaming and offline-download audio is restricted to `dhammadownload.com` and `www.dhammadownload.com` over HTTPS after normalization.
- Offline downloads do not follow redirects, are streamed to app-private temporary files, and are atomically promoted only after a complete successful response.
- URL credentials and custom ports are rejected.
- Personal listening state stays on-device.
- No API keys are required by the application.
