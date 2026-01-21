# PROJECT.md — Ürün Çerçevesi

## Vizyon
Kullanıcının anılarını “kusurlu ama dokunulabilir” bir defter deneyimiyle saklaması ve bunu cihazlar arasında kayıpsız taşıması.

## Ürün İlkeleri
1) Offline-first (internet beklemez)
2) His ve akıcılık: editor motoru birinci sınıf
3) Mahremiyet varsayılan: public yok
4) Basit ana döngü: Defter → Sayfa → Blok ekle → Kaydedildi

## Başarı Metrikleri (MVP)
- İlk 5 dakikada: defter oluşturma + 1 sayfaya içerik ekleme
- 7 günlük geri dönüş: %40+ (beta cohort)
- Crash rate: < %1
- Sync tutarlılığı: 2 cihaz senaryosunda “kayıp değişiklik” sıfır

## Anti-Pattern (Yapılmayacaklar)
- Sosyal feed
- Streak/badge/puan
- Zorlayıcı bildirim spam’i
- “Public journal” yayınlama
- AI ile içerik üretimi (v1’de)

## Fazlar
- v0: Engine spike
- v1.0: MVP + auth + sync
- v1.1: polish + app lock
- v1.2: audio + export
- v1.3: grup journal + rol/izin
