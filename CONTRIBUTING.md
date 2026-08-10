# Contributing

## Setup

1. Install Flutter 3.44.7 and Python 3.13+.
2. Install `requirements-tooling.txt`.
3. Run `make bootstrap` and `make deps`.
4. Use the development fixture for isolated UI work or run `make catalogue` when validating the production catalogue.

## Change discipline

- Keep changes scoped to the requested behavior.
- Prefer Flutter/platform APIs over new dependencies.
- Add behavior tests before production changes when the runtime is available.
- Do not add `skip`, focused-only tests, global lint suppressions, telemetry, account services, or unsupported media hosts.
- Do not commit credentials or store signing material.

## Verification

Run:

```bash
make verify
```

For release work also run:

```bash
make catalogue
make verify-catalogue
make build-android
```

Run the iOS build on macOS with Xcode.
