# CHAPTER 7 — SYSTEM VERIFICATION, QA & CLEANUP (chapter7.md)

**Amaç:**  
FAZ 1 → FAZ 6 boyunca geliştirilen **tüm sistemi tek bir noktada toparlamak**,  
**doğrulamak**, **test etmek**, **temizlemek** ve **yayına hazır hale getirmek**.

Bu chapter **yeni özellik eklemez**.  
Sadece: *kontrol, denetim, sağlamlaştırma* yapar.

---

## 🎯 CHAPTER 7 NET HEDEFLER (KESİN)

Bu chapter tamamlandığında:

- Tüm fazlar birlikte sorunsuz çalışır
- Veri kaybı riski minimize edilmiştir
- Edge-case senaryolar test edilmiştir
- Kod, asset ve veri borcu temizlenmiştir
- Yayına (store submission / beta) hazır durumdadır

---

## 🧱 KAPSAM SINIRLARI

### Dahil
- Fonksiyonel testler
- Entegrasyon testleri
- Offline / online senaryolar
- Performans & stres testleri
- Güvenlik kontrolleri
- Kod ve asset temizliği
- Release hazırlığı

### Hariç
- Yeni feature
- UX redesign
- Yeni tema / asset
- Yeni monetization kararı

---

## 🧪 TEST STRATEJİSİ (GENEL)

### Test Seviyeleri
1. Unit Test
2. Integration Test
3. System Test
4. Manual QA (gerçek kullanıcı senaryosu)

Flutter uygulama **tamamı bu dört seviyeden geçmeden** release edilmez.

---

## 🔬 1. CORE ENGINE DOĞRULAMA

### Journal / Page / Block

#### Kontroller
- Journal silinince:
  - bağlı page’ler siliniyor mu?
  - bağlı block’lar siliniyor mu?
- Page sıralaması bozuluyor mu?
- Block z-index doğru mu?

#### Edge-case
- 0 page journal
- 1 page → sil → yeniden ekle
- Aynı sayfada 50+ block

---

## 🧪 2. FAZ BAZLI REGRESSION TESTLERİ

### FAZ 1 — Core
- Local storage restart sonrası tutarlı mı?
- Editor crash olmadan çalışıyor mu?

### FAZ 2 — Themes
- Tema değişimi eski journal’ları bozmuyor mu?
- Asset eksikse fallback çalışıyor mu?

### FAZ 3 — Power Features
- Audio block silinince dosya da siliniyor mu?
- PDF export büyük journal’da çalışıyor mu?
- Backup → restore birebir mi?

### FAZ 4 — Cloud & Sync
- Offline edit → online sync sorunsuz mu?
- Conflict çözümü deterministic mi?
- Media lazy-load doğru mu?

### FAZ 5 — Collaboration
- Rol ihlali mümkün mü?
- Viewer edit yapabiliyor mu?
- Journal daveti revoke edilince erişim kesiliyor mu?

### FAZ 6 — Monetization
- Premium süresi bitince:
  - veri korunuyor mu?
  - UI doğru kilitleniyor mu?
- Restore purchase her cihazda çalışıyor mu?

---

## 🌐 3. OFFLINE / ONLINE SENARYOLARI (KRİTİK)

### Test Edilecek Senaryolar
- Offline journal oluştur → online sync
- Offline audio kaydet → online yükleme
- Offline premium cache → online entitlement doğrulama
- Offline backup → restore

---

## 🚀 4. PERFORMANS & STRES TESTLERİ

### Senaryolar
- 20 journal
- Journal başına 50 sayfa
- Sayfa başına 30 block
- 10 audio block

### Ölçümler
- Sayfa çevirme FPS ≥ 60
- Editor response < 16ms
- Memory leak yok
- Storage şişmesi kontrol altında

---

## 🔐 5. GÜVENLİK & YETKİ DENETİMİ

### Firestore Rules
- Role-based write testleri
- Unauthorized erişim denemeleri

### Storage Rules
- Journal dışı media erişimi mümkün mü?

### Client-side
- UI bypass mümkün mü?
- Entitlement spoof edilebiliyor mu?

---

## 🧹 6. TEMİZLİK (TECH DEBT & ASSET)

### Kod Temizliği
- Dead code sil
- Feature flag’leri kapat
- Debug log’ları kaldır

### Asset Temizliği
- Kullanılmayan tema asset’leri
- Duplicate görseller
- Büyük dosyalar (optimize)

---

## 📦 7. RELEASE HAZIRLIĞI

### Flutter Build
- `flutter analyze` temiz
- `flutter test` temiz
- `flutter build` warningsiz

### Store Hazırlığı
- App icon
- Splash
- Screenshot’lar
- Privacy policy
- Permission açıklamaları

---

## 📋 8. KABUL KRİTERLERİ (CHECKLIST)

- [ ] Tüm regression testler geçti
- [ ] Crash-free rate ≥ %99
- [ ] Veri kaybı senaryosu yok
- [ ] Offline-first davranış bozulmadı
- [ ] Monetization doğru çalışıyor
- [ ] Güvenlik açıkları kapalı

---

## 🧭 BU CHAPTER’IN FELSEFESİ

> “Yeni özellik eklemek kolaydır.  
> Ama bir ürünü **bırakılmayacak hale getirmek** zordur.”

Bu chapter:
- ürünü olgunlaştırır
- riskleri kapatır
- ekibi (veya seni) rahatlatır

---

## ✅ CHAPTER 7 TAMAMLANDIĞINDA

Uygulama:
- test edilmiş
- denetlenmiş
- temizlenmiş
- yayına hazır

durumdadır.

Bundan sonrası artık **geliştirme değil**,  
**ürün yönetimi ve büyüme** sürecidir.
