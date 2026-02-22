# PRIVACY.md — Veri Minimizasyonu

## 1) Varsayılan
- İçerik (text/image/audio/ink) kullanıcıya aittir, analiz edilmez.
- Telemetry privacy-safe: sadece performans ve hata metrikleri.

## 2) Toplanan Telemetry (Örnek)
- crash_count
- save_duration_ms histogram
- sync_latency_ms histogram
- pending_oplog_size
- frame_time buckets (coarse)

## 3) Toplanmayan
- Metin içeriği
- Foto/ses/ink verisi
- Lokasyon
- Kişi listesi

## 4) Veri Silme
- Kullanıcı “hesabı sil”:
  - Firestore+Storage purge
  - Local cleanup
- Local delete: soft delete + background purge policy
