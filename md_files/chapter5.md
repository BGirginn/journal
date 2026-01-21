````md
# FAZ 5 – SOCIAL & COLLABORATION (faz5.md)

**Amaç:**  
Uygulamayı bireysel journal’dan çıkarıp **kontrollü, kapalı ve amaç odaklı bir paylaşım sistemine** dönüştürmek.  
Bu fazda ürün **sosyal ağ olmaz**, **keşfet / feed / public paylaşım içermez**.  
Odak: *ortak defter*, *asenkron çalışma*, *veri güvenliği*.

---

## 🎯 FAZ 5 NET HEDEFLER (KESİN)

Bu faz sonunda kullanıcı:

- Hesap oluşturabilir
- Bir journal’ı **özel grup journal** olarak tanımlayabilir
- Davet ile kullanıcı ekleyebilir
- Roller üzerinden yetki yönetebilir
- Birden fazla cihazda aynı journal’a erişebilir
- Offline çalışıp sonradan senkronize olabilir

Bu faz **bilinçli olarak**:
- sosyal feed içermez
- herkese açık paylaşım içermez
- like / reaction / yorum içermez
- gerçek zamanlı birlikte yazma içermez

---

## 🧱 TEMEL STRATEJİK KARARLAR

### 1. Social ≠ Collaboration  
Bu faz **iletişim** değil **ortak üretim** fazıdır.

- Amaç: “Birlikte defter tutmak”
- Amaç değil: “Başkalarına göstermek”

---

### 2. Realtime Yok, Asenkron Var  
- Cursor paylaşımı yok  
- Canlı yazma yok  
- Aynı anda düzenleme olabilir ama **senkron değil**

Conflict çözümü deterministic olacak.

---

## 👤 AUTH & KULLANICI SİSTEMİ

### Kullanılacak Servis (KESİN)
- **Firebase Authentication**

### Desteklenen Yöntemler
- Email / Password
- Google Sign-In

(Apple ID sadece iOS gelirse)

---

### User Model (Minimum)
```dart
class UserModel {
  final String uid;
  final String email;
  final DateTime createdAt;
}
````

---

## 📚 JOURNAL TİPLERİ

### JournalType

```dart
enum JournalType {
  personal,
  group
}
```

### Kurallar

* Personal journal → sadece owner erişir
* Group journal → üyeler erişir
* Journal tipi sonradan **değiştirilemez**

---

## 👥 ROL & YETKİ MODELİ (KESİN)

### Roller

```dart
enum JournalRole {
  owner,
  editor,
  viewer
}
```

---

### Yetki Matrisi

| İşlem                  | Owner | Editor | Viewer |
| ---------------------- | ----- | ------ | ------ |
| Journal silme          | ✅     | ❌      | ❌      |
| Üye ekleme / çıkarma   | ✅     | ❌      | ❌      |
| Rol değiştirme         | ✅     | ❌      | ❌      |
| Sayfa ekleme           | ✅     | ✅      | ❌      |
| Block ekleme/düzenleme | ✅     | ✅      | ❌      |
| Sadece görüntüleme     | ✅     | ✅      | ✅      |

---

## ☁️ BACKEND & VERİ KATMANI

### Backend (KESİN)

* Firebase Firestore → metadata
* Firebase Storage → medya
* Firebase Auth → kullanıcı

---

### Firestore Koleksiyon Yapısı

```
users/{userId}

journals/{journalId}
  - title
  - type
  - ownerId
  - themeId
  - createdAt
  - updatedAt

journal_members/{id}
  - journalId
  - userId
  - role

pages/{pageId}
  - journalId
  - pageIndex
  - updatedAt

blocks/{blockId}
  - pageId
  - type
  - data
  - x, y, width, height
  - rotation
  - zIndex
  - updatedAt
```

---

### Storage Yapısı

```
images/{journalId}/{blockId}.jpg
audio/{journalId}/{blockId}.m4a
```

---

## 🔄 SYNC ENGINE (EN KRİTİK KISIM)

### Sync Yaklaşımı

* **Offline-first**
* **Delta sync**
* **Timestamp bazlı conflict çözümü**

---

### Sync Seviyeleri

* Journal
* Page
* Block

Her seviye **bağımsız** senkronize edilir.

---

### Sync Service

```dart
class SyncService {
  Future<void> syncJournals();
  Future<void> syncPages(String journalId);
  Future<void> syncBlocks(String pageId);
}
```

---

### Sync Akışı (KESİN)

1. Local DB’de `dirty = true` olan kayıtları bul
2. Cloud’a push et
3. Cloud’daki güncel verileri çek
4. Conflict varsa:

   * `updatedAt` büyük olan kazanır
5. Local DB güncellenir
6. `dirty = false`

---

### Conflict Senaryoları

#### Aynı block iki cihazda değiştiyse:

* `updatedAt` newer olan overwrite eder

#### Aynı anda page silinip edit edildiyse:

* **Silme kazanır**

---

## 📱 MULTI-DEVICE DAVRANIŞI

### Yeni Cihazda Login

1. Kullanıcı login olur
2. Journal listesi çekilir
3. Pages & blocks metadata indirilir
4. Media **lazy-load** edilir

---

### Offline → Online Geçiş

* Otomatik sync tetiklenir
* Kullanıcıya modal gösterilmez
* Arka planda sessiz çalışır

---

## 🔔 BİLDİRİM STRATEJİSİ (MINIMUM)

### Gönderilecek Bildirimler

* Journal daveti
* Üyelik kabulü / reddi

### Gönderilmeyecekler

* Edit bildirimleri
* “X şunu yazdı” uyarıları
* Aktivite spam’i

---

## 🔐 GÜVENLİK KARARLARI

### Firestore Rules

* Kullanıcı sadece üyesi olduğu journal’ları okuyabilir
* Write izinleri role göre kontrol edilir

### Storage Rules

* Sadece ilgili journal üyeleri dosyaya erişir

---

## 🧠 UX TASARIM KARARLARI

* Grup journal = **kapalı alan**
* Kullanıcılar “izleniyor” hissi almaz
* Kim ne zaman edit etti:

  * detaylı log yok
  * sadece `updatedAt` bilgisi

---

## ❌ BİLİNÇLİ OLARAK YAPILMAYANLAR

* Realtime collaboration
* Yorumlar
* Emojiler
* Public paylaşım linkleri
* Discover / Explore

---

## ✅ FAZ 5 ÇIKIŞ KRİTERLERİ

* [ ] Grup journal stabil çalışıyor
* [ ] Rol yetkileri doğru uygulanıyor
* [ ] Offline → online sync hatasız
* [ ] Veri kaybı yaşanmıyor
* [ ] Uygulama sosyal ağ gibi hissettirmiyor

---
