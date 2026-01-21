````md
# FAZ 6 – MONETIZATION & PLATFORM (faz6.md)

**Amaç:**  
Uygulamayı sürdürülebilir, ölçeklenebilir ve uzun vadede geliştirilebilir bir **ürün platformuna** dönüştürmek.  
Bu fazda odak **para kazanmak kadar**, **yanlış yerden para kazanmamak**tır.  
Journal ruhu korunur; agresif, dikkat dağıtan veya baskıcı monetizasyon yapılmaz.

Bu faz **Flutter (cross-platform)** + **Firebase backend** varsayımıyla tasarlanmıştır.

---

## 🎯 FAZ 6 NET HEDEFLER (KESİN)

Bu faz sonunda:

- Free / Premium ayrımı netleşmiş olur
- Abonelik sistemi çalışır
- Tek seferlik satın alınabilir içerikler (tema, sticker) vardır
- Kullanıcının neye neden para ödediği çok nettir
- Platform izlenebilir (analytics, crash, performance)

Bu faz **bilinçli olarak**:
- reklam içermez
- feed / promoted content içermez
- “paywall first screen” içermez

---

## 🧱 TEMEL STRATEJİK KARARLAR (DEĞİŞMEZ)

### 1. Monetization ≠ Zorlama  
Kullanıcı:
- önce değeri kullanır
- sonra “buna para verilir” hissine ulaşır

---

### 2. Özellik Kilitleme Yerine Kapasite & Konfor  
Premium:
- daha fazlası
- daha rahatı
- daha estetiği

Free:
- asla işlevsiz hissettirilmez

---

### 3. Tek Platform, Çok Cihaz  
- Flutter → Android / iOS
- Abonelik ve entitlement **platformdan bağımsız** yönetilir
- Firebase backend tek kaynak

---

## 💳 ÖDEME & ABONELİK ALTYAPISI

### Kullanılacak Sistem (KESİN)

- **RevenueCat**
- Google Play Billing
- Apple App Store Billing (iOS geldiğinde)

> ❗ Flutter tarafında direkt store API’leriyle uğraşılmaz  
> ❗ Tüm karmaşa RevenueCat’e devredilir

---

### RevenueCat Neden?
- Cross-platform entitlement
- Restore purchase otomatik
- Subscription state tek yerden okunur

---

## 👤 ENTITLEMENT MODELİ

### Entitlement Tanımı
```dart
enum Entitlement {
  free,
  premium
}
````

---

### Kullanıcı Durumu

```dart
class UserEntitlementState {
  final Entitlement level;
  final DateTime? expiresAt;
}
```

---

### Karar Kuralları

* Premium süresi bitince:

  * veri silinmez
  * premium özellikler pasif olur
* Kullanıcı downgrade edildiğinde:

  * journal’lar kalır
  * yeni journal oluşturma sınırlandırılabilir

---

## 🆓 FREE vs 💎 PREMIUM AYRIMI (KESİN)

### FREE KULLANICI

* Maksimum **3 journal**
* Core editor
* 1–2 temel tema
* Local kullanım
* Group journal’a **viewer** olarak katılabilir

---

### PREMIUM KULLANICI

* Sınırsız journal
* Tüm temalar
* Gelişmiş editor araçları
* Cloud sync (FAZ 4’ten)
* Group journal’da **editor / owner**
* PDF export
* Backup & restore

---

## 🏪 ASSET STORE (TEK SEFERLİK SATIŞ)

### Satılabilir İçerikler

* Tema paketleri
* Sticker setleri
* Özel defter kapakları

---

### Asset Türleri

```dart
enum AssetType {
  theme,
  stickerPack,
  cover
}
```

---

### Asset Model

```dart
class StoreAsset {
  final String id;
  final AssetType type;
  final String title;
  final String description;
  final String priceId;
}
```

---

### Asset Satın Alma Davranışı

* Satın alınan asset:

  * kullanıcının hesabına bağlanır
  * cihaz değişince tekrar yüklenir
* Asset silinmez, revoke edilmez

---

## ☁️ BACKEND & VERİ KATMANI

### Firestore Koleksiyonları

```
users/{userId}
  - entitlement
  - createdAt

store_assets/{assetId}
  - type
  - title
  - priceId

user_assets/{id}
  - userId
  - assetId
  - purchasedAt
```

---

### Storage

* Tema / sticker asset’leri:

  * CDN cache’li
  * sadece metadata Firestore’da

---

## 📊 ANALYTICS & İZLEME

### Kullanılacak Servisler

* Firebase Analytics
* Firebase Crashlytics
* Firebase Performance

---

### Takip Edilecek Event’ler (KESİN)

```text
journal_created
page_added
block_added
theme_changed
asset_purchased
subscription_started
subscription_cancelled
export_pdf
```

---

### İzlenmeyecekler

* içerik metni
* kullanıcı yazıları
* ses kayıtları

> ❗ Privacy ihlali yok
> ❗ İçerik **asla** analiz edilmez

---

## 🔐 GÜVENLİK & SUİSTİMAL ÖNLEME

### Entitlement Kontrolü

* UI kontrolü yeterli değil
* Backend tarafında da doğrulanır

### Offline Senaryosu

* Son bilinen entitlement cache’lenir
* Grace period: 24 saat

---

## 🧠 UX & PAYWALL TASARIM KARARLARI

### Paywall Nerede Gösterilir?

* Premium özelliğe tıklanınca
* Journal limiti dolunca

### Nerede Gösterilmez?

* App açılışında
* Editor ortasında
* Yazı yazarken

---

## ❌ BİLİNÇLİ OLARAK YAPILMAYANLAR

* Reklam
* Zorunlu abonelik
* İçeriği kilitleme
* Dark pattern paywall

---

## ✅ FAZ 6 ÇIKIŞ KRİTERLERİ

* [ ] Abonelik satın alma çalışıyor
* [ ] Restore purchase sorunsuz
* [ ] Asset store stabil
* [ ] Premium / free ayrımı net
* [ ] Platform izlenebilir durumda
