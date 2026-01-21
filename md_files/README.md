# Journal App — Offline-first, Defter Metaforlu, Realtime Senkron

## Ürün
- Kullanıcı birden çok **defter (Journal)** oluşturur.
- Defter sayfalardan oluşur.
- Her sayfada **bloklar** vardır: **Metin**, **Fotoğraf (Polaroid)**, **El yazısı (Ink)**. (Ses: v1.2+)
- Uygulama **offline** çalışır; internet gelince **aynı hesapla diğer cihazlara** senkron olur.

## Hızlı Başlangıç (Repo hedefi)
Bu repo, Flutter + Drift + Firebase (Auth/Firestore/Storage) tabanlıdır.

### Gereksinimler
- Flutter SDK (stable)
- Dart SDK (Flutter ile)
- Android Studio / Xcode
- Firebase project (Auth + Firestore + Storage)

### Çalıştırma (taslak)
1) Firebase yapılandırması:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
2) Paketler:
   - `flutter pub get`
3) Uygulama:
   - `flutter run`

## Kapsam (v1.0 MVP)
- Offline-first defter/sayfa
- Text/Image/Ink blokları
- Taşı/resize/rotate, zIndex
- Undo/Redo
- Autosave + crash recovery
- Auth + Realtime sync (oplog)

## MVP’de yok
- Grup journal
- Public paylaşım/feed
- AI/OCR/video
- Export (PDF/ZIP)

## Dokümantasyon
- MASTER_SPEC.md (tek kaynak)
- docs/ARCHITECTURE.md
- docs/DATA_MODEL.md
- docs/EDITOR_ENGINE.md
- docs/SYNC_PROTOCOL.md
- docs/SECURITY.md
- docs/PRIVACY.md
- docs/TEST_PLAN.md
- docs/PERFORMANCE.md
- docs/RELEASE_CHECKLIST.md
- docs/BACKLOG.md

## Repo Yapısı (öneri)
- lib/
  - core/ (model, db, storage, utilities)
  - features/
    - library/
    - journal/
    - editor/
  - sync/
- docs/
- test/
