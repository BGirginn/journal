# RELEASE_CHECKLIST.md

## Security Baseline
- [ ] `android/app/build.gradle.kts` release build debug key kullanmiyor
- [ ] Release signing secret'lari hazir:
- [ ] local: `key.properties` (bkz `key.properties.example`)
- [ ] CI: `RELEASE_STORE_FILE`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD`
- [ ] Firebase rules path standardi `team_members` ile uyumlu
- [ ] `./scripts/verify_release_prereqs.sh` basarili
- [ ] Apple Sign-In capability acik (`ios/Runner/Runner.entitlements` -> `com.apple.developer.applesignin`)
- [ ] Firebase Console > Authentication > Apple provider ayarlari (Service ID / Team ID / Key ID / `.p8`) tamam

## Build & QA
- [ ] `dart analyze` basarili
- [ ] `fvm flutter test` basarili
- [ ] Android release bundle alinabiliyor: `fvm flutter build appbundle --release`
- [ ] iOS simulator build alinabiliyor: `fvm flutter build ios --simulator --no-codesign`
- [ ] Crash-free smoke test (Android + iOS)
- [ ] Offline senaryolar: create/edit/save/restart
- [ ] Sync: 2 cihaz testi (A->B, B->A)
- [ ] Asset upload/download (image + ink)
- [ ] Performance: 30 block sayfa lag yok
- [ ] Security: screenshot flag / app lock (varsa)
- [ ] Migration: clean install + upgrade test

## Store Hazırlığı
- [ ] App icon + screenshots
- [ ] Privacy policy metni
- [ ] Versioning (build number)
- [ ] Firebase rules deploy

## Smoke Komut Seti
```bash
./scripts/verify_release_prereqs.sh
dart analyze
fvm flutter test
fvm flutter build appbundle --release
fvm flutter build ios --simulator --no-codesign
```

## Full Regression (Release-2)
```bash
./scripts/run_release2_validation.sh
# veya secret yoksa:
./scripts/run_release2_validation.sh --config-only
```
