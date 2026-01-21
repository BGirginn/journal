# SYNC_PROTOCOL.md — Oplog + Deterministic Apply

## 1) Problem
Aynı kullanıcı 2 cihazda aynı defteri eşzamanlı düzenler. İnternet kesilir; tekrar gelir. Veri kaybı olmadan birleşmesi gerekir.

## 2) Model
- Local DB: current state
- Remote (Firestore): oplog (işlem kayıtları)
- Asset: Storage’ta binary dosyalar

## 3) Kimlikler
- userId: Firebase UID
- deviceId: install-time UUID
- actorId: userId/deviceId

## 4) Zaman
HLC önerisi:
- hlc = ms:counter:deviceId
- ordering: ms, counter, deviceId

## 5) Oplog Event Yapısı
Fields:
- opId (uuid)
- journalId, pageId?, blockId?
- opType (enum)
- hlc, deviceId, userId
- payload_json

## 6) Gönderim Akışı
1) Local commit (DB transaction)
2) Oplog enqueue (local table status=pending)
3) Uploader pending → Firestore (idempotent)
4) Ack → status=acked/applied

## 7) Dinleme ve Uygulama
- Firestore listener: yeni op → local apply queue
- alreadyApplied kontrolü: opId veya (hlc,deviceId) watermark

## 8) Conflict Kuralları (v1)
### 8.1 Transform (x,y,w,h,rotation,z)
- En yeni HLC kazanır (tek paket)
- Apply: eğer op.hlc > block.last_transform_hlc ise uygula

### 8.2 Payload
- Text edit: edit lease (lock)
  - lock: {blockId, holderDeviceId, expiresAt}
  - edit açan cihaz lease alır (30sn, keepalive)
  - lease yoksa update reddedilir veya kullanıcıya conflict uyarısı
- Image caption: LWW (düşük risk)
- Ink: append merge
  - ink ops event: “append segment”
  - segments HLC sırasıyla birleşir

### 8.3 Delete (tombstone)
- delete op en yeni ise tombstone basar
- tombstone varken update ops ignore

## 9) Asset Sync
- Asset create: local write + checksum
- Upload: Storage upload → remote_url update
- Download: remote_url varsa fetch → local_path set
- Missing asset: placeholder + retry

## 10) Reconciliation / Compaction (v1.2+)
- Oplog büyür → compaction:
  - per block “latest state snapshot” üret
  - eski ops’lar archive

## 11) Failure ve Retry
- exponential backoff
- status=failed -> manual retry opsiyonu
