# STORAGE_MEDIA.md — Dosya Sistemi, Formatlar, Checksum

## 1) Local Layout
/journals/{journalId}/pages/{pageId}/blocks/
- {blockId}_image.jpg
- {blockId}_audio.m4a
- {blockId}_ink.bin

/journals/{journalId}/thumbs/
- {pageId}.jpg

/cache/render_cache/
- {blockId}.png

## 2) Atomic Write
- temp dosyaya yaz
- fsync (mümkünse)
- rename ile replace

## 3) Image
- Input: picker (HEIC/JPEG)
- Store: JPEG (quality 85) veya platform native + meta
- Meta: original w/h, orientation

## 4) Audio (v1.2+)
- Store: AAC (m4a)
- Meta: duration_ms, sampleRate

## 5) Ink Binary (v1)
### Hedef
- küçük boyut
- hızlı append
- hızlı decode

### Format (öneri)
Header:
- magic 'INK1'
- version u16
- stroke_count u32 (opsiyon)
Body:
- stroke records:
  - color u32 (ARGB)
  - width f32
  - point_count u32
  - points: delta-encoded int16/int32 + varint
  - optional: t delta, pressure

Checksum:
- SHA-256 asset checksum DB’de tutulur.

## 6) Thumbnail
- Render: düşük çözünürlük (örn 512px uzun kenar)
- Cache invalidation: page updatedAt değişince
