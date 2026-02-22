# CONTRIBUTING.md

## Branching
- main: release-ready
- develop: integration
- feature/*: feature branches

## PR Kuralları
- Küçük PR’lar
- Her PR:
  - test ekle veya gerekçeyi yaz
  - perf etkisi varsa ölçüm koy
  - migration varsa MIGRATIONS.md güncelle
- PR merge öncesi zorunlu CI check:
  - `Format Check`
  - `Analyze`
  - `Test`
- CI hata çözümü için: `md_files/docs/CI_RUNBOOK.md`

## Kod Stili
- Dart: `dart format`
- Lint: `dart analyze` temiz olmali

## Lokal Komut Standardi
- `fvm flutter pub get`
- `fvm flutter gen-l10n`
- `dart format --output=none --set-exit-if-changed lib/core lib/features lib/providers test`
- `dart analyze`
- `fvm flutter test --reporter expanded`

## Commit Mesajı
- feat: ...
- fix: ...
- refactor: ...
- perf: ...
- docs: ...
