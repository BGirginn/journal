# Journal Feature Expansion Plan - Detaylı Implementasyon Rehberi
---
name: Journal Feature Expansion Plan - Final (Birleşik)
overview: "Tüm özellikler birleştirilmiş, mevcut durum analizi yapılmış, eksikler ve yeni özellikler belirlenmiş. Optimizasyon ve iyileştirmeler dahil."
todos:
  # Faz 1: Kritik İyileştirmeler
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
  
  # Faz 2: Collaboration & Sharing
  - id: team_system
    content: Ekip sistemi - grup journal'ları için ekip yönetimi
    status: pending
  - id: invite_system
    content: Davet sistemi - journal'lara kullanıcı davet etme
    status: pending
  - id: share_system
    content: Paylaş sistemi - journal'ları paylaşma ve erişim yönetimi
    status: pending
  - id: link_system
    content: Link sistemi - deep linking ve paylaşım linkleri
    status: pending
  
  # Faz 3: Stickers & UX
  - id: sticker_creation
    content: Sticker oluşturma - kullanıcıların kendi sticker'larını oluşturması
    status: pending
  - id: journal_cover_preview
    content: Journal kapak önizlemesi iyileştirme - daha iyi görsel gösterim
    status: pending
  - id: drawer_improvements
    content: Drawer iyileştirmeleri - daha iyi UX, animasyonlar
    status: pending
  - id: ux_analysis
    content: UX geliştirmesi analizi - kullanıcı akışları, performans, erişilebilirlik
    status: pending
---

# Journal Feature Expansion Plan - Final (Birleşik)

## Genel Bakış

Bu plan, mevcut journal uygulamasının **tam kapsamlı geliştirme planıdır**. Mevcut özelliklerin iyileştirilmesi, eksiklerin tamamlanması ve yeni özelliklerin eklenmesini kapsar.

---

## ✅ TAMAMLANMIŞ ÖZELLİKLER (Mevcut Durum)

### 1. Temel Özellikler ✅
- ✅ Video desteği (video_block_widget.dart)
- ✅ Metin fontları (12 font seçeneği)
- ✅ Sayfa önizleme (page_preview_screen.dart)
- ✅ Resim çerçeveleri (13 çerçeve stili)
- ✅ Ses kaydı (temel - pause/resume var)
- ✅ User Service (profil, arkadaş sistemi)
- ✅ Drawer navigation (app_drawer.dart - Anasayfa, Ayarlar, Arkadaşlar, Journallar)
- ✅ Arkadaş ekleme (ID ile arama ve ekleme)
- ✅ Kullanıcı ID sistemi (displayId - J-XXXX formatı)
- ✅ Sticker picker (emoji, decorative, shape)

### 2. Backend & Altyapı ✅
- ✅ Backend optimizasyon (küçük sistem için tamamlandı)
- ✅ Firebase Auth + Firestore
- ✅ Sync service
- ✅ Offline-first mimari

### 3. UI Bileşenleri ✅
- ✅ Journal kapak tasarımları (theme sistemi)
- ✅ Journal preview card (kapak önizlemesi var)

---

## ❌ EKSİK/İYİLEŞTİRİLMESİ GEREKENLER

### FAZ 1: Kritik İyileştirmeler (Öncelikli)

#### 1. Profil ve Ayarlar Birleştirme ⭐

**Mevcut Durum:**
- Settings screen var ama profil ayrı
- Drawer'da ayrı menü öğeleri var

**Yapılacaklar:**
- Profil ve ayarları tek ekranda birleştir
- Üstte profil bölümü:
  - Avatar (Firebase'den veya default)
  - Kullanıcı adı ve email
  - Display ID (kopyalama butonu ile)
  - Avatar değiştirme (opsiyonel)
- Altta ayarlar bölümü:
  - **Görünüm:** Tema modu (light/dark/system) + Renk şeması seçici
  - **Veri Yönetimi:** Yedekleme, cache temizleme, veri kullanımı
  - **Hesap:** Çıkış butonu
  - **Hakkında:** Versiyon, lisans

**Dosyalar:**
- `lib/features/profile/profile_settings_screen.dart` (yeni)
- `lib/features/settings/settings_screen.dart` (deprecated)
- `lib/features/library/library_screen.dart` (navigation güncelle)

---

#### 2. Renk Temaları Seçici UI ⭐

**Mevcut Durum:**
- AppColorTheme enum'da 7 renk var (Blue, Green, Purple, Red, Orange, Teal, Pink)
- ThemeProvider var
- Settings'te sadece light/dark seçimi var
- Main.dart'ta sabit purple kullanılıyor

**Yapılacaklar:**
- Profil+ayarlar ekranına renk şeması seçici ekle
- 7 renk için görsel kartlar (renk önizleme ile)
- Seçili rengi işaretle
- Main.dart'ta provider'dan renk al

**Dosyalar:**
- `lib/features/profile/profile_settings_screen.dart`
- `lib/main.dart` (tema entegrasyonu)

---

#### 3. Main.dart Tema Entegrasyonu

**Mevcut:**
```dart
theme: AppTheme.getTheme(AppColorTheme.purple, Brightness.light),
darkTheme: AppTheme.getTheme(AppColorTheme.purple, Brightness.dark),
```

**Yapılacak:**
```dart
final themeSettings = ref.watch(themeProvider);
theme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.light),
darkTheme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.dark),
```

**Dosya:**
- `lib/main.dart`

---

#### 4. Resim Döndürme UI

**Mevcut:**
- Döndürme mantığı var (`_onRotate`)
- Toolbar'da döndürme butonu yok

**Yapılacaklar:**
- Seçili resim bloğu için toolbar'a döndürme butonu
- 90° artışlarla döndürme (veya slider)
- Döndürme açısını görsel olarak göster

**Dosyalar:**
- `lib/features/editor/editor_screen.dart`

---

#### 5. Ses Kaydı UI İyileştirme

**Mevcut:**
- Temel kayıt var
- Pause/resume metodları var
- Duration tracking yok
- Basit dialog var

**Yapılacaklar:**
- Duration tracking (gerçek zamanlı timer)
- Gelişmiş kayıt dialog'u:
  - Timer gösterimi (MM:SS formatında)
  - Waveform görselleştirme (basit animasyon)
  - Pause/resume butonları (görsel geri bildirim ile)
  - Kayıt sırasında animasyon (pulse efekti)
  - İptal ve kaydet seçenekleri
- Daha iyi hata yönetimi ve kullanıcı mesajları

**Dosyalar:**
- `lib/features/editor/widgets/audio_recording_dialog.dart` (yeni)
- `lib/features/editor/editor_screen.dart` (ses kayıt UI güncelleme)
- `lib/features/editor/services/audio_recorder_service.dart` (duration tracking)

---

#### 6. Geri Butonu İyileştirme

**Mevcut:**
- Editor'de geri butonu var
- `_isDirty` state var
- Kaydetme uyarısı yok

**Yapılacaklar:**
- `WillPopScope` veya `PopScope` (Flutter 3.12+) ekle
- Kaydedilmemiş değişiklikler için uyarı dialog'u
- Seçenekler: "Kaydet ve Çık", "Çık (Kaydetme)", "İptal"
- Navigation stack yönetimi

**Dosyalar:**
- `lib/features/editor/editor_screen.dart`

---

### FAZ 2: Collaboration & Sharing Sistemi

#### 7. Ekip Sistemi (Team System)

**Mevcut Durum:**
- User service var (arkadaş sistemi)
- Journal'lar personal olarak çalışıyor
- Grup journal desteği yok

**Yapılacaklar:**
- **Journal Type Genişletme:**
  - Personal journal (mevcut)
  - Team/Group journal (yeni)
- **Ekip Yönetimi:**
  - Ekip oluşturma
  - Ekip üyelerini görüntüleme
  - Ekip üyesi ekleme/çıkarma
  - Ekip rollerini yönetme (owner, editor, viewer)
- **Firestore Yapısı:**
  ```
  teams/{teamId}
    - name
    - ownerId
    - members: [userId1, userId2, ...]
    - createdAt
  
  team_members/{id}
    - teamId
    - userId
    - role (owner/editor/viewer)
    - joinedAt
  ```

**Dosyalar:**
- `lib/core/models/team.dart` (yeni)
- `lib/core/models/journal.dart` (teamId field ekle)
- `lib/core/database/daos/team_dao.dart` (yeni)
- `lib/features/team/team_screen.dart` (yeni)
- `lib/features/team/team_management_screen.dart` (yeni)

---

#### 8. Davet Sistemi (Invite System)

**Mevcut Durum:**
- Arkadaş ekleme var (ID ile)
- Journal davet sistemi yok

**Yapılacaklar:**
- **Journal Davet:**
  - Journal sahibi kullanıcıları davet edebilir
  - Davet linki oluşturma
  - Davet kabul/reddetme
  - Davet durumu takibi (pending/accepted/rejected)
- **Ekip Davet:**
  - Ekip sahibi kullanıcıları ekibe davet edebilir
  - Toplu davet (arkadaş listesinden seçim)
- **Firestore Yapısı:**
  ```
  invites/{inviteId}
    - type (journal/team)
    - targetId (journalId/teamId)
    - inviterId
    - inviteeId
    - status (pending/accepted/rejected)
    - createdAt
    - expiresAt
  ```

**Dosyalar:**
- `lib/core/models/invite.dart` (yeni)
- `lib/core/database/daos/invite_dao.dart` (yeni)
- `lib/features/invite/invite_service.dart` (yeni)
- `lib/features/invite/invite_dialog.dart` (yeni)
- `lib/features/invite/invite_notification.dart` (yeni)

---

#### 9. Paylaş Sistemi (Share System)

**Mevcut Durum:**
- Journal paylaşımı yok

**Yapılacaklar:**
- **Journal Paylaşım:**
  - Journal'ı paylaş butonu
  - Paylaşım seviyeleri:
    - **Private:** Sadece sahip erişebilir
    - **Team:** Ekip üyeleri erişebilir
    - **Friends:** Arkadaşlar erişebilir
    - **Public Link:** Link ile herkes erişebilir (read-only)
  - Paylaşım ayarları yönetimi
- **Paylaşım Linki:**
  - Unique link oluşturma
  - Link expire süresi ayarlama
  - Link erişim logları (opsiyonel)

**Dosyalar:**
- `lib/core/models/share_settings.dart` (yeni)
- `lib/features/share/share_dialog.dart` (yeni)
- `lib/features/share/share_service.dart` (yeni)
- `lib/core/database/daos/share_dao.dart` (yeni)

---

#### 10. Link Sistemi (Deep Linking)

**Mevcut Durum:**
- Deep linking yok

**Yapılacaklar:**
- **Deep Link Desteği:**
  - Journal paylaşım linkleri (`journalapp://journal/{journalId}`)
  - Davet linkleri (`journalapp://invite/{inviteId}`)
  - Ekip linkleri (`journalapp://team/{teamId}`)
- **Link Yönetimi:**
  - Link oluşturma (Firebase Dynamic Links veya custom)
  - Link doğrulama
  - Link açma işleme
- **Firebase Dynamic Links Entegrasyonu:**
  - iOS ve Android deep link yapılandırması
  - Universal links (iOS) ve App Links (Android)

**Dosyalar:**
- `lib/core/deep_linking/deep_link_service.dart` (yeni)
- `lib/core/deep_linking/deep_link_handler.dart` (yeni)
- `lib/main.dart` (deep link initialization)
- `android/app/src/main/AndroidManifest.xml` (intent filters)
- `ios/Runner/Info.plist` (URL schemes)

---

### FAZ 3: Stickers & UX İyileştirmeleri

#### 11. Sticker Oluşturma

**Mevcut Durum:**
- Sticker picker var (BuiltInStickers)
- Sadece emoji, decorative, shape
- Kullanıcı sticker oluşturma yok

**Yapılacaklar:**
- **Sticker Oluşturma:**
  - Resimden sticker oluşturma (image picker)
  - Emoji'den sticker oluşturma
  - Çizimden sticker oluşturma (basit drawing tool)
  - Sticker kategorileri (kullanıcı kategorileri oluşturabilir)
- **Sticker Yönetimi:**
  - Kullanıcının sticker'larını görüntüleme
  - Sticker silme/düzenleme
  - Sticker paylaşımı (ekip/arkadaşlarla)
- **Firestore Yapısı:**
  ```
  user_stickers/{stickerId}
    - userId
    - name
    - category
    - imageUrl (Firebase Storage)
    - type (image/emoji/drawing)
    - createdAt
  ```

**Dosyalar:**
- `lib/core/models/user_sticker.dart` (yeni)
- `lib/features/stickers/sticker_creator_screen.dart` (yeni)
- `lib/features/stickers/sticker_manager_screen.dart` (yeni)
- `lib/features/editor/widgets/sticker_picker.dart` (genişletme - user stickers ekle)

---

#### 12. Journal Kapak Önizlemesi İyileştirme

**Mevcut Durum:**
- Journal preview card var
- Kapak önizlemesi var ama iyileştirilebilir

**Yapılacaklar:**
- **Kapak Önizlemesi:**
  - Daha büyük ve detaylı önizleme
  - Kapak tasarımı seçerken canlı önizleme
  - Kapak özelleştirme (renk, gradient, pattern)
  - Özel kapak yükleme (kullanıcı resmi)
- **Kapak Galerisi:**
  - Daha fazla kapak tasarımı
  - Kategorize edilmiş kapaklar
  - Premium kapaklar (gelecek için)

**Dosyalar:**
- `lib/features/library/widgets/journal_preview_card.dart` (iyileştirme)
- `lib/features/library/theme_picker_dialog.dart` (kapak önizleme iyileştirme)
- `lib/core/theme/journal_theme.dart` (yeni kapak stilleri)

---

#### 13. Drawer İyileştirmeleri

**Mevcut Durum:**
- Drawer var (app_drawer.dart)
- Temel navigation çalışıyor

**Yapılacaklar:**
- **UX İyileştirmeleri:**
  - Profil bilgisi drawer header'da (avatar, isim)
  - Animasyonlar (slide, fade)
  - Badge gösterimi (bildirim sayısı, yeni davetler)
  - Hızlı erişim butonları (yeni journal, arama)
- **Ek Menü Öğeleri:**
  - Bildirimler (davetler, paylaşımlar)
  - Yardım/Destek
  - Çıkış butonu (drawer footer'da)

**Dosyalar:**
- `lib/core/ui/app_drawer.dart` (iyileştirme)
- `lib/core/ui/drawer_header.dart` (yeni - profil gösterimi)

---

#### 14. UX Geliştirmesi Analizi

**Yapılacaklar:**
- **Kullanıcı Akışları Analizi:**
  - Onboarding akışı iyileştirme
  - Journal oluşturma akışı optimizasyonu
  - Editor kullanım kolaylığı
  - Paylaşım/davet akışı
- **Performans Analizi:**
  - Sayfa yükleme süreleri
  - Sync performansı
  - Render optimizasyonu
  - Memory kullanımı
- **Erişilebilirlik:**
  - Screen reader desteği
  - Renk kontrastı
  - Font boyutu ayarları
  - Klavye navigasyonu
- **Analytics Entegrasyonu:**
  - Firebase Analytics (opsiyonel)
  - Kullanıcı davranışı takibi
  - Hata raporlama (Crashlytics)

**Dosyalar:**
- `lib/core/analytics/analytics_service.dart` (yeni - opsiyonel)
- `lib/core/accessibility/accessibility_helper.dart` (yeni)
- UX analiz raporu (dokümantasyon)

---

## Uygulama Öncelik Sırası

### Faz 1: Kritik İyileştirmeler (1-2 Hafta)
1. ✅ Profil ve Ayarlar Birleştirme
2. ✅ Renk Temaları Seçici UI
3. ✅ Main.dart Tema Entegrasyonu
4. ✅ Resim Döndürme UI
5. ✅ Ses Kaydı UI İyileştirme
6. ✅ Geri Butonu İyileştirme

### Faz 2: Collaboration & Sharing (2-3 Hafta)
7. ✅ Ekip Sistemi
8. ✅ Davet Sistemi
9. ✅ Paylaş Sistemi
10. ✅ Link Sistemi

### Faz 3: Stickers & UX (1-2 Hafta)
11. ✅ Sticker Oluşturma
12. ✅ Journal Kapak Önizlemesi İyileştirme
13. ✅ Drawer İyileştirmeleri
14. ✅ UX Geliştirmesi Analizi

---

## Teknik Notlar

### Mevcut Mimari
- ✅ Riverpod state management
- ✅ SharedPreferences (tema tercihleri)
- ✅ Firebase Auth + Firestore + Storage
- ✅ Offline-first mimari
- ✅ Drift (SQLite) local database

### Yeni Bağımlılıklar (Gerekirse)
- `firebase_dynamic_links` (deep linking için)
- `url_launcher` (link açma için)
- `share_plus` (native paylaşım için - opsiyonel)

### Yeni Dosyalar Oluşturulacak
- `lib/features/profile/profile_settings_screen.dart`
- `lib/core/models/team.dart`
- `lib/core/models/invite.dart`
- `lib/core/models/share_settings.dart`
- `lib/core/models/user_sticker.dart`
- `lib/core/deep_linking/deep_link_service.dart`
- `lib/features/team/` (klasör)
- `lib/features/invite/` (klasör)
- `lib/features/share/` (klasör)
- `lib/features/stickers/` (klasör)

### Güncellenecek Dosyalar
- `lib/main.dart` (tema, deep linking)
- `lib/features/editor/editor_screen.dart` (döndürme, ses, geri butonu)
- `lib/features/library/library_screen.dart` (navigation)
- `lib/core/models/journal.dart` (teamId, shareSettings)
- `lib/core/ui/app_drawer.dart` (iyileştirmeler)

---

## Test Edilmesi Gerekenler

### Faz 1
- ✅ Renk teması değişikliği anlık uygulanıyor mu?
- ✅ Profil+ayarlar ekranı tüm özellikleri içeriyor mu?
- ✅ Ses kaydı duration tracking doğru çalışıyor mu?
- ✅ Resim döndürme UI kullanıcı dostu mu?
- ✅ Geri butonu uyarısı doğru çalışıyor mu?

### Faz 2
- ✅ Ekip oluşturma ve yönetimi çalışıyor mu?
- ✅ Davet sistemi doğru çalışıyor mu?
- ✅ Paylaşım linkleri oluşturuluyor ve açılıyor mu?
- ✅ Deep linking iOS ve Android'de çalışıyor mu?
- ✅ Sync çoklu kullanıcı senaryolarında çalışıyor mu?

### Faz 3
- ✅ Sticker oluşturma ve kullanımı çalışıyor mu?
- ✅ Kapak önizlemesi düzgün görüntüleniyor mu?
- ✅ Drawer animasyonları akıcı mı?
- ✅ UX analizi sonuçları uygulanıyor mu?

---

## Notlar

- Tüm yeni özellikler mevcut offline-first mimarisini koruyacak
- Firebase Security Rules güncellenecek (team, invite, share için)
- Tüm değişiklikler geriye dönük uyumlu olacak
- Migration planı hazırlanacak (database schema değişiklikleri için)

## Genel Bakış

Bu dokümantasyon, Journal uygulamasının tüm özelliklerinin **tam detaylı implementasyon planıdır**. Her özellik için:
- Ne olduğu (detaylı açıklama)
- Nasıl yapılacağı (adım adım implementasyon)
- Hangi yöntem/sistem/servisler kullanılacağı
- Veri modelleri (tam kod örnekleri)
- API tasarımları
- UI/UX detayları
- Teknik detaylar
- Test senaryoları

**Hiçbir belirsizlik kalmamalı - her karar mekanizması açıkça belirtilmiştir.**

---

## ✅ TAMAMLANMIŞ ÖZELLİKLER (Mevcut Durum Analizi)

### 1. Video Desteği ✅
**Dosya:** `lib/features/editor/widgets/video_block_widget.dart`
**Durum:** Tam çalışıyor
**Özellikler:**
- Video oynatma widget'ı (video_player paketi)
- Play/pause kontrolü
- BlockType.video enum'da var
- Editor'de video ekleme mantığı var
- Video picker service var (ImagePickerService içinde)

### 2. Metin Fontları ✅
**Dosya:** `lib/features/editor/widgets/text_edit_dialog.dart`
**Durum:** 12 font seçeneği mevcut
**Fontlar:** Roboto, Open Sans, Lato, Montserrat, Oswald, Raleway, Merriweather, Playfair Display, Source Code Pro, Pacifico, Caveat, Dancing Script
**Özellikler:** Font seçici UI, renk seçici (20 renk), font boyutu slider, hizalama seçenekleri

### 3. Sayfa Önizleme ✅
**Dosya:** `lib/features/preview/page_preview_screen.dart`
**Durum:** Tam çalışıyor, read-only görüntüleme

### 4. Resim Çerçeveleri ✅
**Dosya:** `lib/features/editor/widgets/image_frame_widget.dart`
**Durum:** 13 çerçeve stili mevcut (polaroid, tape, shadow, simple_border, circle, rounded, stacked, film, sticker, gradient, vintage, layered, none)

### 5. Ses Kaydı (Temel) ✅
**Dosya:** `lib/features/editor/services/audio_recorder_service.dart`
**Durum:** Pause/resume metodları var, duration tracking yok

### 6. User Service ✅
**Dosya:** `lib/core/auth/user_service.dart`
**Durum:** Profil yönetimi, arkadaş sistemi, displayId (J-XXXX formatı)

### 7. Drawer Navigation ✅
**Dosya:** `lib/core/ui/app_drawer.dart`
**Durum:** Anasayfa, Ayarlar, Arkadaşlar, Journallar menüleri var

---

## ❌ EKSİK/İYİLEŞTİRİLMESİ GEREKENLER - DETAYLI PLAN

---

## FAZ 1: Kritik İyileştirmeler

### 1. Profil ve Ayarlar Birleştirme ⭐

#### Ne Olduğu
Profil bilgileri ve uygulama ayarlarını tek bir ekranda birleştiren, kullanıcı dostu bir yönetim ekranı. Kullanıcı profil bilgilerini görüntüleyip düzenleyebilir, uygulama ayarlarını yönetebilir.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Yeni Ekran Oluşturma**
- `lib/features/profile/profile_settings_screen.dart` dosyası oluştur
- ConsumerStatefulWidget kullan (Riverpod state management için)
- Scaffold yapısı oluştur

**Adım 2: Profil Bölümü (Üst Kısım)**
- UserService'ten kullanıcı bilgilerini al (myProfileStream)
- Avatar widget'ı:
  - Firebase'den photoURL varsa NetworkImage kullan
  - Yoksa default avatar (Icon veya CircleAvatar)
  - Avatar'a tıklanınca image picker aç (opsiyonel - gelecek için)
- Kullanıcı bilgileri:
  - displayName (Text widget, büyük font)
  - email (Text widget, küçük font, gri renk)
  - displayId (Text widget + kopyalama butonu)
- Layout: Column içinde Stack (avatar için) + Column (bilgiler için)

**Adım 3: Ayarlar Bölümü (Alt Kısım)**
- ListView veya Column kullan
- Bölümler:
  1. **Görünüm Bölümü:**
     - ExpansionTile veya SectionHeader
     - Tema modu seçici (RadioListTile: System/Light/Dark)
     - Renk şeması seçici (ColorThemeSelector widget - ayrı widget)
  2. **Veri Yönetimi Bölümü:**
     - Yedekleme butonu (mevcut kod)
     - Cache temizleme butonu (yeni)
     - Veri kullanımı gösterimi (yeni - SharedPreferences + DB size)
  3. **Hesap Bölümü:**
     - Çıkış butonu (AuthService.signOut)
  4. **Hakkında Bölümü:**
     - Versiyon bilgisi (package_info_plus paketi)
     - Lisans bilgisi (dialog)

**Adım 4: Navigation Güncelleme**
- `lib/features/library/library_screen.dart` içinde
- SettingsScreen yerine ProfileSettingsScreen kullan
- Drawer'da "Ayarlar" yerine "Profil" veya "Profil ve Ayarlar" yaz

**Adım 5: Eski Settings Screen'i Deprecate Et**
- `lib/features/settings/settings_screen.dart` dosyasını sil veya deprecated olarak işaretle
- Tüm referansları ProfileSettingsScreen'e yönlendir

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (mevcut)
- `userServiceProvider` - kullanıcı bilgileri için
- `themeProvider` - tema ayarları için
- `authStateProvider` - auth durumu için

**Servisler:**
- `UserService` (mevcut) - profil bilgileri
- `AuthService` (mevcut) - çıkış işlemi
- `ThemeNotifier` (mevcut) - tema yönetimi
- `SharedPreferences` (mevcut) - ayar kalıcılığı

**Paketler:**
- `package_info_plus` (yeni eklenecek) - versiyon bilgisi için
- `image_picker` (mevcut) - avatar değiştirme için (gelecek)

**Firebase:**
- Firebase Auth - kullanıcı bilgileri
- Firestore - profil bilgileri (UserService üzerinden)

#### Veri Modelleri

**Mevcut Modeller (Kullanılacak):**
```dart
// lib/core/auth/user_service.dart içinde zaten var
class UserProfile {
  final String uid;
  final String displayId;
  final String displayName;
  final String? photoUrl;
  final List<String> friends;
}
```

**Yeni Model Gerekmez** - Mevcut UserProfile kullanılacak

#### API Tasarımları

**UserService API (Mevcut - Kullanılacak):**
```dart
// lib/core/auth/user_service.dart
Stream<UserProfile?> get myProfileStream; // Profil bilgilerini stream olarak al
Future<UserProfile?> ensureProfileExists(); // Profil yoksa oluştur
```

**ThemeProvider API (Mevcut - Kullanılacak):**
```dart
// lib/core/theme/theme_provider.dart
Future<void> setThemeMode(ThemeMode mode); // Tema modu değiştir
Future<void> setColorTheme(AppColorTheme colorTheme); // Renk teması değiştir
ThemeSettings get state; // Mevcut ayarları al
```

#### UI/UX Detayları

**Layout Yapısı:**
```
Scaffold
  AppBar (title: "Profil ve Ayarlar")
  Body:
    SingleChildScrollView
      Column
        // Profil Bölümü
        Container (profil kartı)
          Stack
            CircleAvatar (büyük, üstte)
            Column (bilgiler, altta)
              Text (isim)
              Text (email)
              Row (displayId + kopyala butonu)
        
        Divider
        
        // Ayarlar Bölümü
        ExpansionTile ("Görünüm")
          RadioListTile (Sistem Teması)
          RadioListTile (Açık Tema)
          RadioListTile (Koyu Tema)
          ColorThemeSelector (renk şeması seçici)
        
        ExpansionTile ("Veri Yönetimi")
          ListTile (Yedekle)
          ListTile (Cache Temizle)
          ListTile (Veri Kullanımı)
        
        ExpansionTile ("Hesap")
          ListTile (Çıkış Yap, kırmızı renk)
        
        ExpansionTile ("Hakkında")
          ListTile (Versiyon)
          ListTile (Lisans)
```

**Renkler ve Stil:**
- Profil kartı: Gradient background (primary color)
- Avatar: 80x80 boyutunda, border: 4px white
- Ayarlar bölümleri: ExpansionTile veya SectionHeader
- Çıkış butonu: Kırmızı renk (Colors.red)

**Animasyonlar:**
- ExpansionTile açılma/kapanma animasyonu (built-in)
- Avatar değişikliğinde fade animasyonu

#### Teknik Detaylar

**Dosya Yapısı:**
```
lib/features/profile/
  profile_settings_screen.dart (ana ekran)
  widgets/
    profile_header_widget.dart (profil üst kısmı - opsiyonel)
    color_theme_selector.dart (renk seçici widget)
```

**Provider Kullanımı:**
```dart
final userProfileAsync = ref.watch(
  StreamProvider((ref) => ref.read(userServiceProvider).myProfileStream)
);

final themeSettings = ref.watch(themeProvider);
final themeNotifier = ref.read(themeProvider.notifier);
```

**Hata Yönetimi:**
- UserProfile null ise: "Profil yükleniyor..." göster
- Stream error ise: Hata mesajı göster
- Çıkış hatası: SnackBar ile hata göster

**Offline Desteği:**
- Profil bilgileri local'de cache'lenmiş olabilir (UserService)
- Tema ayarları SharedPreferences'ta (offline çalışır)

#### Test Senaryoları

1. **Profil Bilgileri Görüntüleme:**
   - Kullanıcı giriş yapmış, profil bilgileri görüntüleniyor mu?
   - Avatar varsa gösteriliyor mu?
   - Display ID kopyalama çalışıyor mu?

2. **Tema Değiştirme:**
   - Tema modu değişikliği anlık uygulanıyor mu?
   - Renk teması değişikliği anlık uygulanıyor mu?
   - Ayarlar SharedPreferences'a kaydediliyor mu?

3. **Veri Yönetimi:**
   - Yedekleme çalışıyor mu?
   - Cache temizleme çalışıyor mu?
   - Veri kullanımı doğru gösteriliyor mu?

4. **Çıkış:**
   - Çıkış butonu çalışıyor mu?
   - Login ekranına yönlendiriliyor mu?

---

### 2. Renk Temaları Seçici UI ⭐

#### Ne Olduğu
Kullanıcının uygulamanın renk şemasını seçebileceği görsel bir seçici. 7 farklı renk şeması (Blue, Green, Purple, Red, Orange, Teal, Pink) için kartlar gösterilir, seçili renk işaretlenir ve anlık olarak uygulanır.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: ColorThemeSelector Widget Oluştur**
- `lib/features/profile/widgets/color_theme_selector.dart` dosyası oluştur
- StatelessWidget veya ConsumerWidget (themeProvider için)
- GridView veya Wrap kullan (7 renk kartı için)

**Adım 2: Renk Kartları Tasarımı**
- Her renk için bir kart widget'ı
- Kart içeriği:
  - Renk önizlemesi (Container, gradient veya solid color)
  - Renk adı (Text)
  - Seçili işareti (Check icon veya border)
- Kart boyutu: 80x100 (width x height)
- Grid: 3 sütun (2 satır + 1)

**Adım 3: Seçim Mantığı**
- ThemeProvider'dan mevcut renk temasını al
- Kart'a tıklanınca `themeNotifier.setColorTheme()` çağır
- Seçili kartı görsel olarak işaretle (border, check icon)

**Adım 4: Main.dart Entegrasyonu**
- `lib/main.dart` dosyasını güncelle
- `AppColorTheme.purple` yerine `themeSettings.colorTheme` kullan
- MaterialApp'in theme ve darkTheme parametrelerini güncelle

**Adım 5: ProfileSettingsScreen'e Ekle**
- Görünüm bölümüne ColorThemeSelector widget'ını ekle
- ExpansionTile içinde veya direkt olarak

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod ThemeProvider (mevcut)
- `themeProvider` - mevcut tema ayarlarını al
- `themeProvider.notifier` - tema değiştirme

**Servisler:**
- `ThemeNotifier` (mevcut) - tema state yönetimi
- `SharedPreferences` (mevcut) - tema tercihi kalıcılığı

**Paketler:**
- Hiçbir yeni paket gerekmez (mevcut paketler yeterli)

#### Veri Modelleri

**Mevcut Model (Kullanılacak):**
```dart
// lib/core/theme/app_theme.dart
enum AppColorTheme {
  blue('Blue', Colors.blue),
  green('Green', Colors.green),
  purple('Purple', Colors.deepPurple),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  teal('Teal', Colors.teal),
  pink('Pink', Colors.pink);
  
  final String label;
  final Color color;
}

// lib/core/theme/theme_provider.dart
class ThemeSettings {
  final ThemeMode mode;
  final AppColorTheme colorTheme;
}
```

#### API Tasarımları

**ThemeNotifier API (Mevcut - Kullanılacak):**
```dart
// lib/core/theme/theme_provider.dart
Future<void> setColorTheme(AppColorTheme colorTheme);
AppColorTheme get colorTheme; // state.colorTheme
```

**AppTheme API (Mevcut - Kullanılacak):**
```dart
// lib/core/theme/app_theme.dart
static ThemeData getTheme(AppColorTheme colorTheme, Brightness brightness);
```

#### UI/UX Detayları

**Layout Yapısı:**
```
ColorThemeSelector Widget
  Column
    Text ("Renk Şeması", başlık)
    SizedBox (spacing)
    Wrap veya GridView
      _ColorThemeCard (Blue)
      _ColorThemeCard (Green)
      _ColorThemeCard (Purple)
      _ColorThemeCard (Red)
      _ColorThemeCard (Orange)
      _ColorThemeCard (Teal)
      _ColorThemeCard (Pink)
```

**Renk Kartı Tasarımı:**
```
_ColorThemeCard
  GestureDetector (onTap)
    Container
      decoration: BoxDecoration
        color: renk (veya gradient)
        borderRadius: 12
        border: seçili ise 3px primary, değilse 1px grey
      child: Column
        Expanded (renk önizleme alanı)
        Text (renk adı)
        if (seçili) Icon (check_circle)
```

**Renk Önizlemesi:**
- Her renk için ColorScheme.fromSeed kullanarak önizleme
- Light ve dark mod önizlemesi (2 küçük kare yan yana)
- Veya gradient gösterimi

**Animasyonlar:**
- Kart seçildiğinde scale animasyonu (1.0 -> 1.05 -> 1.0)
- Check icon fade-in animasyonu

#### Teknik Detaylar

**Dosya Yapısı:**
```
lib/features/profile/widgets/
  color_theme_selector.dart (ana widget)
```

**Kod Yapısı:**
```dart
class ColorThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Renk Şeması', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColorTheme.values.map((theme) {
            return _ColorThemeCard(
              theme: theme,
              isSelected: theme == themeSettings.colorTheme,
              onTap: () => notifier.setColorTheme(theme),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

**Main.dart Güncelleme:**
```dart
// lib/main.dart - JournalApp widget içinde
@override
Widget build(BuildContext context, WidgetRef ref) {
  final themeSettings = ref.watch(themeProvider);
  
  return MaterialApp(
    theme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.light),
    darkTheme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.dark),
    themeMode: themeSettings.mode,
    // ...
  );
}
```

**Performans:**
- Widget rebuild'i minimize et (ConsumerWidget kullan)
- Renk kartları const olabilir (değişmeyen kısımlar)

#### Test Senaryoları

1. **Renk Seçimi:**
   - Renk kartına tıklanınca tema değişiyor mu?
   - Seçili renk görsel olarak işaretleniyor mu?
   - Uygulama genelinde renk değişikliği uygulanıyor mu?

2. **Kalıcılık:**
   - Uygulama kapatılıp açılınca seçili renk korunuyor mu?
   - SharedPreferences'a kaydediliyor mu?

3. **Light/Dark Mod:**
   - Her renk şeması hem light hem dark modda çalışıyor mu?

---

### 3. Main.dart Tema Entegrasyonu

#### Ne Olduğu
Main.dart dosyasında sabit kodlanmış `AppColorTheme.purple` değerini kaldırıp, ThemeProvider'dan dinamik olarak renk temasını almak.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Mevcut Kodu İncele**
- `lib/main.dart` dosyasını aç
- `JournalApp` widget'ını bul
- `AppTheme.getTheme(AppColorTheme.purple, ...)` satırlarını bul

**Adım 2: Provider'dan Tema Al**
- `ref.watch(themeProvider)` ile tema ayarlarını al
- `themeSettings.colorTheme` kullan
- `themeSettings.mode` kullan (zaten kullanılıyor)

**Adım 3: MaterialApp Güncelle**
- `theme` parametresini güncelle
- `darkTheme` parametresini güncelle
- `themeMode` zaten doğru (güncelleme gerekmez)

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod `themeProvider` (mevcut)

**Servisler:**
- `ThemeNotifier` (mevcut)

#### Veri Modelleri

**Mevcut Model (Kullanılacak):**
```dart
// lib/core/theme/theme_provider.dart
class ThemeSettings {
  final ThemeMode mode;
  final AppColorTheme colorTheme;
}
```

#### API Tasarımları

**ThemeProvider API (Mevcut - Kullanılacak):**
```dart
final themeSettings = ref.watch(themeProvider);
// themeSettings.colorTheme - renk teması
// themeSettings.mode - tema modu (light/dark/system)
```

#### UI/UX Detayları

**Değişiklik:**
- Sadece backend değişikliği, UI değişmez
- Kullanıcı renk seçtiğinde anlık olarak uygulanır

#### Teknik Detaylar

**Kod Değişikliği:**
```dart
// ÖNCE (lib/main.dart)
class JournalApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    
    return MaterialApp(
      theme: AppTheme.getTheme(AppColorTheme.purple, Brightness.light),
      darkTheme: AppTheme.getTheme(AppColorTheme.purple, Brightness.dark),
      themeMode: themeSettings.mode,
      // ...
    );
  }
}

// SONRA (lib/main.dart)
class JournalApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    
    return MaterialApp(
      theme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.light),
      darkTheme: AppTheme.getTheme(themeSettings.colorTheme, Brightness.dark),
      themeMode: themeSettings.mode,
      // ...
    );
  }
}
```

**Hot Reload:**
- Değişiklik hot reload ile test edilebilir
- Provider değiştiğinde MaterialApp rebuild olur

#### Test Senaryoları

1. **Tema Değişikliği:**
   - Renk teması değiştirildiğinde uygulama genelinde uygulanıyor mu?
   - Light ve dark mod her iki durumda da çalışıyor mu?

2. **Performans:**
   - Tema değişikliği sırasında performans sorunu var mı?
   - Rebuild gereksiz yere tetikleniyor mu?

---

### 4. Resim Döndürme UI

#### Ne Olduğu
Editor'de seçili bir resim bloğu için toolbar'a döndürme butonu eklemek. Kullanıcı resmi 90° artışlarla veya slider ile döndürebilir.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Toolbar'a Döndürme Butonu Ekle**
- `lib/features/editor/editor_screen.dart` dosyasını aç
- `_buildToolbar` metodunu bul
- Seçili block image ise döndürme butonu göster
- Buton: `Icons.rotate_right` icon

**Adım 2: Döndürme Dialog'u Oluştur**
- Döndürme butonuna tıklanınca dialog aç
- Dialog içeriği:
  - Mevcut döndürme açısı gösterimi
  - 90° artış butonları (0°, 90°, 180°, 270°)
  - Veya slider (0-360°)
  - Önizleme (resim döndürülmüş halde göster)

**Adım 3: Döndürme Uygulama**
- Seçili block'u bul
- Rotation değerini güncelle
- Block'u update et (blockDao.updateBlock)
- State'i güncelle (_isDirty = true)

**Adım 4: Görsel Geri Bildirim**
- Döndürme sırasında block'u gerçek zamanlı döndür (Transform.rotate)
- Dialog'da önizleme göster

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Editor screen'in local state'i (_selectedBlockId, _blocks)
- BlockDao (mevcut) - block güncelleme

**Servisler:**
- `BlockDao` (mevcut) - block update
- `FirestoreService` (mevcut) - sync için

**Paketler:**
- Hiçbir yeni paket gerekmez

#### Veri Modelleri

**Mevcut Model (Kullanılacak):**
```dart
// lib/core/models/block.dart
class Block {
  final double rotation; // degrees cinsinden
  // ...
  Block copyWith({double? rotation, ...});
}
```

#### API Tasarımları

**BlockDao API (Mevcut - Kullanılacak):**
```dart
// lib/core/database/daos/block_dao.dart
Future<void> updateBlock(Block block);
```

**Editor Screen Metodları (Yeni Eklenecek):**
```dart
void _rotateImageBlock(double angle); // Döndürme uygula
void _showRotateDialog(); // Döndürme dialog'u göster
```

#### UI/UX Detayları

**Toolbar Butonu:**
```
if (_selectedBlockId != null && _getSelectedBlockType() == BlockType.image)
  _ToolBtn(
    Icons.rotate_right,
    'Döndür',
    false,
    _showRotateDialog,
  )
```

**Döndürme Dialog:**
```
AlertDialog
  title: "Resmi Döndür"
  content: Column
    Text ("Mevcut açı: ${block.rotation}°")
    SizedBox
    // Önizleme
    Container (resim önizlemesi, döndürülmüş)
    SizedBox
    // Hızlı seçim butonları
    Row
      ElevatedButton ("0°", onTap: () => _rotateTo(0))
      ElevatedButton ("90°", onTap: () => _rotateTo(90))
      ElevatedButton ("180°", onTap: () => _rotateTo(180))
      ElevatedButton ("270°", onTap: () => _rotateTo(270))
    // Veya slider
    Slider (0-360, value: block.rotation, onChanged: _rotateTo)
  actions
    TextButton ("İptal")
    FilledButton ("Uygula")
```

**Görsel Geri Bildirim:**
- Dialog'da resim döndürülmüş halde gösterilir
- Slider değiştiğinde önizleme anlık güncellenir

#### Teknik Detaylar

**Dosya Yapısı:**
```
lib/features/editor/
  editor_screen.dart (güncelleme)
  widgets/
    image_rotate_dialog.dart (yeni - opsiyonel, dialog ayrı dosyaya alınabilir)
```

**Kod Yapısı:**
```dart
// lib/features/editor/editor_screen.dart içinde
void _showRotateDialog() {
  if (_selectedBlockId == null) return;
  
  final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
  double newRotation = block.rotation;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Resmi Döndür'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mevcut açı: ${newRotation.toInt()}°'),
              const SizedBox(height: 16),
              // Önizleme
              Container(
                width: 200,
                height: 200,
                child: Transform.rotate(
                  angle: newRotation * pi / 180,
                  child: _buildBlockContent(block), // Resim widget'ı
                ),
              ),
              const SizedBox(height: 16),
              // Hızlı seçim
              Wrap(
                spacing: 8,
                children: [0, 90, 180, 270].map((angle) {
                  return ElevatedButton(
                    onPressed: () {
                      setDialogState(() => newRotation = angle.toDouble());
                    },
                    child: Text('${angle}°'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Slider
              Slider(
                value: newRotation,
                min: 0,
                max: 360,
                divisions: 360,
                label: '${newRotation.toInt()}°',
                onChanged: (value) {
                  setDialogState(() => newRotation = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                _rotateImageBlock(newRotation);
                Navigator.pop(context);
              },
              child: const Text('Uygula'),
            ),
          ],
        );
      },
    ),
  );
}

void _rotateImageBlock(double angle) {
  if (_selectedBlockId == null) return;
  
  final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
  if (index == -1) return;
  
  setState(() {
    _blocks[index] = _blocks[index].copyWith(rotation: angle);
    _isDirty = true;
  });
  
  // DB'ye kaydet (async)
  ref.read(blockDaoProvider).updateBlock(_blocks[index]);
}
```

**Performans:**
- Dialog'da önizleme için küçük resim kullan (cache edilmiş thumbnail)
- Slider değişikliğinde sadece dialog state'i güncelle (setDialogState)
- Uygula butonuna basıldığında gerçek block'u güncelle

**Sync:**
- Block güncellendiğinde FirestoreService'e sync et
- Mevcut sync mekanizması kullanılır

#### Test Senaryoları

1. **Döndürme Butonu:**
   - Resim bloğu seçildiğinde toolbar'da döndürme butonu görünüyor mu?
   - Diğer block türlerinde görünmüyor mu?

2. **Döndürme İşlemi:**
   - 90° butonları çalışıyor mu?
   - Slider çalışıyor mu?
   - Önizleme doğru gösteriliyor mu?
   - Uygula butonuna basınca block döndürülüyor mu?

3. **Kalıcılık:**
   - Döndürme kaydediliyor mu?
   - Sayfa yenilendiğinde döndürme korunuyor mu?
   - Sync çalışıyor mu?

---

### 5. Ses Kaydı UI İyileştirme

#### Ne Olduğu
Ses kaydı sırasında kullanıcıya daha iyi geri bildirim sağlayan, duration tracking, waveform görselleştirme, pause/resume kontrolleri içeren gelişmiş bir kayıt dialog'u.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: AudioRecorderService'e Duration Tracking Ekle**
- `lib/features/editor/services/audio_recorder_service.dart` dosyasını güncelle
- Timer ekle (kayıt süresini takip etmek için)
- Stream ekle (duration'ı gerçek zamanlı yayınlamak için)
- `Stream<Duration> get durationStream` metodu ekle

**Adım 2: Gelişmiş Kayıt Dialog'u Oluştur**
- `lib/features/editor/widgets/audio_recording_dialog.dart` dosyası oluştur
- StatefulWidget kullan (duration state için)
- Dialog içeriği:
  - Timer gösterimi (MM:SS formatı)
  - Waveform görselleştirme (basit animasyon)
  - Pause/resume butonları
  - Kayıt animasyonu (pulse efekti)
  - İptal ve kaydet butonları

**Adım 3: Waveform Görselleştirme**
- Basit waveform animasyonu (rastgele yükseklikler)
- CustomPaint veya Container'lar kullan
- Animasyon: kayıt sırasında sürekli güncellenen çubuklar

**Adım 4: Editor Screen'de Kullan**
- `_recordAudio` metodunu güncelle
- Eski basit dialog yerine yeni AudioRecordingDialog kullan
- Dialog'dan dönen path'i al ve block oluştur

**Adım 5: Hata Yönetimi**
- İzin kontrolü (daha detaylı mesajlar)
- Kayıt hatalarını yakala ve göster
- Kullanıcıya anlaşılır hata mesajları

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- StatefulWidget local state (duration için)
- StreamBuilder (duration stream için)

**Servisler:**
- `AudioRecorderService` (mevcut - güncellenecek)
- `record` paketi (mevcut)

**Paketler:**
- `record` (mevcut) - ses kaydı
- `audioplayers` (mevcut) - oynatma için
- `permission_handler` (mevcut) - izin kontrolü

**Animasyonlar:**
- `flutter_animate` (mevcut) veya `AnimationController`

#### Veri Modelleri

**Mevcut Model (Kullanılacak):**
```dart
// lib/core/models/block.dart
class AudioBlockPayload {
  final String? path;
  final int? durationMs;
  // ...
}
```

**Yeni Model Gerekmez**

#### API Tasarımları

**AudioRecorderService API (Güncellenecek):**
```dart
// lib/features/editor/services/audio_recorder_service.dart
class AudioRecorderService {
  // Mevcut metodlar
  Future<String> startRecording();
  Future<String?> stopRecording();
  Future<void> pause();
  Future<void> resume();
  Future<bool> isRecording();
  Future<bool> isPaused();
  
  // YENİ EKLENECEK
  Stream<Duration> get durationStream; // Gerçek zamanlı süre
  Duration get currentDuration; // Mevcut süre
}
```

**AudioRecordingDialog API (Yeni):**
```dart
// lib/features/editor/widgets/audio_recording_dialog.dart
class AudioRecordingDialog extends StatefulWidget {
  final AudioRecorderService recorder;
  
  // Dialog açıldığında kayıt başlatılır
  // Kullanıcı kaydet/iptal seçeneği ile kapatır
  // Dönen değer: String? (path veya null)
}
```

#### UI/UX Detayları

**Dialog Layout:**
```
AlertDialog
  title: "Ses Kaydediliyor"
  content: Column
    // Timer
    Text ("00:45", büyük font, kalın)
    
    SizedBox
    
    // Waveform (animasyonlu)
    Container (yükseklik: 100)
      CustomPaint veya Row (çubuklar)
        // 20-30 adet dikey çubuk
        // Her çubuk rastgele yükseklikte (animasyonlu)
        // Kayıt sırasında sürekli güncellenir
    
    SizedBox
    
    // Kontrol butonları
    Row
      IconButton (pause/resume icon)
      SizedBox
      IconButton (stop/kaydet icon, kırmızı)
      SizedBox
      IconButton (iptal icon)
  
  actions: [] // Dialog içinde butonlar var
```

**Waveform Görselleştirme:**
- 20-30 adet dikey çubuk (Container veya CustomPaint)
- Her çubuk: width 4-6px, height rastgele (20-80px)
- Animasyon: her 100-200ms'de yükseklikler güncellenir
- Renk: primary color, opacity animasyonlu

**Timer Formatı:**
- MM:SS formatı (örn: 01:23)
- 60 saniyeden sonra MM:SS (örn: 02:45)
- Font: monospace (rakamlar hizalı)

**Animasyonlar:**
- Pulse efekti: kayıt sırasında mikrofon ikonu pulse eder
- Waveform: çubuklar sürekli animasyonlu
- Timer: sayılar güncellenirken fade animasyonu

#### Teknik Detaylar

**Dosya Yapısı:**
```
lib/features/editor/
  services/
    audio_recorder_service.dart (güncelleme)
  widgets/
    audio_recording_dialog.dart (yeni)
```

**AudioRecorderService Güncelleme:**
```dart
// lib/features/editor/services/audio_recorder_service.dart
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;
  final _durationController = StreamController<Duration>.broadcast();
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;
  
  Stream<Duration> get durationStream => _durationController.stream;
  Duration get currentDuration => _currentDuration;
  
  Future<String> startRecording() async {
    if (!await hasPermission()) {
      throw Exception('Mikrofon izni yok');
    }
    
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'audio_${const Uuid().v4()}.m4a';
    final path = '${dir.path}/$fileName';
    
    await _recorder.start(const RecordConfig(), path: path);
    
    // Timer başlat
    _recordingStartTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null) {
        _currentDuration = DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
        _durationController.add(_currentDuration);
      }
    });
    
    return path;
  }
  
  Future<void> pause() async {
    await _recorder.pause();
    _pauseStartTime = DateTime.now();
    _durationTimer?.cancel();
  }
  
  Future<void> resume() async {
    await _recorder.resume();
    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }
    _recordingStartTime = DateTime.now() - _currentDuration;
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null) {
        _currentDuration = DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
        _durationController.add(_currentDuration);
      }
    });
  }
  
  Future<String?> stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _recordingStartTime = null;
    _pauseStartTime = null;
    _currentDuration = Duration.zero;
    _pausedDuration = Duration.zero;
    return await _recorder.stop();
  }
  
  @override
  void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }
}
```

**AudioRecordingDialog:**
```dart
// lib/features/editor/widgets/audio_recording_dialog.dart
class AudioRecordingDialog extends StatefulWidget {
  final AudioRecorderService recorder;
  
  const AudioRecordingDialog({required this.recorder});
  
  @override
  State<AudioRecordingDialog> createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<AudioRecordingDialog>
    with SingleTickerProviderStateMixin {
  bool _isPaused = false;
  late AnimationController _pulseController;
  late List<double> _waveformHeights;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Waveform için rastgele yükseklikler
    _waveformHeights = List.generate(25, (_) => Random().nextDouble() * 60 + 20);
    _updateWaveform();
  }
  
  void _updateWaveform() {
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _waveformHeights = List.generate(25, (_) => Random().nextDouble() * 60 + 20);
      });
    });
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ses Kaydediliyor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          StreamBuilder<Duration>(
            stream: widget.recorder.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return Text(
                _formatDuration(duration),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Waveform
          Container(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _waveformHeights.asMap().entries.map((entry) {
                return Container(
                  width: 4,
                  height: entry.value,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Kontrol butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause/Resume
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                iconSize: 32,
                onPressed: () async {
                  if (_isPaused) {
                    await widget.recorder.resume();
                    setState(() => _isPaused = false);
                  } else {
                    await widget.recorder.pause();
                    setState(() => _isPaused = true);
                  }
                },
              ),
              const SizedBox(width: 16),
              // Stop/Kaydet
              IconButton(
                icon: const Icon(Icons.stop),
                iconSize: 32,
                color: Colors.red,
                onPressed: () async {
                  final path = await widget.recorder.stopRecording();
                  if (mounted) Navigator.pop(context, path);
                },
              ),
              const SizedBox(width: 16),
              // İptal
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 32,
                onPressed: () {
                  widget.recorder.stopRecording();
                  if (mounted) Navigator.pop(context, null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
```

**Editor Screen Güncelleme:**
```dart
// lib/features/editor/editor_screen.dart içinde
void _recordAudio() async {
  final service = AudioRecorderService();
  
  try {
    // İzin kontrolü
    if (!await service.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon izni gerekli. Lütfen ayarlardan izin verin.'),
            action: SnackBarAction(
              label: 'Ayarlar',
              onPressed: () {
                // permission_handler ile ayarlara yönlendir
              },
            ),
          ),
        );
      }
      return;
    }
    
    // Kayıt başlat
    await service.startRecording();
    
    // Dialog göster
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudioRecordingDialog(recorder: service),
    );
    
    await service.dispose();
    
    if (path != null) {
      // Block oluştur
      final block = Block(
        pageId: widget.page.id,
        type: BlockType.audio,
        x: 0.1,
        y: 0.4,
        width: 0.6,
        height: 0.1,
        zIndex: _blocks.length,
        payloadJson: AudioBlockPayload(
          path: path,
          durationMs: service.currentDuration.inMilliseconds,
        ).toJsonString(),
      );
      
      await ref.read(blockDaoProvider).insertBlock(block);
      _uploadAndSyncAudioBlock(block, File(path));
      
      setState(() => _isDirty = true);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e')),
      );
    }
  }
}
```

**Performans:**
- Waveform güncellemesi 150ms aralıklarla (çok sık değil)
- Timer 100ms aralıklarla (yeterince hassas)
- Stream kullanımı (gereksiz rebuild yok)

#### Test Senaryoları

1. **Duration Tracking:**
   - Timer doğru çalışıyor mu?
   - Pause/resume sırasında süre doğru hesaplanıyor mu?
   - Format doğru mu (MM:SS)?

2. **Waveform:**
   - Waveform animasyonu çalışıyor mu?
   - Görsel olarak iyi görünüyor mu?

3. **Pause/Resume:**
   - Pause butonu çalışıyor mu?
   - Resume butonu çalışıyor mu?
   - Timer pause/resume sırasında doğru çalışıyor mu?

4. **Kayıt:**
   - Stop butonu kaydı durduruyor mu?
   - İptal butonu kaydı iptal ediyor mu?
   - Dosya doğru oluşturuluyor mu?
   - Duration block'a kaydediliyor mu?

---

### 6. Geri Butonu İyileştirme

#### Ne Olduğu
Editor'den çıkarken kaydedilmemiş değişiklikler varsa kullanıcıya uyarı gösteren, kaydetme seçeneği sunan bir mekanizma.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: PopScope/WillPopScope Ekle**
- `lib/features/editor/editor_screen.dart` dosyasını aç
- `EditorScreen` widget'ını bul
- `PopScope` widget'ı ekle (Flutter 3.12+) veya `WillPopScope` (eski versiyonlar için)
- `canPop: !_isDirty` (dirty ise çıkışı engelle)

**Adım 2: Uyarı Dialog'u Oluştur**
- `_isDirty` true ise uyarı dialog'u göster
- Dialog seçenekleri:
  - "Kaydet ve Çık" - kaydet, sonra çık
  - "Çık (Kaydetme)" - kaydetmeden çık
  - "İptal" - dialog'u kapat, editor'de kal

**Adım 3: Navigation Yönetimi**
- AppBar'daki geri butonunu güncelle
- `PopScope.onPopInvoked` veya `WillPopScope.onWillPop` kullan
- Navigator.pop() çağrısını kontrol et

**Adım 4: Kaydetme İşlemi**
- "Kaydet ve Çık" seçilirse `_save()` metodunu çağır
- Kaydetme tamamlandıktan sonra çık
- Kaydetme hatası varsa kullanıcıya göster ve çıkma

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Editor screen'in local state'i (_isDirty)

**Servisler:**
- `_save()` metodu (mevcut) - kaydetme işlemi

**Paketler:**
- Hiçbir yeni paket gerekmez

#### Veri Modelleri

**Yeni Model Gerekmez**

#### API Tasarımları

**Editor Screen Metodları (Yeni Eklenecek):**
```dart
Future<bool> _handleBackButton(); // Geri butonu işleme
Future<void> _showUnsavedChangesDialog(); // Uyarı dialog'u
```

#### UI/UX Detayları

**Uyarı Dialog:**
```
AlertDialog
  title: "Kaydedilmemiş Değişiklikler"
  content: Text ("Kaydedilmemiş değişiklikleriniz var. Ne yapmak istersiniz?")
  actions:
    TextButton ("Çık (Kaydetme)", kırmızı renk)
    TextButton ("İptal")
    FilledButton ("Kaydet ve Çık", primary renk)
```

**Geri Butonu Davranışı:**
- `_isDirty` false ise: direkt çık
- `_isDirty` true ise: uyarı dialog'u göster

#### Teknik Detaylar

**Kod Yapısı:**
```dart
// lib/features/editor/editor_screen.dart içinde
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: !_isDirty,
    onPopInvoked: (didPop) async {
      if (didPop) return;
      if (_isDirty) {
        final shouldPop = await _handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      }
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_isDirty) {
              final shouldPop = await _handleBackButton();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        // ...
      ),
      // ...
    ),
  );
}

Future<bool> _handleBackButton() async {
  if (!_isDirty) return true;
  
  return await _showUnsavedChangesDialog();
}

Future<bool> _showUnsavedChangesDialog() async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kaydedilmemiş Değişiklikler'),
      content: const Text(
        'Kaydedilmemiş değişiklikleriniz var. Ne yapmak istersiniz?',
      ),
      actions: [
        // Çık (Kaydetme)
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Çık (Kaydetme)'),
        ),
        // İptal
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        // Kaydet ve Çık
        FilledButton(
          onPressed: () async {
            await _save();
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Kaydet ve Çık'),
        ),
      ],
    ),
  );
  
  return result ?? false;
}
```

**Flutter Versiyon Uyumluluğu:**
- Flutter 3.12+: `PopScope` kullan
- Flutter < 3.12: `WillPopScope` kullan

**Hata Yönetimi:**
- Kaydetme hatası varsa: SnackBar göster, çıkma
- Network hatası: Kullanıcıya sor (çıkmak istiyor mu?)

#### Test Senaryoları

1. **Dirty State:**
   - Değişiklik yapıldığında _isDirty true oluyor mu?
   - Kaydedildiğinde _isDirty false oluyor mu?

2. **Geri Butonu:**
   - Dirty değilken direkt çıkıyor mu?
   - Dirty iken uyarı dialog'u gösteriliyor mu?

3. **Dialog Seçenekleri:**
   - "Kaydet ve Çık" çalışıyor mu?
   - "Çık (Kaydetme)" çalışıyor mu?
   - "İptal" çalışıyor mu?

4. **Kaydetme Hatası:**
   - Kaydetme hatası varsa kullanıcıya gösteriliyor mu?
   - Hata durumunda çıkılıyor mu?

---

## FAZ 2: Collaboration & Sharing Sistemi

### 7. Ekip Sistemi (Team System)

#### Ne Olduğu
Kullanıcıların grup journal'ları oluşturmak için ekipler oluşturabileceği, ekip üyelerini yönetebileceği, roller atayabileceği bir sistem.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Team Model Oluştur**
- `lib/core/models/team.dart` dosyası oluştur
- Team entity tanımla
- TeamMember entity tanımla
- JournalRole enum tanımla (owner, editor, viewer)

**Adım 2: Database Schema Güncelle**
- `lib/core/database/tables/teams_table.dart` oluştur
- `lib/core/database/tables/team_members_table.dart` oluştur
- Drift migration ekle
- TeamDao oluştur

**Adım 3: Firestore Yapısı Oluştur**
- FirestoreService'e team metodları ekle
- Firestore security rules güncelle

**Adım 4: Team Service Oluştur**
- `lib/features/team/team_service.dart` oluştur
- Ekip oluşturma, üye ekleme, rol yönetimi metodları

**Adım 5: UI Ekranları Oluştur**
- Team list screen
- Team management screen
- Team member management screen

**Adım 6: Journal Model Güncelle**
- Journal'a teamId field ekle
- Journal type enum ekle (personal, team)

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (team providers)

**Database:**
- Drift (SQLite) - local database
- Firestore - cloud database

**Servisler:**
- TeamService (yeni)
- FirestoreService (güncelleme)
- SyncService (güncelleme - team sync için)

**Paketler:**
- Hiçbir yeni paket gerekmez (mevcut paketler yeterli)

#### Veri Modelleri

**Team Model:**
```dart
// lib/core/models/team.dart
import 'package:uuid/uuid.dart';
import 'base_entity.dart';

enum JournalRole {
  owner,
  editor,
  viewer;
  
  String get displayName {
    switch (this) {
      case JournalRole.owner:
        return 'Sahip';
      case JournalRole.editor:
        return 'Düzenleyici';
      case JournalRole.viewer:
        return 'Görüntüleyici';
    }
  }
}

class Team implements BaseEntity {
  @override
  final String id;
  
  final String name;
  final String ownerId;
  final String? description;
  final String? avatarUrl;
  
  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  
  Team({
    String? id,
    required this.name,
    required this.ownerId,
    this.description,
    this.avatarUrl,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  @override
  bool get isDeleted => deletedAt != null;
  
  Team copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? description,
    String? avatarUrl,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class TeamMember implements BaseEntity {
  @override
  final String id;
  
  final String teamId;
  final String userId;
  final JournalRole role;
  final DateTime joinedAt;
  
  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  
  TeamMember({
    String? id,
    required this.teamId,
    required this.userId,
    required this.role,
    DateTime? joinedAt,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       joinedAt = joinedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  @override
  bool get isDeleted => deletedAt != null;
  
  TeamMember copyWith({
    String? id,
    String? teamId,
    String? userId,
    JournalRole? role,
    DateTime? joinedAt,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
```

**Journal Model Güncelleme:**
```dart
// lib/core/models/journal.dart güncelleme
enum JournalType {
  personal,
  team;
}

class Journal implements BaseEntity {
  // Mevcut field'lar
  final String title;
  final String coverStyle;
  
  // YENİ EKLENECEK
  final JournalType type;
  final String? teamId; // Team journal ise teamId, personal ise null
  final String ownerId; // Journal sahibi (personal için userId, team için teamId)
  
  Journal({
    // Mevcut parametreler
    required this.title,
    this.coverStyle = 'default',
    // YENİ
    this.type = JournalType.personal,
    this.teamId,
    required this.ownerId,
    // ...
  });
  
  // copyWith güncelle
}
```

#### API Tasarımları

**TeamService API:**
```dart
// lib/features/team/team_service.dart
class TeamService {
  // Ekip oluştur
  Future<Team> createTeam({
    required String name,
    String? description,
  });
  
  // Ekip listesi al
  Stream<List<Team>> watchMyTeams();
  
  // Ekip detayı al
  Future<Team?> getTeamById(String teamId);
  
  // Ekip üyelerini al
  Stream<List<TeamMember>> watchTeamMembers(String teamId);
  
  // Üye ekle
  Future<void> addMember({
    required String teamId,
    required String userId,
    required JournalRole role,
  });
  
  // Üye çıkar
  Future<void> removeMember({
    required String teamId,
    required String userId,
  });
  
  // Rol değiştir
  Future<void> updateMemberRole({
    required String teamId,
    required String userId,
    required JournalRole newRole,
  });
  
  // Ekip sil
  Future<void> deleteTeam(String teamId);
}
```

**FirestoreService API (Güncelleme):**
```dart
// lib/core/database/firestore_service.dart içine eklenecek
// Teams
Future<void> createTeam(Team team);
Future<void> updateTeam(Team team);
Future<void> deleteTeam(String teamId);
Stream<List<Team>> watchMyTeams();

// Team Members
Future<void> addTeamMember(TeamMember member);
Future<void> updateTeamMember(TeamMember member);
Future<void> removeTeamMember(String memberId);
Stream<List<TeamMember>> watchTeamMembers(String teamId);
```

#### UI/UX Detayları

**Team List Screen:**
```
Scaffold
  AppBar
    title: "Ekiplerim"
    actions: FAB (yeni ekip oluştur)
  Body
    ListView
      TeamCard (her ekip için)
        - Ekip adı
        - Üye sayısı
        - Son aktivite
        - Tıklanınca: TeamManagementScreen'e git
```

**Team Management Screen:**
```
Scaffold
  AppBar
    title: "Ekip Yönetimi"
  Body
    Column
      // Ekip bilgileri
      TeamInfoCard
        - Ekip adı (düzenlenebilir)
        - Açıklama (düzenlenebilir)
        - Avatar (değiştirilebilir)
      
      Divider
      
      // Üyeler listesi
      ExpansionTile ("Üyeler")
        ListView
          TeamMemberTile (her üye için)
            - Avatar
            - İsim
            - Rol (dropdown ile değiştirilebilir - sadece owner)
            - Çıkar butonu (sadece owner)
      
      // Yeni üye ekle butonu
      FilledButton ("Üye Ekle")
```

**Team Member Tile:**
```
ListTile
  leading: CircleAvatar (üye avatarı)
  title: Text (üye ismi)
  subtitle: Text (rol)
  trailing: 
    if (isOwner)
      PopupMenuButton
        "Rol Değiştir"
        "Üyeyi Çıkar"
```

#### Teknik Detaylar

**Database Tables:**
```dart
// lib/core/database/tables/teams_table.dart
class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// lib/core/database/tables/team_members_table.dart
class TeamMembers extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()(); // 'owner', 'editor', 'viewer'
  DateTimeColumn get joinedAt => dateTime()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Firestore Yapısı:**
```
teams/{teamId}
  - id: string
  - name: string
  - ownerId: string
  - description: string?
  - avatarUrl: string?
  - createdAt: timestamp
  - updatedAt: timestamp
  - deletedAt: timestamp?

team_members/{memberId}
  - id: string
  - teamId: string
  - userId: string
  - role: string ('owner' | 'editor' | 'viewer')
  - joinedAt: timestamp
  - createdAt: timestamp
  - updatedAt: timestamp
  - deletedAt: timestamp?
```

**Firestore Security Rules:**
```javascript
match /teams/{teamId} {
  allow read: if request.auth != null && 
    (resource.data.ownerId == request.auth.uid || 
     exists(/databases/$(database)/documents/team_members/$(teamId + '_' + request.auth.uid)));
  allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
  allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
}

match /team_members/{memberId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
    get(/databases/$(database)/documents/teams/$(resource.data.teamId)).data.ownerId == request.auth.uid;
  allow update, delete: if request.auth != null && 
    get(/databases/$(database)/documents/teams/$(resource.data.teamId)).data.ownerId == request.auth.uid;
}
```

**Sync Mekanizması:**
- Team oluşturulduğunda: Local DB'ye kaydet, Firestore'a sync et
- Team güncellendiğinde: Local DB güncelle, Firestore'a sync et
- Team silindiğinde: Soft delete (deletedAt set), Firestore'a sync et
- Team member eklendiğinde: Local DB'ye kaydet, Firestore'a sync et

#### Test Senaryoları

1. **Ekip Oluşturma:**
   - Ekip oluşturuluyor mu?
   - Owner otomatik üye oluyor mu?
   - Local DB'ye kaydediliyor mu?
   - Firestore'a sync oluyor mu?

2. **Üye Yönetimi:**
   - Üye ekleniyor mu?
   - Rol değiştiriliyor mu?
   - Üye çıkarılıyor mu?
   - Yetkiler doğru çalışıyor mu? (sadece owner yönetebilir)

3. **Journal Entegrasyonu:**
   - Team journal oluşturulabiliyor mu?
   - Team üyeleri journal'a erişebiliyor mu?
   - Roller journal'da doğru çalışıyor mu?

---

### 8. Davet Sistemi (Invite System)

#### Ne Olduğu
Kullanıcıların journal'lara veya ekiplere diğer kullanıcıları davet edebileceği, davet linkleri oluşturabileceği, davetleri kabul/reddedebileceği bir sistem.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Invite Model Oluştur**
- `lib/core/models/invite.dart` dosyası oluştur
- Invite entity tanımla
- InviteType enum (journal, team)
- InviteStatus enum (pending, accepted, rejected, expired)

**Adım 2: Database Schema**
- `lib/core/database/tables/invites_table.dart` oluştur
- InviteDao oluştur

**Adım 3: Invite Service Oluştur**
- `lib/features/invite/invite_service.dart` oluştur
- Davet oluşturma, kabul/reddetme, link oluşturma metodları

**Adım 4: Firestore Yapısı**
- FirestoreService'e invite metodları ekle
- Security rules güncelle

**Adım 5: UI Ekranları**
- Invite dialog (davet gönderme)
- Invite notification (gelen davetler)
- Invite list screen (gönderilen/alınan davetler)

**Adım 6: Deep Link Entegrasyonu**
- Davet linkleri için deep link handler
- Link'ten davet açma

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (invite providers)

**Database:**
- Drift (SQLite)
- Firestore

**Servisler:**
- InviteService (yeni)
- DeepLinkService (yeni - link sistemi ile birlikte)
- UserService (mevcut - kullanıcı arama için)

**Paketler:**
- `uuid` (mevcut) - invite ID için

#### Veri Modelleri

**Invite Model:**
```dart
// lib/core/models/invite.dart
import 'package:uuid/uuid.dart';
import 'base_entity.dart';

enum InviteType {
  journal,
  team;
}

enum InviteStatus {
  pending,
  accepted,
  rejected,
  expired;
}

class Invite implements BaseEntity {
  @override
  final String id;
  
  final InviteType type;
  final String targetId; // journalId veya teamId
  final String inviterId;
  final String inviteeId; // null ise public link
  final InviteStatus status;
  final JournalRole? role; // Davet edilen kişinin rolü
  final DateTime? expiresAt;
  final String? message; // Davet mesajı
  
  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  
  Invite({
    String? id,
    required this.type,
    required this.targetId,
    required this.inviterId,
    this.inviteeId,
    this.status = InviteStatus.pending,
    this.role,
    this.expiresAt,
    this.message,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  @override
  bool get isDeleted => deletedAt != null;
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  Invite copyWith({
    String? id,
    InviteType? type,
    String? targetId,
    String? inviterId,
    String? inviteeId,
    InviteStatus? status,
    JournalRole? role,
    DateTime? expiresAt,
    String? message,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Invite(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      status: status ?? this.status,
      role: role ?? this.role,
      expiresAt: expiresAt ?? this.expiresAt,
      message: message ?? this.message,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
```

#### API Tasarımları

**InviteService API:**
```dart
// lib/features/invite/invite_service.dart
class InviteService {
  // Davet oluştur
  Future<Invite> createInvite({
    required InviteType type,
    required String targetId,
    String? inviteeId, // null ise public link
    JournalRole? role,
    String? message,
    Duration? expiresIn, // null ise süresiz
  });
  
  // Davet linki oluştur
  Future<String> createInviteLink(Invite invite);
  
  // Davet kabul et
  Future<void> acceptInvite(String inviteId);
  
  // Davet reddet
  Future<void> rejectInvite(String inviteId);
  
  // Gelen davetleri al
  Stream<List<Invite>> watchIncomingInvites();
  
  // Gönderilen davetleri al
  Stream<List<Invite>> watchOutgoingInvites(String targetId);
  
  // Davet detayı al
  Future<Invite?> getInviteById(String inviteId);
  
  // Davet linkinden davet al
  Future<Invite?> getInviteFromLink(String linkId);
}
```

**FirestoreService API (Güncelleme):**
```dart
// lib/core/database/firestore_service.dart içine eklenecek
// Invites
Future<void> createInvite(Invite invite);
Future<void> updateInvite(Invite invite);
Stream<List<Invite>> watchIncomingInvites();
Stream<List<Invite>> watchOutgoingInvites(String targetId);
Future<Invite?> getInviteById(String inviteId);
```

#### UI/UX Detayları

**Invite Dialog (Davet Gönderme):**
```
AlertDialog
  title: "Davet Gönder"
  content: Column
    // Davet türü seçimi (journal/team)
    DropdownButton (InviteType)
    
    // Kullanıcı arama (inviteeId için)
    TextField (kullanıcı ID veya email arama)
    ListView (arama sonuçları)
      UserTile (seçilebilir)
    
    // Rol seçimi
    DropdownButton (JournalRole: editor/viewer)
    
    // Mesaj (opsiyonel)
    TextField (davet mesajı)
    
    // Süre seçimi (opsiyonel)
    Checkbox ("Süre sınırı koy")
    if (checked) DatePicker (expiresAt)
  
  actions
    TextButton ("İptal")
    FilledButton ("Davet Gönder")
```

**Invite Notification (Gelen Davetler):**
```
NotificationCard
  - Davet eden kişi bilgisi (avatar, isim)
  - Davet türü (journal/team)
  - Hedef bilgisi (journal/team adı)
  - Mesaj (varsa)
  - Butonlar: "Kabul Et", "Reddet"
```

**Invite List Screen:**
```
Scaffold
  AppBar
    title: "Davetlerim"
    tabs: ["Gelen", "Gönderilen"]
  Body
    TabBarView
      // Gelen davetler
      ListView
        InviteCard (pending)
          - Davet eden
          - Hedef
          - Butonlar: Kabul/Reddet
      
      // Gönderilen davetler
      ListView
        InviteCard
          - Davet edilen
          - Hedef
          - Durum: pending/accepted/rejected
```

#### Teknik Detaylar

**Database Tables:**
```dart
// lib/core/database/tables/invites_table.dart
class Invites extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'journal' | 'team'
  TextColumn get targetId => text()();
  TextColumn get inviterId => text()();
  TextColumn get inviteeId => text().nullable()();
  TextColumn get status => text()(); // 'pending' | 'accepted' | 'rejected' | 'expired'
  TextColumn get role => text().nullable()(); // 'owner' | 'editor' | 'viewer'
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get message => text().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Firestore Yapısı:**
```
invites/{inviteId}
  - id: string
  - type: string ('journal' | 'team')
  - targetId: string
  - inviterId: string
  - inviteeId: string? (null ise public link)
  - status: string ('pending' | 'accepted' | 'rejected' | 'expired')
  - role: string? ('owner' | 'editor' | 'viewer')
  - expiresAt: timestamp?
  - message: string?
  - createdAt: timestamp
  - updatedAt: timestamp
  - deletedAt: timestamp?
```

**Firestore Security Rules:**
```javascript
match /invites/{inviteId} {
  allow read: if request.auth != null && 
    (resource.data.inviterId == request.auth.uid || 
     resource.data.inviteeId == request.auth.uid);
  allow create: if request.auth != null && 
    request.resource.data.inviterId == request.auth.uid;
  allow update: if request.auth != null && 
    (resource.data.inviterId == request.auth.uid || 
     resource.data.inviteeId == request.auth.uid);
  allow delete: if request.auth != null && 
    resource.data.inviterId == request.auth.uid;
}
```

**Deep Link Formatı:**
```
journalapp://invite/{inviteId}
https://journalapp.page.link/invite/{inviteId} (Firebase Dynamic Links)
```

**Davet Kabul/Reddetme İşlemi:**
1. Invite status'u güncelle (accepted/rejected)
2. Eğer journal daveti ise: Journal'a erişim ver (JournalAccess tablosuna ekle)
3. Eğer team daveti ise: TeamMember ekle
4. Notification gönder (inviter'a)

#### Test Senaryoları

1. **Davet Oluşturma:**
   - Journal daveti oluşturuluyor mu?
   - Team daveti oluşturuluyor mu?
   - Public link oluşturuluyor mu?
   - Local DB'ye kaydediliyor mu?
   - Firestore'a sync oluyor mu?

2. **Davet Kabul/Reddetme:**
   - Davet kabul ediliyor mu?
   - Davet reddediliyor mu?
   - Journal/Team erişimi veriliyor mu?
   - Notification gönderiliyor mu?

3. **Davet Linkleri:**
   - Link oluşturuluyor mu?
   - Link'ten davet açılıyor mu?
   - Deep link çalışıyor mu?
   - Süre dolmuş davetler reddediliyor mu?

---

### 9. Paylaş Sistemi (Share System)

#### Ne Olduğu
Journal'ları farklı seviyelerde paylaşabilme, paylaşım linkleri oluşturma, erişim yönetimi yapabilme sistemi.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: ShareSettings Model Oluştur**
- `lib/core/models/share_settings.dart` dosyası oluştur
- ShareLevel enum (private, team, friends, public)
- ShareSettings entity tanımla

**Adım 2: Journal Model Güncelle**
- Journal'a shareSettings field ekle
- Share link field ekle

**Adım 3: Share Service Oluştur**
- `lib/features/share/share_service.dart` oluştur
- Paylaşım ayarları yönetimi
- Link oluşturma/güncelleme

**Adım 4: UI Ekranları**
- Share dialog (paylaşım seçenekleri)
- Share settings screen (ayarları yönetme)

**Adım 5: Erişim Kontrolü**
- Journal erişim kontrolü (share level'a göre)
- Read-only erişim (public link için)

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (share providers)

**Database:**
- Drift (SQLite)
- Firestore

**Servisler:**
- ShareService (yeni)
- DeepLinkService (link sistemi ile birlikte)
- UserService (arkadaş kontrolü için)
- TeamService (ekip kontrolü için)

**Paketler:**
- `share_plus` (opsiyonel - native paylaşım için)
- `uuid` (mevcut) - link ID için

#### Veri Modelleri

**ShareSettings Model:**
```dart
// lib/core/models/share_settings.dart
enum ShareLevel {
  private,  // Sadece sahip
  team,      // Ekip üyeleri
  friends,   // Arkadaşlar
  public;    // Herkes (link ile)
  
  String get displayName {
    switch (this) {
      case ShareLevel.private:
        return 'Özel';
      case ShareLevel.team:
        return 'Ekip';
      case ShareLevel.friends:
        return 'Arkadaşlar';
      case ShareLevel.public:
        return 'Herkese Açık';
    }
  }
}

class ShareSettings {
  final ShareLevel level;
  final String? shareLinkId; // Public link için unique ID
  final DateTime? linkExpiresAt;
  final bool allowComments; // Gelecek için
  final bool allowCopy; // Gelecek için
  
  ShareSettings({
    this.level = ShareLevel.private,
    this.shareLinkId,
    this.linkExpiresAt,
    this.allowComments = false,
    this.allowCopy = true,
  });
  
  ShareSettings copyWith({
    ShareLevel? level,
    String? shareLinkId,
    DateTime? linkExpiresAt,
    bool? allowComments,
    bool? allowCopy,
  }) {
    return ShareSettings(
      level: level ?? this.level,
      shareLinkId: shareLinkId ?? this.shareLinkId,
      linkExpiresAt: linkExpiresAt ?? this.linkExpiresAt,
      allowComments: allowComments ?? this.allowComments,
      allowCopy: allowCopy ?? this.allowCopy,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'shareLinkId': shareLinkId,
      'linkExpiresAt': linkExpiresAt?.toIso8601String(),
      'allowComments': allowComments,
      'allowCopy': allowCopy,
    };
  }
  
  factory ShareSettings.fromJson(Map<String, dynamic> json) {
    return ShareSettings(
      level: ShareLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => ShareLevel.private,
      ),
      shareLinkId: json['shareLinkId'] as String?,
      linkExpiresAt: json['linkExpiresAt'] != null
          ? DateTime.parse(json['linkExpiresAt'])
          : null,
      allowComments: json['allowComments'] ?? false,
      allowCopy: json['allowCopy'] ?? true,
    );
  }
}
```

**Journal Model Güncelleme:**
```dart
// lib/core/models/journal.dart güncelleme
class Journal implements BaseEntity {
  // Mevcut field'lar
  final String title;
  final String coverStyle;
  final JournalType type;
  final String? teamId;
  final String ownerId;
  
  // YENİ EKLENECEK
  final ShareSettings shareSettings;
  
  Journal({
    // Mevcut parametreler
    required this.title,
    this.coverStyle = 'default',
    this.type = JournalType.personal,
    this.teamId,
    required this.ownerId,
    // YENİ
    ShareSettings? shareSettings,
    // ...
  }) : shareSettings = shareSettings ?? ShareSettings();
  
  // copyWith güncelle
}
```

#### API Tasarımları

**ShareService API:**
```dart
// lib/features/share/share_service.dart
class ShareService {
  // Paylaşım ayarlarını güncelle
  Future<void> updateShareSettings({
    required String journalId,
    required ShareSettings settings,
  });
  
  // Paylaşım linki oluştur
  Future<String> createShareLink({
    required String journalId,
    Duration? expiresIn,
  });
  
  // Paylaşım linkini iptal et
  Future<void> revokeShareLink(String journalId);
  
  // Journal erişim kontrolü
  Future<bool> canAccessJournal({
    required String journalId,
    required String userId,
  });
  
  // Paylaşım linkinden journal al
  Future<Journal?> getJournalFromShareLink(String linkId);
}
```

#### UI/UX Detayları

**Share Dialog:**
```
AlertDialog
  title: "Journal'ı Paylaş"
  content: Column
    // Paylaşım seviyesi seçimi
    RadioListTile (Özel - Sadece ben)
    RadioListTile (Ekip - Ekip üyeleri)
    RadioListTile (Arkadaşlar - Arkadaşlarım)
    RadioListTile (Herkese Açık - Link ile)
    
    if (public selected)
      Column
        // Link oluştur
        FilledButton ("Link Oluştur")
        if (link exists)
          TextField (link, read-only, kopyalanabilir)
          Row
            IconButton (kopyala)
            IconButton (yeniden oluştur)
            IconButton (iptal et)
        
        // Süre seçimi
        Checkbox ("Süre sınırı koy")
        if (checked) DatePicker (expiresAt)
  
  actions
    TextButton ("İptal")
    FilledButton ("Kaydet")
```

**Share Settings Screen:**
```
Scaffold
  AppBar
    title: "Paylaşım Ayarları"
  Body
    ListView
      // Mevcut paylaşım seviyesi
      ListTile
        title: "Paylaşım Seviyesi"
        subtitle: ShareLevel display name
        trailing: Icon (chevron_right)
        onTap: () => ShareDialog aç
        
      if (public link exists)
        // Link bilgileri
        Card
          ListTile
            title: "Paylaşım Linki"
            subtitle: Link (kopyalanabilir)
          ListTile
            title: "Süre"
            subtitle: expiresAt veya "Süresiz"
          ListTile
            title: "Link'i İptal Et"
            trailing: Switch
            onTap: () => Link iptal et
```

#### Teknik Detaylar

**Journal Table Güncelleme:**
```dart
// lib/core/database/tables/journals_table.dart güncelleme
class Journals extends Table {
  // Mevcut column'lar
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get coverStyle => text().withDefault(const Constant('default'))();
  TextColumn get type => text().withDefault(const Constant('personal'))();
  TextColumn get teamId => text().nullable()();
  TextColumn get ownerId => text()();
  
  // YENİ EKLENECEK
  TextColumn get shareSettingsJson => text().withDefault(const Constant('{}'))();
  
  // ...
}
```

**Firestore Yapısı:**
```
journals/{journalId}
  - shareSettings: {
      level: 'private' | 'team' | 'friends' | 'public',
      shareLinkId: string?,
      linkExpiresAt: timestamp?,
      allowComments: boolean,
      allowCopy: boolean
    }
```

**Erişim Kontrolü Mantığı:**
```dart
Future<bool> canAccessJournal(String journalId, String userId) async {
  final journal = await journalDao.getById(journalId);
  if (journal == null) return false;
  
  // Sahip her zaman erişebilir
  if (journal.ownerId == userId) return true;
  
  final settings = journal.shareSettings;
  
  switch (settings.level) {
    case ShareLevel.private:
      return false;
      
    case ShareLevel.team:
      if (journal.teamId == null) return false;
      final isMember = await teamService.isMember(journal.teamId!, userId);
      return isMember;
      
    case ShareLevel.friends:
      final isFriend = await userService.isFriend(userId);
      return isFriend;
      
    case ShareLevel.public:
      // Link kontrolü
      if (settings.shareLinkId == null) return false;
      // Link expire kontrolü
      if (settings.linkExpiresAt != null && 
          DateTime.now().isAfter(settings.linkExpiresAt!)) {
        return false;
      }
      return true;
  }
}
```

**Share Link Formatı:**
```
journalapp://journal/{shareLinkId}
https://journalapp.page.link/journal/{shareLinkId} (Firebase Dynamic Links)
```

#### Test Senaryoları

1. **Paylaşım Ayarları:**
   - Paylaşım seviyesi değiştiriliyor mu?
   - Ayarlar kaydediliyor mu?
   - Sync çalışıyor mu?

2. **Paylaşım Linkleri:**
   - Link oluşturuluyor mu?
   - Link kopyalanabiliyor mu?
   - Link iptal ediliyor mu?
   - Link expire çalışıyor mu?

3. **Erişim Kontrolü:**
   - Private journal'a sadece sahip erişebiliyor mu?
   - Team journal'a ekip üyeleri erişebiliyor mu?
   - Friends journal'a arkadaşlar erişebiliyor mu?
   - Public link çalışıyor mu?

---

### 10. Link Sistemi (Deep Linking)

#### Ne Olduğu
Uygulama içi ve dışından linklerle journal'lara, davetlere, ekiplere erişim sağlayan deep linking sistemi.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Deep Link Service Oluştur**
- `lib/core/deep_linking/deep_link_service.dart` oluştur
- Link oluşturma, parsing, validation metodları

**Adım 2: Deep Link Handler Oluştur**
- `lib/core/deep_linking/deep_link_handler.dart` oluştur
- Link türüne göre routing

**Adım 3: Platform Yapılandırması**
- Android: AndroidManifest.xml intent filters
- iOS: Info.plist URL schemes
- Firebase Dynamic Links (opsiyonel)

**Adım 4: Main.dart Entegrasyonu**
- App lifecycle'da deep link dinleme
- Initial link handling

**Adım 5: Navigation Entegrasyonu**
- Link'ten journal açma
- Link'ten davet açma
- Link'ten team açma

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (deep link providers)

**Platform:**
- `uni_links` veya `app_links` paketi (deep link dinleme)
- Firebase Dynamic Links (opsiyonel)

**Servisler:**
- DeepLinkService (yeni)
- DeepLinkHandler (yeni)
- NavigationService (mevcut)

**Paketler:**
- `app_links` (yeni eklenecek) - deep link handling
- `firebase_dynamic_links` (opsiyonel)

#### Veri Modelleri

**DeepLink Model:**
```dart
// lib/core/deep_linking/deep_link_model.dart
enum DeepLinkType {
  journal,
  invite,
  team,
  share,
}

class DeepLink {
  final DeepLinkType type;
  final String id;
  final Map<String, String>? parameters;
  
  DeepLink({
    required this.type,
    required this.id,
    this.parameters,
  });
  
  factory DeepLink.fromUri(Uri uri) {
    // journalapp://journal/{id}
    // journalapp://invite/{id}
    // journalapp://team/{id}
    // journalapp://share/{linkId}
    
    final scheme = uri.scheme; // 'journalapp'
    final host = uri.host; // 'journal', 'invite', 'team', 'share'
    final pathSegments = uri.pathSegments; // [id]
    
    DeepLinkType? type;
    switch (host) {
      case 'journal':
        type = DeepLinkType.journal;
        break;
      case 'invite':
        type = DeepLinkType.invite;
        break;
      case 'team':
        type = DeepLinkType.team;
        break;
      case 'share':
        type = DeepLinkType.share;
        break;
    }
    
    if (type == null || pathSegments.isEmpty) {
      throw Exception('Invalid deep link');
    }
    
    return DeepLink(
      type: type,
      id: pathSegments.first,
      parameters: uri.queryParameters,
    );
  }
  
  Uri toUri() {
    String host;
    switch (type) {
      case DeepLinkType.journal:
        host = 'journal';
        break;
      case DeepLinkType.invite:
        host = 'invite';
        break;
      case DeepLinkType.team:
        host = 'team';
        break;
      case DeepLinkType.share:
        host = 'share';
        break;
    }
    
    return Uri(
      scheme: 'journalapp',
      host: host,
      pathSegments: [id],
      queryParameters: parameters,
    );
  }
}
```

#### API Tasarımları

**DeepLinkService API:**
```dart
// lib/core/deep_linking/deep_link_service.dart
class DeepLinkService {
  // Deep link stream (uygulama açıkken)
  Stream<DeepLink> get linkStream;
  
  // Initial link (uygulama kapalıyken açıldığında)
  Future<DeepLink?> getInitialLink();
  
  // Link oluştur
  String createLink(DeepLink link);
  
  // Link parse et
  DeepLink? parseLink(String link);
  
  // Link validate et
  Future<bool> validateLink(DeepLink link);
}
```

**DeepLinkHandler API:**
```dart
// lib/core/deep_linking/deep_link_handler.dart
class DeepLinkHandler {
  final DeepLinkService _linkService;
  final NavigationService _navigationService;
  final ShareService _shareService;
  final InviteService _inviteService;
  final TeamService _teamService;
  
  // Link'i işle
  Future<void> handleLink(DeepLink link);
  
  // Journal link'i işle
  Future<void> handleJournalLink(String journalId);
  
  // Davet link'i işle
  Future<void> handleInviteLink(String inviteId);
  
  // Team link'i işle
  Future<void> handleTeamLink(String teamId);
  
  // Share link'i işle
  Future<void> handleShareLink(String linkId);
}
```

#### UI/UX Detayları

**Link Açma Senaryoları:**

1. **Journal Link:**
   - Link açıldığında: Journal detay ekranına git
   - Erişim yoksa: "Bu journal'a erişim izniniz yok" mesajı
   - Read-only ise: Preview mode'da aç

2. **Invite Link:**
   - Link açıldığında: Invite detay dialog'u göster
   - Kabul/Reddet butonları
   - Davet eden kişi bilgisi

3. **Team Link:**
   - Link açıldığında: Team detay ekranına git
   - Erişim yoksa: "Bu ekibe erişim izniniz yok" mesajı

4. **Share Link:**
   - Link açıldığında: Journal preview ekranına git (read-only)
   - Erişim yoksa: "Bu link geçersiz veya süresi dolmuş" mesajı

#### Teknik Detaylar

**Android Yapılandırması:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity
    android:name=".MainActivity"
    ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="journalapp" />
    </intent-filter>
    
    <!-- Firebase Dynamic Links için -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="journalapp.page.link" />
    </intent-filter>
</activity>
```

**iOS Yapılandırması:**
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.journalapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>journalapp</string>
        </array>
    </dict>
</array>

<!-- Universal Links için -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:journalapp.page.link</string>
</array>
```

**Main.dart Entegrasyonu:**
```dart
// lib/main.dart
void main() async {
  // ... mevcut kod
  
  runApp(ProviderScope(
    child: const JournalApp(),
  ));
  
  // Deep link handling
  final deepLinkService = DeepLinkService();
  final handler = DeepLinkHandler(deepLinkService, ...);
  
  // Initial link (uygulama kapalıyken açıldığında)
  final initialLink = await deepLinkService.getInitialLink();
  if (initialLink != null) {
    handler.handleLink(initialLink);
  }
  
  // Link stream (uygulama açıkken)
  deepLinkService.linkStream.listen((link) {
    handler.handleLink(link);
  });
}
```

**DeepLinkHandler Implementasyonu:**
```dart
// lib/core/deep_linking/deep_link_handler.dart
class DeepLinkHandler {
  // ...
  
  Future<void> handleLink(DeepLink link) async {
    switch (link.type) {
      case DeepLinkType.journal:
        await handleJournalLink(link.id);
        break;
      case DeepLinkType.invite:
        await handleInviteLink(link.id);
        break;
      case DeepLinkType.team:
        await handleTeamLink(link.id);
        break;
      case DeepLinkType.share:
        await handleShareLink(link.id);
        break;
    }
  }
  
  Future<void> handleJournalLink(String journalId) async {
    // Erişim kontrolü
    final canAccess = await _shareService.canAccessJournal(
      journalId: journalId,
      userId: _authService.currentUser?.uid ?? '',
    );
    
    if (!canAccess) {
      // Hata mesajı göster
      return;
    }
    
    // Journal ekranına git
    _navigationService.navigateToJournal(journalId);
  }
  
  Future<void> handleInviteLink(String inviteId) async {
    final invite = await _inviteService.getInviteFromLink(inviteId);
    if (invite == null) {
      // Hata mesajı
      return;
    }
    
    // Invite dialog göster
    _navigationService.showInviteDialog(invite);
  }
  
  // ... diğer handler metodları
}
```

#### Test Senaryoları

1. **Link Oluşturma:**
   - Journal link oluşturuluyor mu?
   - Invite link oluşturuluyor mu?
   - Team link oluşturuluyor mu?
   - Share link oluşturuluyor mu?

2. **Link Açma:**
   - Android'de deep link çalışıyor mu?
   - iOS'te deep link çalışıyor mu?
   - Uygulama kapalıyken açılıyor mu?
   - Uygulama açıkken çalışıyor mu?

3. **Erişim Kontrolü:**
   - Erişim izni olmayan link'ler reddediliyor mu?
   - Expire olmuş link'ler reddediliyor mu?

---

## FAZ 3: Stickers & UX İyileştirmeleri

### 11. Sticker Oluşturma

#### Ne Olduğu
Kullanıcıların kendi sticker'larını oluşturabileceği, yönetebileceği, paylaşabileceği sistem.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: UserSticker Model Oluştur**
- `lib/core/models/user_sticker.dart` oluştur
- StickerType enum (image, emoji, drawing)
- UserSticker entity

**Adım 2: Database Schema**
- `lib/core/database/tables/user_stickers_table.dart` oluştur
- UserStickerDao oluştur

**Adım 3: Sticker Creator Screen**
- Resimden sticker oluşturma
- Emoji'den sticker oluşturma
- Çizimden sticker oluşturma

**Adım 4: Sticker Manager Screen**
- Kullanıcının sticker'larını listeleme
- Sticker silme/düzenleme
- Kategori yönetimi

**Adım 5: Sticker Picker Güncelleme**
- Mevcut sticker picker'a user stickers ekle
- Kategori filtreleme

**Adım 6: Firebase Storage Entegrasyonu**
- Sticker görsellerini Firebase Storage'a yükle
- Download URL'leri sakla

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (sticker providers)

**Database:**
- Drift (SQLite)
- Firestore
- Firebase Storage

**Servisler:**
- StickerService (yeni)
- StorageService (mevcut - güncelleme)

**Paketler:**
- `image_picker` (mevcut)
- `flutter_drawing_board` (yeni - çizim için, opsiyonel)

#### Veri Modelleri

**UserSticker Model:**
```dart
// lib/core/models/user_sticker.dart
enum StickerType {
  image,
  emoji,
  drawing;
}

class UserSticker implements BaseEntity {
  @override
  final String id;
  
  final String userId;
  final String name;
  final String category;
  final StickerType type;
  final String imageUrl; // Firebase Storage URL
  final String? localPath; // Local cache path
  final int width;
  final int height;
  
  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  
  UserSticker({
    String? id,
    required this.userId,
    required this.name,
    this.category = 'Genel',
    required this.type,
    required this.imageUrl,
    this.localPath,
    required this.width,
    required this.height,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  @override
  bool get isDeleted => deletedAt != null;
  
  UserSticker copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    StickerType? type,
    String? imageUrl,
    String? localPath,
    int? width,
    int? height,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return UserSticker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      width: width ?? this.width,
      height: height ?? this.height,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
```

#### API Tasarımları

**StickerService API:**
```dart
// lib/features/stickers/sticker_service.dart
class StickerService {
  // Sticker oluştur
  Future<UserSticker> createSticker({
    required String name,
    required File imageFile,
    String category = 'Genel',
    StickerType type = StickerType.image,
  });
  
  // Kullanıcının sticker'larını al
  Stream<List<UserSticker>> watchUserStickers();
  
  // Kategoriye göre sticker'ları al
  Stream<List<UserSticker>> watchStickersByCategory(String category);
  
  // Sticker sil
  Future<void> deleteSticker(String stickerId);
  
  // Sticker güncelle
  Future<void> updateSticker(UserSticker sticker);
  
  // Kategori oluştur
  Future<void> createCategory(String category);
  
  // Kategorileri al
  Stream<List<String>> watchCategories();
}
```

#### UI/UX Detayları

**Sticker Creator Screen:**
```
Scaffold
  AppBar
    title: "Sticker Oluştur"
  Body
    TabBar
      Tab ("Resim")
      Tab ("Emoji")
      Tab ("Çizim")
    
    TabBarView
      // Resim Tab
      Column
        ElevatedButton ("Resim Seç")
        if (image selected)
          Image (preview)
          TextField (isim)
          DropdownButton (kategori)
          FilledButton ("Oluştur")
      
      // Emoji Tab
      Column
        EmojiPicker (emoji seçimi)
        TextField (isim)
        DropdownButton (kategori)
        FilledButton ("Oluştur")
      
      // Çizim Tab
      Column
        DrawingBoard (çizim alanı)
        TextField (isim)
        DropdownButton (kategori)
        FilledButton ("Oluştur")
```

**Sticker Manager Screen:**
```
Scaffold
  AppBar
    title: "Sticker'larım"
    actions: FAB (yeni sticker)
  Body
    Column
      // Kategori filtreleme
      ChipBar (kategoriler)
      
      // Sticker grid
      GridView
        StickerCard (her sticker için)
          - Thumbnail
          - İsim
          - Kategori
          - PopupMenu (sil, düzenle, paylaş)
```

#### Teknik Detaylar

**Database Tables:**
```dart
// lib/core/database/tables/user_stickers_table.dart
class UserStickers extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('Genel'))();
  TextColumn get type => text()(); // 'image' | 'emoji' | 'drawing'
  TextColumn get imageUrl => text()();
  TextColumn get localPath => text().nullable()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Firestore Yapısı:**
```
user_stickers/{stickerId}
  - id: string
  - userId: string
  - name: string
  - category: string
  - type: string ('image' | 'emoji' | 'drawing')
  - imageUrl: string (Firebase Storage URL)
  - width: number
  - height: number
  - createdAt: timestamp
  - updatedAt: timestamp
  - deletedAt: timestamp?
```

**Firebase Storage Yapısı:**
```
users/{userId}/stickers/{stickerId}.png
```

#### Test Senaryoları

1. **Sticker Oluşturma:**
   - Resimden sticker oluşturuluyor mu?
   - Emoji'den sticker oluşturuluyor mu?
   - Çizimden sticker oluşturuluyor mu?
   - Firebase Storage'a yükleniyor mu?

2. **Sticker Yönetimi:**
   - Sticker'lar listeleniyor mu?
   - Sticker siliniyor mu?
   - Kategori filtreleme çalışıyor mu?

3. **Sticker Kullanımı:**
   - Editor'de kullanılabiliyor mu?
   - Sticker picker'da görünüyor mu?

---

### 12. Journal Kapak Önizlemesi İyileştirme

#### Ne Olduğu
Journal kartlarında daha büyük, detaylı ve etkileşimli kapak önizlemeleri, kapak seçerken canlı önizleme.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Journal Preview Card Güncelleme**
- Daha büyük kapak önizlemesi
- Hover/tap efektleri
- Kapak detayları gösterimi

**Adım 2: Theme Picker Dialog İyileştirme**
- Canlı önizleme (kapak seçilirken)
- Daha fazla kapak tasarımı
- Kategori filtreleme

**Adım 3: Kapak Özelleştirme**
- Renk seçimi
- Gradient seçimi
- Pattern seçimi
- Özel resim yükleme

**Adım 4: Journal Theme Genişletme**
- Yeni kapak stilleri ekle
- Kapak kategorileri

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (journal providers)

**Servisler:**
- JournalTheme (mevcut - genişletilecek)
- ImagePickerService (özel kapak için)

**Paketler:**
- Hiçbir yeni paket gerekmez

#### Veri Modelleri

**Mevcut Journal Model Kullanılacak** - coverStyle field'ı genişletilecek

#### UI/UX Detayları

**Journal Preview Card İyileştirme:**
```
Card
  ClipRRect (borderRadius)
    Stack
      // Kapak görseli (daha büyük)
      Container
        height: 200
        decoration: JournalTheme.getCoverDecoration(coverStyle)
        child: Image veya Gradient veya Pattern
      
      // Overlay (hover/tap)
      Positioned.fill
        Container (opacity animasyonu)
          Icon (edit, büyük)
          Text ("Kapak Değiştir")
  
  // Journal bilgileri
  Padding
    Text (title)
    Text (sayfa sayısı, tarih)
```

**Theme Picker Dialog İyileştirme:**
```
AlertDialog
  title: "Kapak Tasarımı Seç"
  content: Column
    // Canlı önizleme
    Container
      height: 300
      decoration: Seçili kapak stili
      child: Journal preview (büyük)
    
    // Kapak kategorileri
    TabBar
      Tab ("Tümü")
      Tab ("Renkli")
      Tab ("Gradient")
      Tab ("Pattern")
      Tab ("Özel")
    
    // Kapak grid
    GridView
      CoverCard (her kapak için)
        - Thumbnail
        - Tıklanınca seçili olur, önizleme güncellenir
```

#### Teknik Detaylar

**JournalTheme Genişletme:**
```dart
// lib/core/theme/journal_theme.dart güncelleme
class JournalTheme {
  static BoxDecoration getCoverDecoration(String coverStyle) {
    switch (coverStyle) {
      case 'default':
        return BoxDecoration(color: Colors.white);
      case 'gradient_blue':
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade700],
          ),
        );
      // ... daha fazla stil
    }
  }
  
  static List<String> getAvailableCovers() {
    return [
      'default',
      'gradient_blue',
      'gradient_purple',
      'pattern_dots',
      'pattern_lines',
      // ... daha fazla
    ];
  }
}
```

#### Test Senaryoları

1. **Kapak Önizlemesi:**
   - Kapak düzgün görüntüleniyor mu?
   - Canlı önizleme çalışıyor mu?
   - Özel kapak yükleniyor mu?

2. **Kapak Seçimi:**
   - Kapak seçiliyor mu?
   - Journal'a kaydediliyor mu?

---

### 13. Drawer İyileştirmeleri

#### Ne Olduğu
Sol taraftaki drawer navigasyonunu daha kullanıcı dostu, görsel olarak zengin, animasyonlu hale getirme.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Drawer Header Oluştur**
- Profil bilgileri (avatar, isim)
- Hızlı erişim butonları

**Adım 2: Menü Öğeleri İyileştirme**
- İkonlar ve animasyonlar
- Badge gösterimi (bildirim sayısı)
- Aktif sayfa işaretleme

**Adım 3: Drawer Footer**
- Çıkış butonu
- Versiyon bilgisi

**Adım 4: Animasyonlar**
- Drawer açılma/kapanma animasyonu
- Menü öğesi hover/tap animasyonları

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**State Management:**
- Riverpod (navigation, notification providers)

**Servisler:**
- UserService (profil bilgileri)
- NotificationService (badge sayısı için)

**Paketler:**
- Hiçbir yeni paket gerekmez

#### UI/UX Detayları

**Drawer Layout:**
```
Drawer
  // Header
  DrawerHeader
    Column
      CircleAvatar (büyük, profil fotoğrafı)
      Text (kullanıcı ismi)
      Text (email, küçük)
      Row (hızlı erişim butonları)
        IconButton (yeni journal)
        IconButton (arama)
  
  // Menü öğeleri
  ListView
    _DrawerMenuItem ("Anasayfa", Icons.home, badge: 0)
    _DrawerMenuItem ("Journallar", Icons.book, badge: 0)
    _DrawerMenuItem ("Arkadaşlar", Icons.people, badge: 3)
    _DrawerMenuItem ("Bildirimler", Icons.notifications, badge: 5)
    _DrawerMenuItem ("Profil ve Ayarlar", Icons.settings)
    Divider
    _DrawerMenuItem ("Yardım", Icons.help)
    _DrawerMenuItem ("Hakkında", Icons.info)
  
  // Footer
  DrawerFooter
    TextButton ("Çıkış Yap", kırmızı renk)
    Text (versiyon bilgisi, küçük)
```

**Drawer Menu Item:**
```
ListTile
  leading: Stack
    Icon
    if (badge > 0)
      Positioned
        Badge (sayı)
  title: Text
  trailing: if (isActive) Icon (check)
  onTap: () => Navigation
```

#### Teknik Detaylar

**Dosya Yapısı:**
```
lib/core/ui/
  app_drawer.dart (güncelleme)
  drawer_header.dart (yeni)
  drawer_menu_item.dart (yeni)
```

**Animasyonlar:**
- Drawer açılma: SlideTransition
- Menu item hover: ScaleTransition
- Badge: FadeTransition

#### Test Senaryoları

1. **Drawer Açılma:**
   - Drawer açılıyor mu?
   - Animasyon çalışıyor mu?

2. **Navigation:**
   - Menü öğeleri çalışıyor mu?
   - Aktif sayfa işaretleniyor mu?

3. **Badge:**
   - Badge gösteriliyor mu?
   - Sayılar doğru mu?

---

### 14. UX Geliştirmesi Analizi

#### Ne Olduğu
Uygulamanın genel kullanıcı deneyimini analiz etme, iyileştirme önerileri sunma, performans optimizasyonu.

#### Nasıl Yapılacağı (Adım Adım)

**Adım 1: Kullanıcı Akışları Analizi**
- Onboarding akışı
- Journal oluşturma
- Editor kullanımı
- Paylaşım/davet

**Adım 2: Performans Analizi**
- Sayfa yükleme süreleri
- Sync performansı
- Render optimizasyonu
- Memory kullanımı

**Adım 3: Erişilebilirlik İyileştirmeleri**
- Screen reader desteği
- Renk kontrastı
- Font boyutu
- Klavye navigasyonu

**Adım 4: Analytics Entegrasyonu (Opsiyonel)**
- Firebase Analytics
- Crashlytics

#### Hangi Yöntem/Sistem/Servisler Kullanılacak

**Analytics:**
- Firebase Analytics (opsiyonel)
- Firebase Crashlytics (opsiyonel)

**Servisler:**
- AnalyticsService (yeni - opsiyonel)
- AccessibilityHelper (yeni)

**Paketler:**
- `firebase_analytics` (opsiyonel)
- `firebase_crashlytics` (opsiyonel)

#### UI/UX Detayları

**Erişilebilirlik İyileştirmeleri:**
- Tüm widget'lara semantic labels
- Renk kontrastı kontrolü (WCAG AA)
- Font boyutu ayarları (system font scale)
- Klavye navigasyonu (FocusNode yönetimi)

**Performans İyileştirmeleri:**
- Lazy loading (ListView.builder)
- Image caching
- Widget rebuild optimizasyonu
- Memory leak kontrolü

#### Teknik Detaylar

**AccessibilityHelper:**
```dart
// lib/core/accessibility/accessibility_helper.dart
class AccessibilityHelper {
  // Screen reader için label
  static String getSemanticLabel(String key);
  
  // Renk kontrastı kontrolü
  static bool hasGoodContrast(Color foreground, Color background);
  
  // Font scale
  static double getFontScale(BuildContext context);
}
```

**AnalyticsService (Opsiyonel):**
```dart
// lib/core/analytics/analytics_service.dart
class AnalyticsService {
  // Event log
  Future<void> logEvent(String name, Map<String, dynamic>? parameters);
  
  // Screen view
  Future<void> logScreenView(String screenName);
  
  // User property
  Future<void> setUserProperty(String name, String value);
}
```

#### Test Senaryoları

1. **Erişilebilirlik:**
   - Screen reader çalışıyor mu?
   - Renk kontrastı yeterli mi?
   - Font scale çalışıyor mu?

2. **Performans:**
   - Sayfa yükleme hızlı mı?
   - Memory kullanımı normal mi?
   - Animasyonlar akıcı mı?

---

## Sonuç ve Özet

Bu detaylı plan, Journal uygulamasının tüm özelliklerinin implementasyon rehberidir. Her özellik için:

✅ **Ne olduğu** - Detaylı açıklama
✅ **Nasıl yapılacağı** - Adım adım implementasyon
✅ **Hangi yöntem/sistem/servisler** - Kullanılacak teknolojiler
✅ **Veri modelleri** - Tam kod örnekleri
✅ **API tasarımları** - Servis metodları
✅ **UI/UX detayları** - Layout ve tasarım
✅ **Teknik detaylar** - Kod yapısı ve implementasyon
✅ **Test senaryoları** - Test edilmesi gerekenler

**Hiçbir belirsizlik kalmamalı** - her karar mekanizması açıkça belirtilmiştir.

---

## Uygulama Öncelik Sırası

### Faz 1: Kritik İyileştirmeler (1-2 Hafta)
1. ✅ Profil ve Ayarlar Birleştirme
2. ✅ Renk Temaları Seçici UI
3. ✅ Main.dart Tema Entegrasyonu
4. ✅ Resim Döndürme UI
5. ✅ Ses Kaydı UI İyileştirme
6. ✅ Geri Butonu İyileştirme

### Faz 2: Collaboration & Sharing (2-3 Hafta)
7. ✅ Ekip Sistemi
8. ✅ Davet Sistemi
9. ✅ Paylaş Sistemi
10. ✅ Link Sistemi

### Faz 3: Stickers & UX (1-2 Hafta)
11. ✅ Sticker Oluşturma
12. ✅ Journal Kapak Önizlemesi İyileştirme
13. ✅ Drawer İyileştirmeleri
14. ✅ UX Geliştirmesi Analizi

---

## Notlar

- Tüm yeni özellikler mevcut offline-first mimarisini koruyacak
- Firebase Security Rules güncellenecek (team, invite, share için)
- Tüm değişiklikler geriye dönük uyumlu olacak
- Migration planı hazırlanacak (database schema değişiklikleri için)
- Her özellik için unit test ve integration test yazılacak
- Code review yapılacak
- Dokümantasyon güncellenecek