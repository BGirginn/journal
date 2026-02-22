# CI_RUNBOOK.md

## Zorunlu Check'ler (PR)
- `Format Check`
- `Analyze`
- `Test`

Bu 3 check fail ederse PR merge edilmez.

## Hata Siniflandirma
- `Format Check`:
  - Tipik neden: formatlanmamis Dart dosyalari
  - Komut: `dart format --output=none --set-exit-if-changed lib/core lib/features lib/providers test`
- `Analyze`:
  - Tipik neden: lint, null-safety, import hatalari
  - Komut: `dart analyze`
- `Test`:
  - Tipik neden: unit/widget test regressions
  - Komut: `fvm flutter test --reporter expanded`

## Lokal Repro Akisi
```bash
fvm flutter pub get
fvm flutter gen-l10n
dart format --output=none --set-exit-if-changed lib/core lib/features lib/providers test
dart analyze
fvm flutter test --reporter expanded
```

## Release Candidate Akisi
`Release Candidate` workflow'u:
1. Signing secret kontrolu
2. `./scripts/verify_release_prereqs.sh`
3. `fvm flutter build appbundle --release`
4. AAB + metadata artifact upload

## Branch Protection Onerisi
- `main` ve `develop` icin required status checks:
  - `Format Check`
  - `Analyze`
  - `Test`
- Required approvals: en az 1 reviewer.
