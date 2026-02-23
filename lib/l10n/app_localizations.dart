import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal V2'**
  String get appTitle;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettingsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @copyUsernameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Username copied'**
  String get copyUsernameSuccess;

  /// No description provided for @copyUsernameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Username'**
  String get copyUsernameTooltip;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @onboardingTitleCaptureMemories.
  ///
  /// In en, this message translates to:
  /// **'Capture Your Memories'**
  String get onboardingTitleCaptureMemories;

  /// No description provided for @onboardingDescCaptureMemories.
  ///
  /// In en, this message translates to:
  /// **'Build your personal journal with text, photo, video, and audio. Keep every memory alive on a unique page.'**
  String get onboardingDescCaptureMemories;

  /// No description provided for @onboardingTitleShareTogether.
  ///
  /// In en, this message translates to:
  /// **'Share Together'**
  String get onboardingTitleShareTogether;

  /// No description provided for @onboardingDescShareTogether.
  ///
  /// In en, this message translates to:
  /// **'Create teams, invite friends, and keep shared journals together. Memories become more meaningful when shared.'**
  String get onboardingDescShareTogether;

  /// No description provided for @onboardingTitlePersonalize.
  ///
  /// In en, this message translates to:
  /// **'Personalize It'**
  String get onboardingTitlePersonalize;

  /// No description provided for @onboardingDescPersonalize.
  ///
  /// In en, this message translates to:
  /// **'Make your journal your own with nostalgic themes, stickers, and drawing tools.'**
  String get onboardingDescPersonalize;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Preserve your memories with a modern touch'**
  String get loginTagline;

  /// No description provided for @loginProfileChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking profile...'**
  String get loginProfileChecking;

  /// No description provided for @loginGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Gmail'**
  String get loginGoogleSignIn;

  /// No description provided for @loginAppleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get loginAppleSignIn;

  /// No description provided for @loginAccountExistsWithGoogleTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Google to Continue'**
  String get loginAccountExistsWithGoogleTitle;

  /// No description provided for @loginAccountExistsWithGoogleMessage.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered with your Google account.'**
  String get loginAccountExistsWithGoogleMessage;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginCanLinkAppleLater.
  ///
  /// In en, this message translates to:
  /// **'After signing in with Google, you can link Apple from Profile settings.'**
  String get loginCanLinkAppleLater;

  /// No description provided for @loginAppleIOSOnly.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In is available only on iOS.'**
  String get loginAppleIOSOnly;

  /// No description provided for @loginAppleMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Apple identity token could not be retrieved.'**
  String get loginAppleMissingToken;

  /// No description provided for @loginAppleInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Apple credential is invalid.'**
  String get loginAppleInvalidCredential;

  /// No description provided for @loginAppleProviderNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In is not enabled in Firebase Auth provider settings.'**
  String get loginAppleProviderNotEnabled;

  /// No description provided for @loginAppleAuthorizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple authorization failed. Check Apple ID session on device/simulator.'**
  String get loginAppleAuthorizationFailed;

  /// No description provided for @loginAppleCredentialRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple credential request failed. Please try again.'**
  String get loginAppleCredentialRequestFailed;

  /// No description provided for @loginAppleFlowTimeout.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in dialog did not respond. Sign out/in Apple ID on simulator and try again.'**
  String get loginAppleFlowTimeout;

  /// No description provided for @loginGoogleConfigError.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In configuration is invalid.'**
  String get loginGoogleConfigError;

  /// No description provided for @loginFirebaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Firebase could not be initialized.'**
  String get loginFirebaseUnavailable;

  /// No description provided for @linkedAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get linkedAccountsTitle;

  /// No description provided for @linkedProviderGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get linkedProviderGoogle;

  /// No description provided for @linkedProviderApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get linkedProviderApple;

  /// No description provided for @linkedStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get linkedStatusConnected;

  /// No description provided for @linkedStatusNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get linkedStatusNotConnected;

  /// No description provided for @linkAppleAction.
  ///
  /// In en, this message translates to:
  /// **'Link Apple Account'**
  String get linkAppleAction;

  /// No description provided for @linkAppleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Apple account linked successfully.'**
  String get linkAppleSuccess;

  /// No description provided for @linkAppleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Apple account linking is only available on iOS.'**
  String get linkAppleUnsupported;

  /// No description provided for @linkAppleNeedsRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again before linking Apple.'**
  String get linkAppleNeedsRecentLogin;

  /// No description provided for @linkAppleAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'Apple account is already linked.'**
  String get linkAppleAlreadyLinked;

  /// No description provided for @linkAppleCredentialInUse.
  ///
  /// In en, this message translates to:
  /// **'This Apple account is linked to another user.'**
  String get linkAppleCredentialInUse;

  /// No description provided for @editorPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Page {pageNumber}'**
  String editorPageTitle(int pageNumber);

  /// No description provided for @editorTooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get editorTooltipShare;

  /// No description provided for @editorTooltipPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorTooltipPreview;

  /// No description provided for @editorTooltipSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorTooltipSave;

  /// No description provided for @editorPdfPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF...'**
  String get editorPdfPreparing;

  /// No description provided for @editorExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get editorExportPdf;

  /// No description provided for @editorSaveLocalCloudFail.
  ///
  /// In en, this message translates to:
  /// **'Saved locally, cloud sync failed: {error}'**
  String editorSaveLocalCloudFail(Object error);

  /// No description provided for @editorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved ✓'**
  String get editorSaved;

  /// No description provided for @editorToolSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get editorToolSelect;

  /// No description provided for @editorToolText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get editorToolText;

  /// No description provided for @editorToolDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get editorToolDraw;

  /// No description provided for @editorToolErase.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get editorToolErase;

  /// No description provided for @editorToolMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get editorToolMedia;

  /// No description provided for @editorToolSticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get editorToolSticker;

  /// No description provided for @editorToolTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get editorToolTag;

  /// No description provided for @editorToolZoomReset.
  ///
  /// In en, this message translates to:
  /// **'1x'**
  String get editorToolZoomReset;

  /// No description provided for @editorToolRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get editorToolRotate;

  /// No description provided for @editorToolFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get editorToolFrame;

  /// No description provided for @editorToolDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get editorToolDelete;

  /// No description provided for @editorMediaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Media'**
  String get editorMediaAdd;

  /// No description provided for @editorMediaImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get editorMediaImage;

  /// No description provided for @editorMediaImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery or camera'**
  String get editorMediaImageSubtitle;

  /// No description provided for @editorMediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get editorMediaVideo;

  /// No description provided for @editorMediaVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record or choose a video'**
  String get editorMediaVideoSubtitle;

  /// No description provided for @editorMediaAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get editorMediaAudio;

  /// No description provided for @editorMediaAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record voice audio'**
  String get editorMediaAudioSubtitle;

  /// No description provided for @editorMediaDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get editorMediaDrawing;

  /// No description provided for @editorMediaDrawingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Freehand drawing'**
  String get editorMediaDrawingSubtitle;

  /// No description provided for @editorVideoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get editorVideoFromGallery;

  /// No description provided for @editorVideoFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get editorVideoFromCamera;

  /// No description provided for @editorPageTags.
  ///
  /// In en, this message translates to:
  /// **'Page Tags'**
  String get editorPageTags;

  /// No description provided for @editorEraserSize.
  ///
  /// In en, this message translates to:
  /// **'Eraser size'**
  String get editorEraserSize;

  /// No description provided for @editorTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add text...'**
  String get editorTextPlaceholder;

  /// No description provided for @editorMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required. Please allow it in settings.'**
  String get editorMicPermissionRequired;

  /// No description provided for @editorRecordError.
  ///
  /// In en, this message translates to:
  /// **'Recording error: {error}'**
  String editorRecordError(Object error);

  /// No description provided for @editorFrameSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Frame'**
  String get editorFrameSelect;

  /// No description provided for @editorFrameNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get editorFrameNone;

  /// No description provided for @editorFrameRound.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get editorFrameRound;

  /// No description provided for @editorFrameRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get editorFrameRounded;

  /// No description provided for @editorFramePolaroid.
  ///
  /// In en, this message translates to:
  /// **'Polaroid'**
  String get editorFramePolaroid;

  /// No description provided for @editorFrameTape.
  ///
  /// In en, this message translates to:
  /// **'Tape'**
  String get editorFrameTape;

  /// No description provided for @editorFrameShadow.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get editorFrameShadow;

  /// No description provided for @editorFrameFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get editorFrameFilm;

  /// No description provided for @editorFrameStacked.
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get editorFrameStacked;

  /// No description provided for @editorFrameSticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get editorFrameSticker;

  /// No description provided for @editorFrameBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get editorFrameBorder;

  /// No description provided for @editorFrameGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get editorFrameGradient;

  /// No description provided for @editorFrameVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get editorFrameVintage;

  /// No description provided for @editorFrameLayered.
  ///
  /// In en, this message translates to:
  /// **'Layered'**
  String get editorFrameLayered;

  /// No description provided for @editorFrameTapeCorner.
  ///
  /// In en, this message translates to:
  /// **'Tape Corner'**
  String get editorFrameTapeCorner;

  /// No description provided for @editorFramePolaroidClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic Polaroid'**
  String get editorFramePolaroidClassic;

  /// No description provided for @editorFrameVintageEdge.
  ///
  /// In en, this message translates to:
  /// **'Vintage Edge'**
  String get editorFrameVintageEdge;

  /// No description provided for @editorDeleteBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Block'**
  String get editorDeleteBlockTitle;

  /// No description provided for @editorDeleteBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this block?'**
  String get editorDeleteBlockMessage;

  /// No description provided for @editorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get editorDelete;

  /// No description provided for @editorRotateImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Rotate Image'**
  String get editorRotateImageTitle;

  /// No description provided for @editorCurrentAngle.
  ///
  /// In en, this message translates to:
  /// **'Current angle: {angle}°'**
  String editorCurrentAngle(int angle);

  /// No description provided for @editorApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get editorApply;

  /// No description provided for @editorUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get editorUnsavedTitle;

  /// No description provided for @editorUnsavedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. What would you like to do?'**
  String get editorUnsavedMessage;

  /// No description provided for @editorExitWithoutSave.
  ///
  /// In en, this message translates to:
  /// **'Exit (Don\'t Save)'**
  String get editorExitWithoutSave;

  /// No description provided for @editorSaveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save and Exit'**
  String get editorSaveAndExit;

  /// No description provided for @editorErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String editorErrorWithMessage(Object error);

  /// No description provided for @libraryGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get libraryGreetingMorning;

  /// No description provided for @libraryGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get libraryGreetingAfternoon;

  /// No description provided for @libraryGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get libraryGreetingEvening;

  /// No description provided for @libraryHeaderYourJournals.
  ///
  /// In en, this message translates to:
  /// **'Your Journals'**
  String get libraryHeaderYourJournals;

  /// No description provided for @librarySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get librarySectionSubtitle;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your first journal'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture moments with text, photos, audio, and drawings.'**
  String get libraryEmptySubtitle;

  /// No description provided for @libraryEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Create Journal'**
  String get libraryEmptyCta;

  /// No description provided for @libraryCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Journal'**
  String get libraryCreateTitle;

  /// No description provided for @libraryCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Travel Notes'**
  String get libraryCreateHint;

  /// No description provided for @libraryCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get libraryCreateAction;

  /// No description provided for @libraryActionPreview.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get libraryActionPreview;

  /// No description provided for @libraryActionCustomizeCover.
  ///
  /// In en, this message translates to:
  /// **'Customize Cover'**
  String get libraryActionCustomizeCover;

  /// No description provided for @libraryActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get libraryActionRename;

  /// No description provided for @libraryActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get libraryActionDelete;

  /// No description provided for @libraryPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Journal Preview'**
  String get libraryPreviewTitle;

  /// No description provided for @libraryRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Journal'**
  String get libraryRenameTitle;

  /// No description provided for @libraryRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Journal title'**
  String get libraryRenameHint;

  /// No description provided for @libraryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Journal'**
  String get libraryDeleteTitle;

  /// No description provided for @libraryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{journalTitle}\"?'**
  String libraryDeleteMessage(Object journalTitle);

  /// No description provided for @libraryThemePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get libraryThemePickerTitle;

  /// No description provided for @libraryCoverCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Cover'**
  String get libraryCoverCustomizeTitle;

  /// No description provided for @libraryThemeTab.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get libraryThemeTab;

  /// No description provided for @libraryPhotoTab.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get libraryPhotoTab;

  /// No description provided for @libraryUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get libraryUploading;

  /// No description provided for @librarySelectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select From Gallery'**
  String get librarySelectFromGallery;

  /// No description provided for @libraryCustomCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a custom cover photo'**
  String get libraryCustomCoverHint;

  /// No description provided for @libraryUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String libraryUploadError(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
