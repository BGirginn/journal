# DATA_MODEL.md — Drift/SQLite Şeması

## Temel Kavramlar
- Journal: defter
- Page: journal içinde sıralı sayfa
- Block: sayfadaki taşınabilir öğe
- Asset: block medyası (image/audio/ink/thumb)
- Oplog: işlemler kuyruğu ve uygulanma kaydı

## Ortak Alanlar (Tüm entity’ler)
- id (TEXT, PK)
- schema_version (INT)
- created_at / updated_at (epoch ms)
- deleted_at (nullable, soft delete)

## Koordinat Standardı
- x,y,w,h normalize [0..1]
- rotation_deg degree

## Tablolar (Özet)
### journals
- id, title, cover_style, owner_user_id, is_group, timestamps

### pages
- id, journal_id, page_index, background_style, thumbnail_asset_id, timestamps
- Unique (journal_id, page_index)

### blocks
- id, page_id, type, x,y,w,h, rotation_deg, z_index, payload_json, timestamps

### assets
- id, owner_block_id, kind, local_path, remote_url, meta_json, checksum, size_bytes, timestamps

### oplog
- id, user_id, journal_id, page_id?, block_id?
- op_type, hlc, device_id, payload_json
- status (pending/sent/acked/applied/failed)
- created_at

## Payload Versioning
- payload_json içinde payload_version tutulur.
- Migration: payload_version bump → migration pipeline.

## İndeksler (Performans)
- blocks(page_id, deleted_at, z_index)
- pages(journal_id, deleted_at, page_index)
- journals(owner_user_id, updated_at desc)
- oplog(user_id, status, created_at)

## Soft Delete Politikası
- Silme: deleted_at set
- Sync: tombstone ile yay
- Cleanup: background job fiziksel dosya siler (assets) + purge policy (ör. 30 gün)
