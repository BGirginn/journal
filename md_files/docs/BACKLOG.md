# BACKLOG.md — Sprint 0–4 (Acceptance Criteria + Test)

> Not: Bu backlog “MVP + Auth + Sync” hedefiyle yazılmıştır. Scope şişirme yok.

---

## Sprint 0 — Engine Spike (1 hafta)
### S0-01 Drift DB bootstrap
- AC:
  - DB açılıyor/kapanıyor
  - journals/pages/blocks/assets/oplog tabloları oluşturuluyor
- Test:
  - unit: open/close DB

### S0-02 AssetStore atomic write
- AC:
  - temp->rename ile image yazma
  - checksum hesaplama
- Test:
  - integration: write/read + checksum

### S0-03 Editor canvas host
- AC:
  - boş sayfada frame drops yok
  - page size hesaplama (normalize mapping)
- Test:
  - manual: fps overlay

### S0-04 Block hit-test v1
- AC:
  - üstteki zIndex block seçilir
  - rotation olsa da doğru seçim
- Test:
  - unit: point-in-rotated-rect

### S0-05 Transform move/resize/rotate v1 (ephemeral)
- AC:
  - block taşınır, resize, rotate
  - min size clamp
- Test:
  - unit: transform math
  - manual: gesture

### S0-06 Command history skeleton
- AC:
  - undo/redo çalışır (move)
  - coalesce: drag end’de tek komut
- Test:
  - unit: history stack

### S0-07 Autosave debounce v1 (local only)
- AC:
  - 1500ms sonra DB’ye yazar
  - UI state “saved”
- Test:
  - integration: dirty->save

---

## Sprint 1 — Library + Journal View (1.5 hafta)
### S1-01 Library Screen
- AC:
  - journal list (grid)
  - create journal dialog
- Test:
  - widget test: empty state + create

### S1-02 Journal CRUD (local)
- AC:
  - create/delete (soft)
  - updated_at sıralama
- Test:
  - unit: repository CRUD

### S1-03 Pages CRUD
- AC:
  - page add (append)
  - page_index unique
- Test:
  - unit: page index

### S1-04 Journal View PageView
- AC:
  - swipe ile sayfa gezme
  - sayfa preview placeholder
- Test:
  - widget: page count

### S1-05 Editor routing
- AC:
  - sayfa tap -> editor açılır
  - geri -> state korunur
- Test:
  - integration: navigation

---

## Sprint 2 — Blocks v1 (2 hafta)
### S2-01 TextBlock render + edit
- AC:
  - double tap -> edit
  - commit -> payload update
- Test:
  - widget: edit flow

### S2-02 ImageBlock pick + polaroid frame
- AC:
  - galeriden seç -> asset yaz -> block ekle
  - caption edit
- Test:
  - integration: pick + persist

### S2-03 InkBlock draw -> ink.bin
- AC:
  - pen mode çizim
  - ink.bin yazılır
- Test:
  - integration: draw->save->reload

### S2-04 Z-index actions
- AC:
  - bring front / send back
  - selection doğru
- Test:
  - unit: z reorder

### S2-05 Render caching baseline
- AC:
  - drag sırasında outline preview
  - gesture end -> full render
- Test:
  - manual: fps

---

## Sprint 3 — Sync v1 (2 hafta)
### S3-01 Firebase Auth
- AC:
  - sign-in/out
  - userId elde
- Test:
  - manual: login flows

### S3-02 Oplog enqueue on local commit
- AC:
  - block create/move/payload update oplog yazıyor
  - status=pending
- Test:
  - unit: oplog rows

### S3-03 Uploader: pending->Firestore
- AC:
  - idempotent upload
  - ack update
- Test:
  - integration: offline->online

### S3-04 Listener: Firestore->apply local
- AC:
  - device A change -> device B görüyor
  - alreadyApplied kontrol
- Test:
  - integration: 2 device sim

### S3-05 Conflict rules v1
- AC:
  - transform LWW (HLC)
  - tombstone delete wins
  - text edit lease basic
- Test:
  - unit: apply rules

### S3-06 Asset upload/download
- AC:
  - image + ink upload
  - other device downloads
- Test:
  - integration: placeholder->ready

---

## Sprint 4 — Stabilizasyon (1 hafta)
### S4-01 Crash recovery snapshot
- AC:
  - save öncesi snapshot
  - restart -> restore prompt
- Test:
  - manual: force kill

### S4-02 Perf pass
- AC:
  - 30 block page lag yok
  - ink 2000 point lag yok
- Test:
  - perf checklist

### S4-03 Migration framework
- AC:
  - schema_version constant
  - empty migration scaffold
- Test:
  - unit: migrate no-op

### S4-04 QA + Beta build
- AC:
  - Android internal test
  - iOS TestFlight
- Test:
  - release checklist

---
