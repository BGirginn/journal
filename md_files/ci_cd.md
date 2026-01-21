```md
# CI/CD — Flutter + Firebase + Store Release Pipeline (ci_cd.md)

Bu doküman, Flutter (cross-platform) journal uygulaması için **kesin ve uygulanabilir** CI/CD tasarımını tanımlar.  
Pipeline hedefi: her push’ta kalite kapıları (lint/test/build) + main branch’te sürümleme + store dağıtımı.

---

## 0) NET KARARLAR (DEĞİŞMEZ)

### Repo & Branch Model
- `main`: prod release branch
- `develop`: aktif geliştirme
- `feature/*`: özellik branch’leri
- `release/*`: sürüm hazırlığı (opsiyonel)
- `hotfix/*`: acil düzeltme

### CI/CD Aracı
- **GitHub Actions** (KESİN)

### Flutter Kurulumu
- `subosito/flutter-action` kullanılır (KESİN)

### Versiyonlama
- Tek kaynak: `pubspec.yaml` içindeki `version: x.y.z+buildNumber`
- Release tag formatı: `vX.Y.Z`

### Dağıtım
- Android: **Google Play Console** (Internal → Closed → Production)
- iOS: **App Store Connect / TestFlight** (iOS geldiğinde)
- Firebase: Auth/Firestore/Storage için kurallar ve config deploy edilir

---

## 1) PIPELINE YAPISI (ÖZET)

### A) Pull Request CI (her PR)
- Format/Lint
- Unit + Integration test
- Debug build
- Artifact üretimi (APK) opsiyonel

### B) Develop Branch CD (her merge)
- Staging build
- Firebase config & rules deploy (staging)
- Android internal track’e yükleme (opsiyonel)

### C) Main Branch Release CD (tag veya merge)
- Release build (AAB)
- Signing
- Play Console’a upload
- (Opsiyonel) Firebase prod rules deploy
- Release notes + tag

---

## 2) GITHUB ACTIONS WORKFLOWS

Repo dizini:
```

.github/
workflows/
pr_ci.yml
develop_cd.yml
release_cd.yml

````

---

## 3) PR CI — LINT / TEST / BUILD (pr_ci.yml)

```yaml
name: PR CI

on:
  pull_request:
    branches: [ "develop", "main" ]

jobs:
  pr_ci:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Flutter Pub Get
        run: flutter pub get

      - name: Analyze (lint)
        run: flutter analyze

      - name: Format check
        run: dart format --set-exit-if-changed .

      - name: Run unit tests
        run: flutter test

      - name: Build Android debug APK
        run: flutter build apk --debug
````

**Kesin kural:** PR bu kontrolleri geçmeden merge edilmez.

---

## 4) STAGING CD — DEVELOP BRANCH (develop_cd.yml)

### Staging Ortam Kararı

* Firebase projesi: `journal-staging`
* Android uygulama id: aynı kalabilir, ancak farklı google-services.json kullanılır
* Staging config: `--dart-define=ENV=staging`

```yaml
name: Develop CD (Staging)

on:
  push:
    branches: [ "develop" ]

jobs:
  staging_cd:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Pub Get
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Tests
        run: flutter test

      - name: Build AAB (staging)
        run: flutter build appbundle --release --dart-define=ENV=staging

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: appbundle-staging
          path: build/app/outputs/bundle/release/app-release.aab
```

**Not:** Staging dağıtımı otomatik Play upload istersen aşağıdaki “fastlane” bölümünü aç.

---

## 5) RELEASE CD — MAIN BRANCH (release_cd.yml)

### Release Tetikleme Kararı

* Release işlemi **tag** ile tetiklenir (KESİN)
* Tag: `vX.Y.Z`
* Tag atıldığında:

  * AAB üretilir
  * imzalanır
  * Play Console’a gönderilir

```yaml
name: Release CD (Production)

on:
  push:
    tags:
      - "v*.*.*"

jobs:
  release_android:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Pub Get
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Tests
        run: flutter test

      - name: Decode Android keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=upload-keystore.jks
          EOF

      - name: Build AAB (production)
        run: flutter build appbundle --release --dart-define=ENV=production

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: appbundle-production
          path: build/app/outputs/bundle/release/app-release.aab
```

> Play Console’a otomatik yükleme için fastlane şart (aşağıda).

---

## 6) ANDROID STORE UPLOAD — FASTLANE (KESİN YOL)

### Karar

* Store upload işlemi **fastlane supply** ile yapılır.

### Repo içine eklenecekler

```
android/fastlane/
  Appfile
  Fastfile
```

### Gem kurulumu

CI’da:

* `ruby/setup-ruby@v1`
* `bundle install`

### Fastfile (örnek)

```ruby
default_platform(:android)

platform :android do
  desc "Upload AAB to Google Play (internal)"
  lane :internal do
    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Upload AAB to Google Play (production)"
  lane :production do
    upload_to_play_store(
      track: "production",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
```

### Gerekli Secret (KESİN)

* `PLAY_SERVICE_ACCOUNT_JSON_BASE64` (Google Play service account JSON’u base64)
* Upload için fastlane `json_key` kullanır

CI step:

```bash
echo "${{ secrets.PLAY_SERVICE_ACCOUNT_JSON_BASE64 }}" | base64 --decode > play.json
bundle exec fastlane android production json_key:play.json
```

---

## 7) FIREBASE RULES & CONFIG DEPLOY

### Karar

* Firestore rules ve Storage rules **repo içinde** tutulur.
* Deploy staging/prod ayrı yapılır.

Repo:

```
firebase/
  firestore.rules
  storage.rules
  firebase.json
```

### Firebase CLI

CI’da:

* `npm install -g firebase-tools`

Deploy komutu:

```bash
firebase use $FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules,storage:rules
```

Secrets:

* `FIREBASE_SERVICE_ACCOUNT_BASE64`
* `FIREBASE_PROJECT_ID_STAGING`
* `FIREBASE_PROJECT_ID_PROD`

---

## 8) ENV MANAGEMENT (STAGING / PROD)

### Kesin Yol

* `--dart-define=ENV=staging|production`
* Firebase config dosyaları:

  * `android/app/google-services.json` (staging/prod ayrımı)
  * iOS için `GoogleService-Info.plist` (sonra)

### Repo’da config yönetimi kararı

* Config dosyaları **repoya konmaz** (kesin)
* CI’da secret olarak saklanır ve build sırasında yazdırılır

Örn:

* `GOOGLE_SERVICES_JSON_STAGING_BASE64`
* `GOOGLE_SERVICES_JSON_PROD_BASE64`

CI step:

```bash
echo "${{ secrets.GOOGLE_SERVICES_JSON_PROD_BASE64 }}" | base64 --decode > android/app/google-services.json
```

---

## 9) QUALITY GATES (KESİN KABUL KAPILARI)

Bir release tag’i geçerli sayılmadan önce:

* `flutter analyze` temiz
* `dart format` temiz
* `flutter test` temiz
* Release build başarılı
* Firebase rules deploy başarılı (opsiyonel ama önerilir)
* Play upload başarılı

---

## 10) RELEASE CHECKLIST (MANUEL)

Release öncesi:

* `pubspec.yaml` versiyon arttır
* `CHANGELOG.md` güncelle (varsa)
* `vX.Y.Z` tag oluştur ve push et

Release sonrası:

* Play Console’da rollout kontrol et
* Crashlytics / analytics izle
* Hotfix gerekiyorsa `hotfix/*` ile ilerle

---

## 11) GEREKLİ SECRETS LİSTESİ (TOPLU)

GitHub Repo → Settings → Secrets and variables:

### Android Signing

* `ANDROID_KEYSTORE_BASE64`
* `ANDROID_KEYSTORE_PASSWORD`
* `ANDROID_KEY_ALIAS`
* `ANDROID_KEY_PASSWORD`

### Google Play

* `PLAY_SERVICE_ACCOUNT_JSON_BASE64`

### Firebase

* `FIREBASE_SERVICE_ACCOUNT_BASE64`
* `FIREBASE_PROJECT_ID_STAGING`
* `FIREBASE_PROJECT_ID_PROD`

### Firebase App Config

* `GOOGLE_SERVICES_JSON_STAGING_BASE64`
* `GOOGLE_SERVICES_JSON_PROD_BASE64`

---

## 12) BU CI/CD’NİN SINIRLARI (BİLİNÇLİ)

* E2E UI testleri (Flutter integration_driver) opsiyonel
* iOS pipeline bu dokümanda yok (iOS geldiğinde ayrı workflow)

---

## ✅ SONUÇ

Bu CI/CD ile:

* PR’lar otomatik kalite kontrolünden geçer
* Staging build otomatik üretilebilir
* Production release tag ile tek komutla dağıtılır
* Firebase rules/config güvenli şekilde yönetilir
* Flutter cross-platform hedefi korunur

```
```
