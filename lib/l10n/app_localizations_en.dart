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
  String get onboardingDescCaptureMemories => 'Build your personal journal with text, photo, video, and audio. Keep every memory alive on a unique page.';

  @override
  String get onboardingTitleShareTogether => 'Share Together';

  @override
  String get onboardingDescShareTogether => 'Create teams, invite friends, and keep shared journals together. Memories become more meaningful when shared.';

  @override
  String get onboardingTitlePersonalize => 'Personalize It';

  @override
  String get onboardingDescPersonalize => 'Make your journal your own with nostalgic themes, stickers, and drawing tools.';

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
  String get loginGoogleSignIn => 'Continue with Google';

  @override
  String get loginAppleSignIn => 'Sign in with Apple';

  @override
  String get loginAccountExistsWithGoogleTitle => 'Use Google to Continue';

  @override
  String get loginAccountExistsWithGoogleMessage => 'This email is already registered with your Google account.';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginCanLinkAppleLater => 'After signing in with Google, you can link Apple from Profile settings.';

  @override
  String get loginAppleIOSOnly => 'Apple Sign-In is available only on iOS.';

  @override
  String get loginAppleMissingToken => 'Apple identity token could not be retrieved.';

  @override
  String get loginAppleInvalidCredential => 'Apple credential is invalid.';

  @override
  String get loginGoogleConfigError => 'Google Sign-In configuration is invalid.';

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
  String get linkAppleUnsupported => 'Apple account linking is only available on iOS.';

  @override
  String get linkAppleNeedsRecentLogin => 'Please sign in again before linking Apple.';

  @override
  String get linkAppleAlreadyLinked => 'Apple account is already linked.';

  @override
  String get linkAppleCredentialInUse => 'This Apple account is linked to another user.';

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
  String get editorMicPermissionRequired => 'Microphone permission is required. Please allow it in settings.';

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
  String get editorDeleteBlockMessage => 'Are you sure you want to delete this block?';

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
  String get editorUnsavedMessage => 'You have unsaved changes. What would you like to do?';

  @override
  String get editorExitWithoutSave => 'Exit (Don\'t Save)';

  @override
  String get editorSaveAndExit => 'Save and Exit';

  @override
  String editorErrorWithMessage(Object error) {
    return 'Error: $error';
  }
}
