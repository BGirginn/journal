#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG_ONLY=0
if [[ "${1:-}" == "--config-only" ]]; then
  CONFIG_ONLY=1
fi

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

pass() {
  echo "OK: $1"
}

BUILD_FILE="android/app/build.gradle.kts"
RULES_FILE="firestore.rules"

[[ -f "$BUILD_FILE" ]] || fail "$BUILD_FILE bulunamadi"
[[ -f "$RULES_FILE" ]] || fail "$RULES_FILE bulunamadi"

if rg -n "signingConfigs.getByName\\(\"debug\"\\)" "$BUILD_FILE" >/dev/null; then
  fail "Release build debug signing kullaniyor."
fi
pass "Release build debug signing kullanmiyor."

if ! rg -n "match /team_members/\\{memberId\\}" "$RULES_FILE" >/dev/null; then
  fail "Firestore rules icinde team_members match yok."
fi
pass "Firestore rules team_members path standardini kullaniyor."

if rg -n "match /teamMembers/\\{memberId\\}" "$RULES_FILE" >/dev/null; then
  fail "Firestore rules eski teamMembers path'i iceriyor."
fi
pass "Firestore rules eski teamMembers path'ini icermiyor."

if [[ "$CONFIG_ONLY" -eq 1 ]]; then
  echo "Config-only mode: signing secret kontrolu atlandi."
  echo "Release prereq checks tamam."
  exit 0
fi

has_key_props=0
if [[ -f "key.properties" ]]; then
  has_key_props=1
  for key in storeFile storePassword keyAlias keyPassword; do
    if ! rg -n "^${key}=" key.properties >/dev/null; then
      fail "key.properties icinde $key eksik."
    fi
  done
  pass "key.properties release signing alanlarini iceriyor."
fi

has_env=1
for key in RELEASE_STORE_FILE RELEASE_STORE_PASSWORD RELEASE_KEY_ALIAS RELEASE_KEY_PASSWORD; do
  if [[ -z "${!key:-}" ]]; then
    has_env=0
  fi
done

if [[ "$has_key_props" -eq 0 && "$has_env" -eq 0 ]]; then
  fail "Release signing secret'lari yok. key.properties olusturun veya CI env degiskenlerini tanimlayin."
fi

if [[ "$has_env" -eq 1 ]]; then
  pass "CI release signing env degiskenleri tanimli."
fi

echo "Release prereq checks tamam."
