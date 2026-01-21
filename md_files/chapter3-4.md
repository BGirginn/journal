````md
# FAZ 3 — POWER FEATURES (faz3.md)

**Amaç:**  
Journal motoru + tema sistemi artık oturmuş kabul edilir.  
Bu fazın hedefi, ürünü “keyifli” olmaktan çıkarıp **gerçekten güçlü ve vazgeçilmez** hale getirmektir.  
Hâlâ **offline-first** yaklaşım korunur. Cloud yoktur.

---

## 🎯 FAZ 3 NET HEDEFLER

Bu faz sonunda kullanıcı:
- Sesli not ekleyebilir
- Journal’ını dışarı aktarabilir (PDF)
- Verisini güvenli şekilde yedekleyebilir
- Editörde daha profesyonel kontrol hissi alır

Bu faz **bilinçli olarak**:
- sosyal değildir
- online değildir
- abonelik içermez

---

## 🧱 FAZ 3 SİSTEMSEL KARARLAR (KESİN)

### 1. Mimari Karar
- **Yeni feature’lar = Core motoru bozmadan eklenen modüller**
- Her yeni özellik:
  - kendi data modeline
  - kendi servis katmanına
  - kendi UI bileşenlerine sahiptir

Core (Journal / Page / Block) **değişmez**.

---

## 🔊 FEATURE 1 — AUDIO BLOCK (SES BLOĞU)

### Amaç
Kullanıcı:
- yazmak istemediği anlarda
- hızlıca sesli not bırakabilsin
- sesi sayfanın bir parçası gibi görsün

---

### Sistem Tasarımı

#### Yeni BlockType
```dart
enum BlockType {
  text,
  image,
  handwriting,
  sticker,
  audio
}
````

---

### Audio Data Model

```dart
class AudioBlockData {
  final String filePath;
  final int durationMs;
  final DateTime recordedAt;

  AudioBlockData({
    required this.filePath,
    required this.durationMs,
    required this.recordedAt,
  });
}
```

---

### Storage Kararı (KESİN)

* **Ses dosyaları:**
  `appDir/audio/{blockId}.m4a`
* **Format:** `AAC (m4a)`
* **Sebep:**

  * Android native destek
  * Küçük boyut
  * Yeterli kalite

---

### Kullanılacak Paket

* `record`
* `just_audio`

---

### Audio Service

```dart
class AudioService {
  Future<String> record(String blockId);
  Future<void> play(String filePath);
  Future<void> stop();
}
```

> Audio ile ilgili **tüm mantık burada** toplanır.
> UI bu servisi **doğrudan değil**, ViewModel üzerinden çağırır.

---

### UI Davranışı (KESİN)

* Audio block:

  * dalga formu göstermez (faz 3’te gerek yok)
  * play / pause butonu vardır
  * süresi yazar
* Audio edit edilmez, sadece:

  * silinir
  * yeniden kaydedilir

---

## 📄 FEATURE 2 — PDF EXPORT

### Amaç

Kullanıcı:

* journal’ını saklayabilsin
* yazdırabilsin
* “gerçek defter” çıktısı alabilsin

---

### Sistem Kararı (ÇOK ÖNEMLİ)

> ❗ PDF export **editör üzerinden yapılmaz**
> ❗ Ayrı bir render pipeline kullanılır

---

### PDF Render Pipeline

```
Journal
 └─ Pages
     └─ Blocks
         └─ PDF Render Layer
```

---

### PDF Render Service

```dart
class PdfExportService {
  Future<File> exportJournalToPdf(String journalId);
}
```

---

### Teknik Yol

* Paket: `pdf`
* Paket: `printing`
* Her Page:

  * A4 boyutuna ölçeklenir
  * Bloklar **orantılı** yerleştirilir
* Rotation korunur
* Tema arka planları PDF’e gömülür

---

### Kapsam Dışı (Bilinçli)

* Audio block PDF’e gömülmez
* Audio için:

  * sayfaya küçük ikon + süre yazılır

---

## 💾 FEATURE 3 — LOCAL BACKUP & RESTORE

### Amaç

* Kullanıcı telefon değiştirirse
* veya veri silinirse
* journal’larını kaybetmesin

---

### Backup Stratejisi (KESİN)

#### Backup İçeriği

* journals.json
* pages.json
* blocks.json
* assets/

  * images/
  * audio/
  * handwriting/

---

### Backup Format

* **ZIP**
* Tek dosya

---

### Backup Service

```dart
class BackupService {
  Future<File> createBackup();
  Future<void> restoreBackup(File zipFile);
}
```

---

### Kullanıcı Akışı

1. Ayarlar → Yedekle
2. ZIP oluşturulur
3. Kullanıcı:

   * dosyayı paylaşır
   * saklar

Restore:

1. ZIP seç
2. Mevcut veriler **silinir**
3. Backup yüklenir

> ❗ Merge YOK
> ❗ Restore = replace

---

## ✏️ FEATURE 4 — EDITOR POWER TOOLS

### Net Kararlar

* Grid sistemi eklenmez (journal ruhuna aykırı)
* Ama:

  * hizalama yardımcıları eklenir
  * snap **opsiyonel**

---

### Eklenecekler

* Çoklu block seçimi
* Bring to front / send to back
* Block kilitleme (move edilemez)

---

## ✅ FAZ 3 ÇIKIŞ KRİTERLERİ

* [ ] Audio block sorunsuz çalışıyor
* [ ] PDF export 10+ sayfalı journal’da stabil
* [ ] Backup → restore veri kaybı olmadan
* [ ] Editör profesyonel ama hâlâ sade

---

---

# FAZ 4 — CLOUD & MULTI-DEVICE (faz4.md)

**Amaç:**
Uygulamayı tek cihazlı defterden çıkarıp
**kişisel ama senkronize bir deneyime** dönüştürmek.

Bu fazdan sonra ürün artık:

* hesaplı
* çok cihazlı
* altyapı gerektiren

bir üründür.

---

## 🎯 FAZ 4 NET HEDEFLER

* Kullanıcı hesabı
* Cloud sync
* Multi-device kullanım
* Altyapı temeli (faz 5 için)

---

## 🧱 FAZ 4 STRATEJİK KARARLAR (KESİN)

### 1. Offline-first KORUNUR

* Cloud = backup + sync
* Offline çalışmazsa FAZ 4 başarısızdır

---

### 2. Conflict Resolution (ÇOK KRİTİK)

* Realtime collaboration YOK
* Aynı anda 2 cihazda edit:

  * **Last write wins**
  * Page & Block bazında timestamp

---

## 👤 FEATURE 1 — AUTH SYSTEM

### Sistem Kararı

* **Firebase Authentication**
* Email + Google
* Apple (iOS gelirse)

---

### User Model

```dart
class User {
  final String uid;
  final String email;
  final DateTime createdAt;
}
```

---

## ☁️ FEATURE 2 — CLOUD STORAGE

### Servis Kararı (KESİN)

* **Firebase Firestore** → metadata
* **Firebase Storage** → media files

---

### Veri Ayrımı

#### Firestore

* journals
* pages
* blocks
* themeId
* timestamps

#### Storage

* images/{userId}/{blockId}.jpg
* audio/{userId}/{blockId}.m4a

---

## 🔄 FEATURE 3 — SYNC ENGINE

### Sync Yaklaşımı

* Delta sync
* Timestamp bazlı

---

### Sync Service

```dart
class SyncService {
  Future<void> sync();
}
```

---

### Sync Flow

1. Local değişiklikleri bul
2. Cloud’a gönder
3. Cloud’daki yeni verileri çek
4. Conflict varsa:

   * latest updatedAt kazanır

---

## 📱 FEATURE 4 — MULTI DEVICE

### Davranış

* Yeni cihazda login
* Tüm journal’lar indirilir
* Media lazy-load edilir

---

## 🔐 SECURITY KARARLARI

* Firestore rules:

  * userId eşleşmesi zorunlu
* Storage rules:

  * kullanıcı sadece kendi dosyalarını görür
* Local DB şifreleme (opsiyonel)

---

## ❌ BİLİNÇLİ DIŞARIDA

* Realtime cursor
* Live typing
* Shared journal (faz 5)

---

## ✅ FAZ 4 ÇIKIŞ KRİTERLERİ

* [ ] Login stabil
* [ ] 2 cihazda sync tutarlı
* [ ] Offline → online geçiş sorunsuz
* [ ] Veri kaybı yok
