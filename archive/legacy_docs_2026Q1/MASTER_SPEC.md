# MASTER_SPEC.md — Journal (iOS + Android) Cross-Platform Offline-First + Realtime Sync
Version: 1.0  
Owner: Bora  
Last Updated: 2026-01-01  

---

## 0) Tek cümle ürün tanımı
Bu uygulama, kullanıcıların anılarını “defter/sayfa” metaforuyla, sürükle-bırak bloklarla (metin, fotoğraf/polaroid, el yazısı; sonra ses) offline oluşturup, aynı hesapla birden fazla cihazda eşzamanlı güncelleyebildiği bir mobil journaling editörüdür.

---

## 1) Hedefler ve Hedef Dışı

### 1.1 Hedefler (Non-negotiable)
- Cross-platform: iOS + Android tek codebase
- Offline-first: internet yokken tam çalışma; internet gelince otomatik sync
- Realtime: aynı hesaptaki 2 cihazda aynı defter güncellenince anlık/çok hızlı görünür
- Editor kalitesi: taşı/yeniden boyutlandır/döndür, zIndex, undo/redo, autosave, crash recovery
- Veri bütünlüğü: “kaydetmedim gitti” kabul edilemez
- Migration destekli veri modeli: schema/payload değişiminde kullanıcı verisi bozulmaz

### 1.2 Hedef dışı (v1 / MVP’de yok)
- Public paylaşım, feed, keşfet
- Gamification (streak, puan, badge)
- AI/OCR/otomatik içerik üretimi
- Video block
- Grup journal (v1.0’da yok; v1.3+)
- PDF/ZIP export (v1.2+)

---

## 2) Kilit Teknoloji Kararları

### 2.1 Client
- Flutter (Dart)
- State: Riverpod
- Rendering: CustomPainter + composited layer yaklaşımı (RepaintBoundary)
- Storage: Drift (SQLite)

### 2.2 Backend (Multi-device + realtime için zorunlu)
- Firebase Auth (Apple/Google/Email)
- Firestore: metadata + operation log (oplog)
- Cloud Storage: medya dosyaları (image/audio/ink blobs)

### 2.3 Koordinat ve rotasyon standardı (Cross-device stabil)
- Block koordinatları normalize: x,y,w,h ∈ [0..1] (page space)
- Rotation: DB’de degree saklanır (float). Engine içi trig için gerektiğinde radian’a çevrilir.

### 2.4 Handwriting storage (kalite odaklı)
- Handwriting stroke verisi JSON olarak şişirilmez.
- Ink: binary blob (DB BLOB veya file asset: ink.bin) + meta JSON
- Baseline: delta encoding + varint packing (opsiyonel quantization)

---

## 3) Terminoloji (Sözlük)
- Journal: Defter
- Page: Sayfa
- Block: Sayfa üstündeki taşınabilir öğe (text/image/ink/audio)
- Asset: Block’un bağlı medya dosyası (jpg, m4a, ink.bin)
- Oplog: Operation log; “state” yerine “işlemler”in kaydı
- DeviceId: cihaz kimliği (UUID, local install)
- ActorId: işlem üreticisi (userId + deviceId)
- HLC: Hybrid Logical Clock (timestamp + counter) (opsiyonel ama önerilir)

---

## 4) UX Akışları (MVP)

### 4.1 Onboarding (FTUE)
- İlk açılış: “İlk Defterini Oluştur”
- 3 basit kapak seçimi (default assets)
- İlk sayfada mini tutorial:
  - Text ekle → sürükle → foto ekle → kaydedildi göstergesi

### 4.2 Library (Defterlerim)
- Grid view
- Yeni Defter
- Defter kartı: kapak + başlık + son düzenleme + küçük thumbnail (opsiyon)

### 4.3 Journal View
- PageView ile sayfa çevirme
- Sayfa ekle (+)
- Sayfaya dokun → Editor

### 4.4 Editor
- Canvas alanı (page)
- Toolbar: Text / Photo / Pen (Ink) / Delete / BringFront / SendBack
- Üst bar: Undo / Redo, Save state
- Gesture:
  - Block seç → move/resize/rotate
  - Pen modunda: çizim (block selection kapalı veya sınırlı)

---

## 5) Mimari (Client)

### 5.1 Katmanlar
- Presentation (UI)
  - Screens, widgets
  - Gesture recognizers
  - Renderer host
- Editor Engine (Domain)
  - Hit-test, transform math
  - Command history
  - Autosave state machine
  - Render caching rules
- Data (Local)
  - Drift DB + DAOs
  - Asset store (files)
  - Migrations
- Sync (Remote)
  - Oplog producer/consumer
  - Conflict resolution rules
  - Upload/download assets
  - Reconciliation & compaction

### 5.2 Ana prensip
UI state (ephemeral) ile kalıcı state ayrıdır:
- Drag sırasında state RAM’de akar (60 FPS)
- Gesture end’de tek bir commit (DB + oplog)

---

## 6) Veri Modeli (Local SQLite / Drift)

### 6.1 Ortak alanlar
- id TEXT PRIMARY KEY
- schema_version INTEGER NOT NULL
- created_at INTEGER NOT NULL (epoch ms)
- updated_at INTEGER NOT NULL
- deleted_at INTEGER NULL

### 6.2 Tables
Detaylı şema için: docs/DATA_MODEL.md

---

## 7) Editor Engine
Detaylı motor spesifikasyonu için: docs/EDITOR_ENGINE.md

---

## 8) Sync
Detaylı sync protokolü için: docs/SYNC_PROTOCOL.md

---

## 9) Güvenlik / Gizlilik / Test / Performans
- docs/SECURITY.md
- docs/PRIVACY.md
- docs/TEST_PLAN.md
- docs/PERFORMANCE.md

---

## 10) Release
Release checklist: docs/RELEASE_CHECKLIST.md

---
