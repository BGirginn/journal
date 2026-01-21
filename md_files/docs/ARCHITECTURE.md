# ARCHITECTURE.md

## Sistem Bileşenleri
- Client: Flutter (UI + Editor Engine + Local DB)
- Backend: Firebase Auth (kimlik), Firestore (metadata + oplog), Storage (assets)

## Katmanlar
### Presentation
- Screen’ler: Library, JournalView, Editor
- Ephemeral UI state: selection, drag, in-progress strokes

### Editor Engine (Domain)
- Hit-test
- Transform math
- Gesture arbitration
- Command history (undo/redo)
- Render caching
- Autosave coordinator

### Data (Local)
- Drift DB (SQLite): journals/pages/blocks/assets/oplog
- AssetStore: dosya sistemi
- Migration manager

### Sync (Remote)
- Oplog producer: local commit → oplog enqueue
- Uploader: pending oplog → Firestore
- Listener: Firestore oplog → apply local
- Asset sync: upload/download + checksum

## Tek gerçek kaynak
- Local DB “çalışan state”
- Remote oplog “paylaşılan değişiklik kaydı”
- Reconciliation: local state, remote oplog ile deterministik güncellenir

## İsimlendirme Kuralları
- Id: UUIDv4 string
- DeviceId: install-time UUID (keystore/safe storage)

## Hata Sınıfları
- Data corruption: recovery snapshot
- Sync conflicts: deterministic rules + edit lease (text)
- Asset missing: placeholder + background fetch
