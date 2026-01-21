# MIGRATIONS.md — Schema + Payload Migration

## 1) Versiyonlama
- App schema version: integer
- DB schema migrations: Drift migration scripts
- Payload version: her payload_json içinde payload_version

## 2) Kurallar
- Backward compatibility: mümkünse okuma destekle
- Migration öncesi backup:
  - DB dosyasını kopyala
  - Kritik asset indekslerini doğrula

## 3) Örnek Senaryo
v1.0 -> v1.1:
- blocks.payload_json içine yeni alan ekleniyor:
  - Text: style.align default 'left'
Migration:
- payload_version bump
- eksik alan varsa default ekle

## 4) Data Integrity Kontrolleri
- orphan pages? (journal_id yok)
- orphan blocks? (page_id yok)
- orphan assets? (block yok)
- checksum mismatch (opsiyon)

## 5) Rollback
- Migration fail → backup restore
- Recovery snapshot ile kullanıcı akışı: “Kurtarma öner”
