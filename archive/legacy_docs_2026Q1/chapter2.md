```md
# FAZ 2 — EXPERIENCE & THEMES (faz2.md)

**Hedef:**  
FAZ 1’de tamamlanan journal motorunun üstüne, **yazma isteğini artıran deneyim katmanını** eklemek.  
Bu fazda ürün hâlâ **offline-first**, **single-user** kalır.

---

## 🎯 FAZ 2 HEDEF VE KAPSAM

### Ana Hedefler
- Tema sistemi eklemek (defter + sayfa + davranış)
- Görsel ve etkileşimsel deneyimi zenginleştirmek
- Journal hissini güçlendirmek (ritüel, kusur, dokunsallık)

### Kapsam Dahilinde
- Tema altyapısı (JSON tabanlı)
- Çoklu defter temaları
- Polaroid image block
- Sticker & dekoratif asset’ler (base)
- Sayfa açılış / kapanış efektleri
- Boş sayfa mikro ipuçları

### Kapsam Dışı (Faz 3+)
- ❌ Login / hesap
- ❌ Cloud sync
- ❌ Grup journal
- ❌ Audio block
- ❌ Export (PDF/ZIP)
- ❌ Ödeme / abonelik

---

## 🧱 FAZ 2 TEKNOLOJİ EKLERİ (FLUTTER)

### Yeni Paketler
- `flutter_svg` (sticker / dekor)
- `just_audio` (sayfa sesi için – opsiyonel)
- `collection` (tema konfigürasyonları için)

---

## 📁 FAZ 2 PROJE YAPISI EKLERİ

```

lib/
├── themes/
│   ├── theme_model.dart
│   ├── theme_manager.dart
│   ├── default_theme.json
│   ├── after_school_2004.json
│   ├── junk_scrapbook.json
│   └── night_thoughts.json
├── assets/
│   ├── themes/
│   │   ├── paper/
│   │   ├── covers/
│   │   └── textures/
│   └── stickers/

````

---

## 🎨 TEMA SİSTEMİ

### Tema Tanımı
Tema = görsel + etkileşim + mikro davranış seti

### Theme Model
```dart
class JournalTheme {
  final String id;
  final String name;
  final String coverAsset;
  final String pageBackground;
  final String defaultFont;
  final double rotationVariance;
  final bool snapToGrid;
  final List<String> pageHints;
  final String pageTurnSound;

  JournalTheme({
    required this.id,
    required this.name,
    required this.coverAsset,
    required this.pageBackground,
    required this.defaultFont,
    required this.rotationVariance,
    required this.snapToGrid,
    required this.pageHints,
    required this.pageTurnSound,
  });
}
````

---

### Tema JSON Örneği

```json
{
  "id": "after_school_2004",
  "name": "After School Bedroom",
  "coverAsset": "assets/themes/covers/after_school.png",
  "pageBackground": "assets/themes/paper/pastel.png",
  "defaultFont": "handwritten_soft",
  "rotationVariance": 3,
  "snapToGrid": false,
  "pageHints": [
    "Bugün okuldan sonra ne yaptın?",
    "Aklında kalan küçük bir an var mı?"
  ],
  "pageTurnSound": "paper_soft.wav"
}
```

---

## 📘 SPRINT 1 — TEMA ALTYAPISI (HAFTA 1)

### Milestone 1.1 — Theme Manager

* Tema JSON’larını yükleme
* Aktif temayı bellekte tutma
* Journal’a tema bağlama

```dart
class ThemeManager {
  JournalTheme activeTheme;
  void loadTheme(String themeId);
}
```

✔️ Tema değişince UI otomatik güncellenir

---

### Milestone 1.2 — Journal Tema Bağlantısı

* Journal modeline `themeId` ekle
* Journal açılırken tema yükle
* Default theme fallback

✔️ Her defter kendi temasını taşır

---

## 📗 SPRINT 2 — GÖRSEL DENEYİM (HAFTA 2)

### Milestone 2.1 — Kapak Tasarımları

* Tema bazlı kapak görselleri
* Kapak açılma animasyonu
* Defter açılış ritüeli

✔️ “Editöre girmek” yerine “defteri açmak”

---

### Milestone 2.2 — Sayfa Arka Planları

* Tema bazlı kağıt dokuları
* Doku tekrarları (tiling)
* Performans için cache

✔️ Her tema farklı kağıt hissi verir

---

## 📙 SPRINT 3 — POLAROID & STICKER (HAFTA 3)

### Milestone 3.1 — Polaroid Image Block

* Image block’un özel varyantı
* Beyaz çerçeve
* Tarih / küçük not alanı

```dart
enum ImageStyle { normal, polaroid }
```

✔️ Fotoğraf “yapıştırılmış” hissi verir

---

### Milestone 3.2 — Sticker System (Base)

* SVG / PNG sticker’lar
* Drag & drop
* Sticker = özel BlockType

```dart
enum BlockType {
  text,
  image,
  handwriting,
  sticker
}
```

✔️ Scrapbook hissi oluşur

---

## 📕 SPRINT 4 — MİKRO UX & RİTÜEL (HAFTA 4)

### Milestone 4.1 — Boş Sayfa İpuçları

* Tema bazlı page hints
* Çok silik placeholder
* İlk etkileşimde kaybolur

✔️ Boş sayfa korkusu azalır

---

### Milestone 4.2 — Sayfa Sesleri & Gecikme

* Page turn sound (opsiyonel)
* Mikro gecikme (80–120 ms)
* Ayarlardan kapatılabilir

✔️ Sayfa “nesne” gibi algılanır

---

### Milestone 4.3 — Kapanış Ritüeli

* Defter kapanma animasyonu
* Kaydetme bildirimi yok
* Sessiz, yumuşak çıkış

✔️ Kullanıcı rahat bırakılır

---

## 🧪 TEST & KABUL KRİTERLERİ

### Fonksiyonel

* [ ] Tema değişince tüm UI uyumlu
* [ ] Her journal farklı tema taşıyabiliyor
* [ ] Polaroid & sticker block çalışıyor
* [ ] Boş sayfa ipuçları doğru görünüyor

### Performans

* [ ] Tema değişimi < 200 ms
* [ ] Sayfa çevirme 60 FPS
* [ ] Asset cache memory leak yok

### UX

* [ ] Kullanıcı “yazmak istiyorum” hissini alıyor
* [ ] Defter hissi belirgin
* [ ] Karmaşa artmıyor

---

## 📦 FAZ 2 ÇIKIŞ KRİTERİ

FAZ 2 tamamlanmış sayılır eğer:

* Journal artık sadece “çalışan” değil, **hissettiren** bir ürünse
* Temalar kod yazmadan eklenebiliyorsa
* Kullanıcı en az 1 defteri süsleme ihtiyacı hissediyorsa
