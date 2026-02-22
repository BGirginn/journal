# Journal V2

Offline-first journal uygulamasi (Flutter + Drift + Firebase).

## Toolchain
- Flutter version is pinned with FVM in `.fvmrc`.
- Preferred commands:
  - `fvm flutter pub get`
  - `dart analyze`
  - `fvm flutter test --reporter expanded`
  - `fvm flutter build apk --debug`
  - `fvm flutter build ios --simulator --no-codesign`

## iOS / Xcode Run
- Always open `ios/Runner.xcworkspace` (not `ios/Runner.xcodeproj`).
- After pulling iOS dependency changes, run `cd ios && pod install`.
- Select an installed simulator in Xcode (for this machine: `iPhone 17`, `iPhone 17 Pro`, `iPhone Air`, etc.).

## CI Workflows
- PR kalite kapilari: `.github/workflows/pr_ci.yml`
- Release candidate pipeline: `.github/workflows/release_candidate.yml`

## Release Hazirlik Dokumanlari
- `md_files/docs/RELEASE_CHECKLIST.md`
- `md_files/docs/ANDROID_SIGNING.md`
- `md_files/docs/RELEASE_GO_NO_GO.md`
- `md_files/docs/CI_RUNBOOK.md`
