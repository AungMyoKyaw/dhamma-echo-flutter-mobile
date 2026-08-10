#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter executable not found" >&2
  exit 1
fi

flutter create --platforms=android,ios --org com.aungmyokyaw .
python3 tool/configure_platforms.py
