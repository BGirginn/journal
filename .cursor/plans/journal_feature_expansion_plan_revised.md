---
name: Journal Feature Expansion Plan - Revize (Mevcut Durum Analizi)
overview: "Proje baştan taranmış, mevcut özellikler analiz edilmiş. Yapılmış özellikler işaretlenmiş, eksikler ve iyileştirmeler belirlenmiş."
todos:
  - id: profile_settings_unified
    content: Profil ve Ayarları birleştir - tek ekran, profil üstte ayarlar altta
    status: pending
  - id: color_theme_selector_ui
    content: Renk temaları seçici UI ekle (settings'te AppColorTheme seçimi)
    status: pending
  - id: main_theme_integration
    content: Main.dart'ta renk temasını provider'dan al (şu an purple sabit)
    status: pending
  - id: image_rotate_ui
    content: Resim döndürme UI - toolbar'a döndürme butonu ekle
    status: pending
  - id: audio_recording_ui_improvement
    content: Ses kaydı UI iyileştirme - duration tracking, gelişmiş dialog, waveform
    status: pending
  - id: back_button_improvements
    content: Geri butonu iyileştirme (kaydetme uyarısı, WillPopScope)
    status: pending
---

# Journal Feature Expansion Plan - Revize (Mevcut Durum)

## Proje Tarama Sonuçları

### ✅ TAMAMLANMIŞ ÖZELLİKLER

#### 1. Video Desteği ✅
- **Dosya:** `lib/features/editor/widgets/video_block_widget.dart`
- **Durum:** Tam çalışıyor
- **Özellikler:**
  - Video oynatma widget'ı
  - Play/pause kontrolü
  - BlockType.video enum'da var
  - Editor'de video ekleme mantığı var
  - Video picker service var

#### 2. Metin Fontları ✅
- **Dosya:** `lib/features/editor/widgets/text_edit_dialog.dart`
- **Durum:** 12 font seçeneği mevcut
- **Fontlar:**
  - Roboto, Open Sans, Lato, Montserrat, Oswald, Raleway
  - Merriweather, Playfair Display
  - Source Code Pro
  - Pacifico, Caveat, Dancing Script
- **Özellikler:**
  - Font seçici UI
  - Renk seçici (20 renk)
  - Font boyutu slider
  - Hizalama seçenekleri

#### 3. Sayfa Önizleme ✅
- **Dosya:** `lib/features/preview/page_preview_screen.dart`
- **Durum:** Tam çalışıyor
- **Özellikler:**
  - Read-only sayfa görüntüleme
  - Tüm block türlerini render ediyor
  - Ink strokes gösteriyor

#### 4. Uygulama Renk Temaları (Backend) ✅
- **Dosya:** `lib/core/theme/app_theme.dart`
- **Durum:** 7 renk şeması tanımlı
- **Renkler:**
  - Blue, Green, Purple, Red, Orange, Teal, Pink
- **Provider:** `lib/core/theme/theme_provider.dart` var
- **Eksik:** UI'da renk seçici yok, main.dart'ta sabit purple kullanılıyor

#### 5. Resim Çerçeveleri ✅
- **Dosya:** `lib/features/editor/widgets/image_frame_widget.dart`
- **Durum:** 13 çerçeve stili mevcut!
- **Çerçeveler:**
  - polaroid, tape, shadow, simple_border, circle, rounded
  - stacked, film, sticker, gradient, vintage, layered, none
- **Not:** Hedef 10-12'ydi, 13 var! ✅

#### 6. Ses Kaydı (Temel) ✅
- **Dosya:** `lib/features/editor/services/audio_recorder_service.dart`
- **Durum:** Pause/resume metodları var
- **Eksik:** Duration tracking, gelişmiş UI dialog

#### 7. User Service ✅
- **Dosya:** `lib/core/auth/user_service.dart`
- **Durum:** Profil yönetimi, arkadaş sistemi var

---

### ❌ EKSİK/İYİLEŞTİRİLMESİ GEREKENLER

#### 1. Profil ve Ayarlar Birleştirme ⭐ ÖNCELİKLİ

**Mevcut Durum:**
- `lib/features/settings/settings_screen.dart` var
- Settings'te profil bölümü var ama ayrı
- Profil ekranı yok (ayrı bir profil ekranı yok)

**Yapılacaklar:**
- Profil ve ayarları tek ekranda birleştir
- Üstte profil bölümü (avatar, isim, email, display ID)
- Altta ayarlar bölümü:
  - Görünüm (tema modu + renk şeması seçici)
  - Veri Yönetimi (yedekleme, cache temizleme)
  - Hesap (çıkış)
  - Hakkında

**Dosyalar:**
- `lib/features/profile/profile_settings_screen.dart` (yeni - birleşik)
- `lib/features/settings/settings_screen.dart` (deprecated veya sil)
- `lib/features/library/library_screen.dart` (navigation güncelle)

---

#### 2. Renk Temaları Seçici UI ⭐ ÖNCELİKLİ

**Mevcut Durum:**
- `AppColorTheme` enum'da 7 renk var
- `ThemeProvider` var ve çalışıyor
- Settings'te sadece light/dark seçimi var
- Renk seçici UI yok
- `main.dart`'ta sabit `AppColorTheme.purple` kullanılıyor

**Yapılacaklar:**
- Settings'e renk şeması seçici ekle
- 7 renk için görsel kartlar (renk önizleme ile)
- Seçili rengi işaretle
- `main.dart`'ta `themeProvider.colorTheme` kullan

**Dosyalar:**
- `lib/features/settings/settings_screen.dart` veya birleşik profil ekranı
- `lib/main.dart` (renk temasını provider'dan al)

---

#### 3. Main.dart Tema Entegrasyonu

**Mevcut Durum:**
```dart
theme: AppTheme.getTheme(AppColorTheme.purple, Brightness.light),
darkTheme: AppTheme.getTheme(AppColorTheme.purple, Brightness.dark),
```

**Yapılacaklar:**
```dart
final themeSettings = ref.watch(themeProvider);
theme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.light),
darkTheme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.dark),
```

**Dosya:**
- `lib/main.dart`

---

#### 4. Resim Döndürme UI

**Mevcut Durum:**
- Döndürme mantığı var (`_onRotate` metodu)
- Toolbar'da döndürme butonu yok
- Sadece rotate handle ile döndürme var

**Yapılacaklar:**
- Seçili resim bloğu için toolbar'a döndürme butonu ekle
- 90° artışlarla döndürme (veya slider)
- Döndürme açısını göster

**Dosyalar:**
- `lib/features/editor/editor_screen.dart` (toolbar güncelleme)

---

#### 5. Ses Kaydı UI İyileştirme

**Mevcut Durum:**
- Temel kayıt var
- Pause/resume metodları var
- Duration tracking yok
- Basit dialog var

**Yapılacaklar:**
- Duration tracking (gerçek zamanlı süre gösterimi)
- Gelişmiş kayıt dialog'u:
  - Timer gösterimi
  - Waveform görselleştirme (basit)
  - Pause/resume butonları
  - Kayıt sırasında animasyon
- Daha iyi hata yönetimi

**Dosyalar:**
- `lib/features/editor/widgets/audio_recording_dialog.dart` (yeni)
- `lib/features/editor/editor_screen.dart` (ses kayıt UI güncelleme)
- `lib/features/editor/services/audio_recorder_service.dart` (duration tracking ekle)

---

#### 6. Geri Butonu İyileştirme

**Mevcut Durum:**
- Editor'de geri butonu var
- `_isDirty` state var
- Kaydetme uyarısı yok

**Yapılacaklar:**
- `WillPopScope` ekle
- Kaydedilmemiş değişiklikler için uyarı dialog'u
- "Kaydet ve Çık", "Çık", "İptal" seçenekleri

**Dosyalar:**
- `lib/features/editor/editor_screen.dart`

---

## Uygulama Öncelik Sırası

### Faz 1: Kritik İyileştirmeler (Hemen)
1. ✅ **Profil ve Ayarlar Birleştirme** - Tek ekran, daha iyi UX
2. ✅ **Renk Temaları Seçici UI** - Kullanıcı renk seçebilsin
3. ✅ **Main.dart Tema Entegrasyonu** - Seçilen renk uygulanmalı

### Faz 2: UX İyileştirmeleri
4. ✅ **Resim Döndürme UI** - Daha kolay kullanım
5. ✅ **Ses Kaydı UI İyileştirme** - Daha profesyonel görünüm
6. ✅ **Geri Butonu İyileştirme** - Veri kaybını önle

---

## Teknik Notlar

### Mevcut Mimari
- Riverpod state management ✅
- SharedPreferences tema tercihleri için ✅
- Firebase Auth + Firestore ✅
- Offline-first mimari ✅

### Yeni Dosyalar Oluşturulacak
- `lib/features/profile/profile_settings_screen.dart` (birleşik profil+ayarlar)

### Güncellenecek Dosyalar
- `lib/main.dart` (tema entegrasyonu)
- `lib/features/editor/editor_screen.dart` (döndürme UI, ses kayıt UI, geri butonu)
- `lib/features/library/library_screen.dart` (navigation - profil ekranına)

### Deprecated/Silinecek
- `lib/features/settings/settings_screen.dart` (birleşik ekrana taşınacak)

---

## Test Edilmesi Gerekenler

- Renk teması değişikliği anlık uygulanıyor mu?
- Profil+ayarlar ekranı tüm özellikleri içeriyor mu?
- Ses kaydı duration tracking doğru çalışıyor mu?
- Resim döndürme UI kullanıcı dostu mu?
- Geri butonu uyarısı doğru çalışıyor mu?
