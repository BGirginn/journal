// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Journal V2';

  @override
  String get profileSettingsTitle => 'Profile & Settings';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeModeTitle => 'Theme Mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accountTitle => 'Account';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get aboutTitle => 'About';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licenses';

  @override
  String get loading => 'Loading...';

  @override
  String get errorPrefix => 'Error';

  @override
  String get copyUsernameSuccess => 'Username copied';

  @override
  String get copyUsernameTooltip => 'Copy Username';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageEnglish => 'English';

  @override
  String get onboardingTitleCaptureMemories => 'Capture Your Memories';

  @override
  String get onboardingDescCaptureMemories =>
      'Build your personal journal with text, photo, video, and audio. Keep every memory alive on a unique page.';

  @override
  String get onboardingTitleShareTogether => 'Share Together';

  @override
  String get onboardingDescShareTogether =>
      'Create teams, invite friends, and keep shared journals together. Memories become more meaningful when shared.';

  @override
  String get onboardingTitlePersonalize => 'Personalize It';

  @override
  String get onboardingDescPersonalize =>
      'Make your journal your own with nostalgic themes, stickers, and drawing tools.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get loginTagline => 'Preserve your memories with a modern touch';

  @override
  String get loginProfileChecking => 'Checking profile...';

  @override
  String get loginGoogleSignIn => 'Continue with Gmail';

  @override
  String get loginAppleSignIn => 'Sign in with Apple';

  @override
  String get loginAccountExistsWithGoogleTitle => 'Use Google to Continue';

  @override
  String get loginAccountExistsWithGoogleMessage =>
      'This email is already registered with your Google account.';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginCanLinkAppleLater =>
      'After signing in with Google, you can link Apple from Profile settings.';

  @override
  String get loginAppleIOSOnly => 'Apple Sign-In is available only on iOS.';

  @override
  String get loginAppleMissingToken =>
      'Apple identity token could not be retrieved.';

  @override
  String get loginAppleInvalidCredential => 'Apple credential is invalid.';

  @override
  String get loginAppleProviderNotEnabled =>
      'Apple Sign-In is not enabled in Firebase Auth provider settings.';

  @override
  String get loginAppleAuthorizationFailed =>
      'Apple authorization failed. Check Apple ID session on device/simulator.';

  @override
  String get loginAppleCredentialRequestFailed =>
      'Apple credential request failed. Please try again.';

  @override
  String get loginAppleFlowTimeout =>
      'Apple sign-in dialog did not respond. Sign out/in Apple ID on simulator and try again.';

  @override
  String get loginGoogleConfigError =>
      'Google Sign-In configuration is invalid.';

  @override
  String get loginFirebaseUnavailable => 'Firebase could not be initialized.';

  @override
  String get linkedAccountsTitle => 'Linked Accounts';

  @override
  String get linkedProviderGoogle => 'Google';

  @override
  String get linkedProviderApple => 'Apple';

  @override
  String get linkedStatusConnected => 'Connected';

  @override
  String get linkedStatusNotConnected => 'Not connected';

  @override
  String get linkAppleAction => 'Link Apple Account';

  @override
  String get linkAppleSuccess => 'Apple account linked successfully.';

  @override
  String get linkAppleUnsupported =>
      'Apple account linking is only available on iOS.';

  @override
  String get linkAppleNeedsRecentLogin =>
      'Please sign in again before linking Apple.';

  @override
  String get linkAppleAlreadyLinked => 'Apple account is already linked.';

  @override
  String get linkAppleCredentialInUse =>
      'This Apple account is linked to another user.';

  @override
  String editorPageTitle(int pageNumber) {
    return 'Page $pageNumber';
  }

  @override
  String get editorTooltipShare => 'Share';

  @override
  String get editorTooltipPreview => 'Preview';

  @override
  String get editorTooltipSave => 'Save';

  @override
  String get editorPdfPreparing => 'Preparing PDF...';

  @override
  String get editorExportPdf => 'Export as PDF';

  @override
  String editorSaveLocalCloudFail(Object error) {
    return 'Saved locally, cloud sync failed: $error';
  }

  @override
  String get editorSaved => 'Saved ✓';

  @override
  String get editorToolSelect => 'Select';

  @override
  String get editorToolText => 'Text';

  @override
  String get editorToolDraw => 'Draw';

  @override
  String get editorToolErase => 'Eraser';

  @override
  String get editorToolMedia => 'Media';

  @override
  String get editorToolSticker => 'Sticker';

  @override
  String get editorToolTag => 'Tag';

  @override
  String get editorToolZoomReset => '1x';

  @override
  String get editorToolRotate => 'Rotate';

  @override
  String get editorToolFrame => 'Frame';

  @override
  String get editorToolDelete => 'Delete';

  @override
  String get editorMediaAdd => 'Add Media';

  @override
  String get editorMediaImage => 'Image';

  @override
  String get editorMediaImageSubtitle => 'Choose from gallery or camera';

  @override
  String get editorMediaVideo => 'Video';

  @override
  String get editorMediaVideoSubtitle => 'Record or choose a video';

  @override
  String get editorMediaAudio => 'Audio';

  @override
  String get editorMediaAudioSubtitle => 'Record voice audio';

  @override
  String get editorMediaDrawing => 'Drawing';

  @override
  String get editorMediaDrawingSubtitle => 'Freehand drawing';

  @override
  String get editorVideoFromGallery => 'Select from Gallery';

  @override
  String get editorVideoFromCamera => 'Record Video';

  @override
  String get editorPageTags => 'Page Tags';

  @override
  String get editorEraserSize => 'Eraser size';

  @override
  String get editorTextPlaceholder => 'Add text...';

  @override
  String get editorMicPermissionRequired =>
      'Microphone permission is required. Please allow it in settings.';

  @override
  String editorRecordError(Object error) {
    return 'Recording error: $error';
  }

  @override
  String get editorFrameSelect => 'Select Frame';

  @override
  String get editorFrameNone => 'None';

  @override
  String get editorFrameRound => 'Round';

  @override
  String get editorFrameRounded => 'Rounded';

  @override
  String get editorFramePolaroid => 'Polaroid';

  @override
  String get editorFrameTape => 'Tape';

  @override
  String get editorFrameShadow => 'Shadow';

  @override
  String get editorFrameFilm => 'Film';

  @override
  String get editorFrameStacked => 'Stacked';

  @override
  String get editorFrameSticker => 'Sticker';

  @override
  String get editorFrameBorder => 'Border';

  @override
  String get editorFrameGradient => 'Gradient';

  @override
  String get editorFrameVintage => 'Vintage';

  @override
  String get editorFrameLayered => 'Layered';

  @override
  String get editorFrameTapeCorner => 'Tape Corner';

  @override
  String get editorFramePolaroidClassic => 'Classic Polaroid';

  @override
  String get editorFrameVintageEdge => 'Vintage Edge';

  @override
  String get editorDeleteBlockTitle => 'Delete Block';

  @override
  String get editorDeleteBlockMessage =>
      'Are you sure you want to delete this block?';

  @override
  String get editorDelete => 'Delete';

  @override
  String get editorRotateImageTitle => 'Rotate Image';

  @override
  String editorCurrentAngle(int angle) {
    return 'Current angle: $angle°';
  }

  @override
  String get editorApply => 'Apply';

  @override
  String get editorUnsavedTitle => 'Unsaved Changes';

  @override
  String get editorUnsavedMessage =>
      'You have unsaved changes. What would you like to do?';

  @override
  String get editorExitWithoutSave => 'Exit (Don\'t Save)';

  @override
  String get editorSaveAndExit => 'Save and Exit';

  @override
  String editorErrorWithMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get libraryGreetingMorning => 'Good morning';

  @override
  String get libraryGreetingAfternoon => 'Good afternoon';

  @override
  String get libraryGreetingEvening => 'Good evening';

  @override
  String get libraryHeaderYourJournals => 'Your Journals';

  @override
  String get librarySectionSubtitle => 'Pick up where you left off';

  @override
  String get libraryEmptyTitle => 'Start your first journal';

  @override
  String get libraryEmptySubtitle =>
      'Capture moments with text, photos, audio, and drawings.';

  @override
  String get libraryEmptyCta => 'Create Journal';

  @override
  String get libraryCreateTitle => 'New Journal';

  @override
  String get libraryCreateHint => 'Example: Travel Notes';

  @override
  String get libraryCreateAction => 'Create';

  @override
  String get libraryActionPreview => 'Live Preview';

  @override
  String get libraryActionCustomizeCover => 'Customize Cover';

  @override
  String get libraryActionRename => 'Rename';

  @override
  String get libraryActionDelete => 'Delete';

  @override
  String get libraryPreviewTitle => 'Live Journal Preview';

  @override
  String get libraryRenameTitle => 'Rename Journal';

  @override
  String get libraryRenameHint => 'Journal title';

  @override
  String get libraryDeleteTitle => 'Delete Journal';

  @override
  String libraryDeleteMessage(Object journalTitle) {
    return 'Are you sure you want to delete \"$journalTitle\"?';
  }

  @override
  String get libraryThemePickerTitle => 'Choose Theme';

  @override
  String get libraryCoverCustomizeTitle => 'Customize Cover';

  @override
  String get libraryThemeTab => 'Themes';

  @override
  String get libraryPhotoTab => 'Photo';

  @override
  String get libraryUploading => 'Uploading...';

  @override
  String get librarySelectFromGallery => 'Select From Gallery';

  @override
  String get libraryCustomCoverHint => 'Upload a custom cover photo';

  @override
  String libraryUploadError(Object error) {
    return 'Upload failed: $error';
  }
}
