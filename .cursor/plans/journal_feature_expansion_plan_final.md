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
