#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD=(fvm flutter)
else
  FLUTTER_BIN="$(command -v flutter)"
  if [[ -z "$FLUTTER_BIN" ]]; then
    echo "flutter command bulunamadi."
    exit 1
  fi
  FLUTTER_CMD=(flutter)
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "dart command bulunamadi."
  exit 1
fi

CONFIG_ONLY=0
if [[ "${1:-}" == "--config-only" ]]; then
  CONFIG_ONLY=1
fi

echo "== Release-2 validation started =="

if [[ "$CONFIG_ONLY" -eq 1 ]]; then
  ./scripts/verify_release_prereqs.sh --config-only
else
  ./scripts/verify_release_prereqs.sh
fi

"${FLUTTER_CMD[@]}" pub get
"${FLUTTER_CMD[@]}" gen-l10n
dart format --output=none --set-exit-if-changed lib/core lib/features lib/providers test
dart analyze
"${FLUTTER_CMD[@]}" test --reporter expanded

if [[ "$CONFIG_ONLY" -eq 0 ]]; then
  "${FLUTTER_CMD[@]}" build appbundle --release
else
  echo "Config-only mode: release build adimi atlandi."
fi

echo "== Release-2 validation completed =="
