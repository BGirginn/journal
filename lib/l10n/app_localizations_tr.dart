// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Journal V2';

  @override
  String get profileSettingsTitle => 'Profil ve Ayarlar';

  @override
  String get settingsTitle => 'AYARLAR';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get themeModeTitle => 'Tema Modu';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get accountTitle => 'Hesap';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signOutConfirmTitle => 'Çıkış Yap';

  @override
  String get signOutConfirmMessage => 'Çıkış yapmak istediğinize emin misiniz?';

  @override
  String get cancel => 'İptal';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get version => 'Sürüm';

  @override
  String get licenses => 'Lisanslar';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get errorPrefix => 'Hata';

  @override
  String get copyUsernameSuccess => 'Kullanıcı adı kopyalandı';

  @override
  String get copyUsernameTooltip => 'Kullanıcı Adını Kopyala';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem Varsayılanı';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get onboardingTitleCaptureMemories => 'Anılarınızı Kaydedin';

  @override
  String get onboardingDescCaptureMemories =>
      'Metin, fotoğraf, video ve ses kayıtları ile özel günlüğünüzü oluşturun. Her anı benzersiz bir sayfada yaşatın.';

  @override
  String get onboardingTitleShareTogether => 'Birlikte Paylaşın';

  @override
  String get onboardingDescShareTogether =>
      'Takımlar oluşturun, arkadaşlarınızı davet edin ve birlikte ortak günlükler tutun. Anılar paylaşıldığında daha değerli olur.';

  @override
  String get onboardingTitlePersonalize => 'Kişiselleştirin';

  @override
  String get onboardingDescPersonalize =>
      'Nostaljik temalar, stickerlar ve çizim araçlarıyla günlüğünüzü tamamen kişiselleştirin.';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingGetStarted => 'Başlayalım!';

  @override
  String get loginTagline => 'Anılarını modern bir dokunuşla sakla';

  @override
  String get loginProfileChecking => 'Profil kontrol ediliyor...';

  @override
  String get loginGoogleSignIn => 'Gmail ile Giriş Yap';

  @override
  String get loginAppleSignIn => 'Apple ile Giriş Yap';

  @override
  String get loginAccountExistsWithGoogleTitle => 'Google ile Devam Et';

  @override
  String get loginAccountExistsWithGoogleMessage =>
      'Bu e-posta Google hesabınla kayıtlı.';

  @override
  String get loginContinueWithGoogle => 'Google ile Devam Et';

  @override
  String get loginCanLinkAppleLater =>
      'Google ile giriş yaptıktan sonra Apple hesabını Profil ayarlarından bağlayabilirsin.';

  @override
  String get loginAppleIOSOnly =>
      'Apple ile giriş sadece iOS\'ta kullanılabilir.';

  @override
  String get loginAppleMissingToken => 'Apple kimlik tokeni alınamadı.';

  @override
  String get loginAppleInvalidCredential => 'Apple kimlik bilgisi geçersiz.';

  @override
  String get loginAppleProviderNotEnabled =>
      'Firebase Authentication içinde Apple sağlayıcısı etkin değil.';

  @override
  String get loginAppleAuthorizationFailed =>
      'Apple yetkilendirmesi başarısız. Cihaz/simülatörde Apple ID oturumunu kontrol edin.';

  @override
  String get loginAppleCredentialRequestFailed =>
      'Apple kimlik bilgisi alınamadı. Lütfen tekrar deneyin.';

  @override
  String get loginAppleFlowTimeout =>
      'Apple giriş penceresi yanıt vermedi. Simülatörde Apple hesabından çıkış yapıp tekrar deneyin.';

  @override
  String get loginGoogleConfigError => 'Google giriş yapılandırması hatalı.';

  @override
  String get loginFirebaseUnavailable => 'Firebase başlatılamadı.';

  @override
  String get linkedAccountsTitle => 'Bağlı Hesaplar';

  @override
  String get linkedProviderGoogle => 'Google';

  @override
  String get linkedProviderApple => 'Apple';

  @override
  String get linkedStatusConnected => 'Bağlı';

  @override
  String get linkedStatusNotConnected => 'Bağlı değil';

  @override
  String get linkAppleAction => 'Apple Hesabını Bağla';

  @override
  String get linkAppleSuccess => 'Apple hesabı başarıyla bağlandı.';

  @override
  String get linkAppleUnsupported =>
      'Apple hesabı bağlama sadece iOS\'ta kullanılabilir.';

  @override
  String get linkAppleNeedsRecentLogin =>
      'Apple bağlamak için lütfen tekrar giriş yapın.';

  @override
  String get linkAppleAlreadyLinked => 'Apple hesabı zaten bağlı.';

  @override
  String get linkAppleCredentialInUse =>
      'Bu Apple hesabı başka bir kullanıcıya bağlı.';

  @override
  String editorPageTitle(int pageNumber) {
    return 'Sayfa $pageNumber';
  }

  @override
  String get editorTooltipShare => 'Paylaş';

  @override
  String get editorTooltipPreview => 'Önizle';

  @override
  String get editorTooltipSave => 'Kaydet';

  @override
  String get editorPdfPreparing => 'PDF hazırlanıyor...';

  @override
  String get editorExportPdf => 'PDF Olarak Dışa Aktar';

  @override
  String editorSaveLocalCloudFail(Object error) {
    return 'Yerel kaydedildi, bulut senkronizasyonu başarısız: $error';
  }

  @override
  String get editorSaved => 'Kaydedildi ✓';

  @override
  String get editorToolSelect => 'Seç';

  @override
  String get editorToolText => 'Metin';

  @override
  String get editorToolDraw => 'Çiz';

  @override
  String get editorToolErase => 'Silgi';

  @override
  String get editorToolMedia => 'Medya';

  @override
  String get editorToolSticker => 'Sticker';

  @override
  String get editorToolTag => 'Etiket';

  @override
  String get editorToolZoomReset => '1x';

  @override
  String get editorToolRotate => 'Döndür';

  @override
  String get editorToolFrame => 'Çerçeve';

  @override
  String get editorToolDelete => 'Sil';

  @override
  String get editorMediaAdd => 'Medya Ekle';

  @override
  String get editorMediaImage => 'Resim';

  @override
  String get editorMediaImageSubtitle => 'Galeriden veya kameradan';

  @override
  String get editorMediaVideo => 'Video';

  @override
  String get editorMediaVideoSubtitle => 'Video kaydet veya seç';

  @override
  String get editorMediaAudio => 'Ses';

  @override
  String get editorMediaAudioSubtitle => 'Ses kaydı yap';

  @override
  String get editorMediaDrawing => 'Çizim';

  @override
  String get editorMediaDrawingSubtitle => 'Serbest çizim yapın';

  @override
  String get editorVideoFromGallery => 'Galeriden Seç';

  @override
  String get editorVideoFromCamera => 'Video Çek';

  @override
  String get editorPageTags => 'Sayfa Etiketleri';

  @override
  String get editorEraserSize => 'Silgi boyutu';

  @override
  String get editorTextPlaceholder => 'Yazı ekle...';

  @override
  String get editorMicPermissionRequired =>
      'Mikrofon izni gerekli. Lütfen ayarlardan izin verin.';

  @override
  String editorRecordError(Object error) {
    return 'Kayıt hatası: $error';
  }

  @override
  String get editorFrameSelect => 'Çerçeve Seçin';

  @override
  String get editorFrameNone => 'Yok';

  @override
  String get editorFrameRound => 'Yuvarlak';

  @override
  String get editorFrameRounded => 'Köşeli';

  @override
  String get editorFramePolaroid => 'Polaroid';

  @override
  String get editorFrameTape => 'Bant';

  @override
  String get editorFrameShadow => 'Gölge';

  @override
  String get editorFrameFilm => 'Film';

  @override
  String get editorFrameStacked => 'Yığın';

  @override
  String get editorFrameSticker => 'Etiket';

  @override
  String get editorFrameBorder => 'Kenarlık';

  @override
  String get editorFrameGradient => 'Gradyan';

  @override
  String get editorFrameVintage => 'Nostalji';

  @override
  String get editorFrameLayered => 'Katman';

  @override
  String get editorFrameTapeCorner => 'Bant Köşe';

  @override
  String get editorFramePolaroidClassic => 'Polaroid Klasik';

  @override
  String get editorFrameVintageEdge => 'Vintage Kenar';

  @override
  String get editorDeleteBlockTitle => 'Bloğu Sil';

  @override
  String get editorDeleteBlockMessage =>
      'Bu bloğu silmek istediğinizden emin misiniz?';

  @override
  String get editorDelete => 'Sil';

  @override
  String get editorRotateImageTitle => 'Resmi Döndür';

  @override
  String editorCurrentAngle(int angle) {
    return 'Mevcut açı: $angle°';
  }

  @override
  String get editorApply => 'Uygula';

  @override
  String get editorUnsavedTitle => 'Kaydedilmemiş Değişiklikler';

  @override
  String get editorUnsavedMessage =>
      'Kaydedilmemiş değişiklikleriniz var. Ne yapmak istersiniz?';

  @override
  String get editorExitWithoutSave => 'Çık (Kaydetme)';

  @override
  String get editorSaveAndExit => 'Kaydet ve Çık';

  @override
  String editorErrorWithMessage(Object error) {
    return 'Hata: $error';
  }

  @override
  String get libraryGreetingMorning => 'Gunaydin';

  @override
  String get libraryGreetingAfternoon => 'Iyi gunler';

  @override
  String get libraryGreetingEvening => 'Iyi aksamlar';

  @override
  String get libraryHeaderYourJournals => 'Gunluklerin';

  @override
  String get librarySectionSubtitle => 'Kaldigin yerden devam et';

  @override
  String get libraryEmptyTitle => 'Ilk gunlugunu baslat';

  @override
  String get libraryEmptySubtitle =>
      'Metin, fotograf, ses ve cizim ile anilarini kaydet.';

  @override
  String get libraryEmptyCta => 'Gunluk Olustur';

  @override
  String get libraryCreateTitle => 'Yeni Gunluk';

  @override
  String get libraryCreateHint => 'Orn: Seyahat Notlarim';

  @override
  String get libraryCreateAction => 'Olustur';

  @override
  String get libraryActionPreview => 'Canli Onizleme';

  @override
  String get libraryActionCustomizeCover => 'Kapagi Ozellestir';

  @override
  String get libraryActionRename => 'Yeniden Adlandir';

  @override
  String get libraryActionDelete => 'Sil';

  @override
  String get libraryPreviewTitle => 'Canli Gunluk Onizlemesi';

  @override
  String get libraryRenameTitle => 'Gunlugu Yeniden Adlandir';

  @override
  String get libraryRenameHint => 'Gunluk adi';

  @override
  String get libraryDeleteTitle => 'Gunlugu Sil';

  @override
  String libraryDeleteMessage(Object journalTitle) {
    return '\"$journalTitle\" gunlugunu silmek istediginize emin misiniz?';
  }

  @override
  String get libraryThemePickerTitle => 'Tema Secin';

  @override
  String get libraryCoverCustomizeTitle => 'Kapak Ozellestir';

  @override
  String get libraryThemeTab => 'Temalar';

  @override
  String get libraryPhotoTab => 'Fotograf';

  @override
  String get libraryUploading => 'Yukleniyor...';

  @override
  String get librarySelectFromGallery => 'Galeriden Sec';

  @override
  String get libraryCustomCoverHint => 'Ozel kapak fotografi yukleyin';

  @override
  String libraryUploadError(Object error) {
    return 'Yukleme hatasi: $error';
  }
}
