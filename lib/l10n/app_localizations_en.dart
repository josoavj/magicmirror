// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Magic Mirror iOS 26';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get displaySection => 'Display';

  @override
  String get darkModeLabel => 'Dark mode';

  @override
  String get darkModeSubtitle => 'Use dark theme';

  @override
  String get languageLabel => 'Language';

  @override
  String get notificationsSoundSection => 'Notifications & Sound';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get notificationsSubtitle => 'Receive notifications';

  @override
  String get audioFeedbackLabel => 'Audio feedback';

  @override
  String get audioFeedbackSubtitle => 'Sounds and vibrations';

  @override
  String get ttsSection => 'Voice (TTS)';

  @override
  String get ttsEnabledLabel => 'Voice announcements';

  @override
  String get ttsEnabledSubtitle => 'Enable speech synthesis for mirror';

  @override
  String get ttsLanguageLabel => 'Voice language';

  @override
  String get ttsMorphologyLabel => 'Include detected body type';

  @override
  String get ttsMorphologySubtitle =>
      'Also speak detected body type in announcements';

  @override
  String get ttsSpeechRateLabel => 'Speech rate';

  @override
  String get ttsPitchLabel => 'Voice pitch';

  @override
  String get ttsRepeatLabel => 'Announcement anti-repeat';

  @override
  String get ttsInterruptLabel => 'Interrupt current announcement';

  @override
  String get ttsInterruptSubtitle => 'Avoid stacked announcements';

  @override
  String get ttsTestButton => 'Test voice';

  @override
  String get ttsTestSpeechFr =>
      'Test vocal. Vos préférences de synthèse vocale sont appliquées.';

  @override
  String get ttsTestSpeechEn =>
      'Voice test. Your text to speech preferences are now applied.';

  @override
  String get locationWeatherSection => 'Location & Weather';

  @override
  String get locationTrackingLabel => 'Location tracking';

  @override
  String get locationTrackingSubtitle => 'Use your position for weather';

  @override
  String get defaultCityLabel => 'Default city';

  @override
  String get defaultCityHint => 'E.g. Antananarivo';

  @override
  String get calendarSection => 'Calendar';

  @override
  String get calendarSyncLabel => 'Cloud agenda on startup';

  @override
  String get calendarSyncSubtitle => 'Sync your Supabase calendar at launch';

  @override
  String get cameraSection => 'Camera';

  @override
  String get cameraFlipLabel => 'Flip camera';

  @override
  String get cameraFlipSubtitle => 'Mirror camera preview';

  @override
  String get flashModeLabel => 'Flash mode';

  @override
  String get flashOff => 'Off';

  @override
  String get flashAuto => 'Auto';

  @override
  String get flashAlways => 'On';

  @override
  String get flashTorch => 'Torch';

  @override
  String get compatibilityLabel => 'Compatibility';

  @override
  String get cameraControlInfo =>
      'Zoom and exposure are now controlled directly in camera with an animated UI.';

  @override
  String get mirrorHudVisibleLabel => 'Mirror HUD visible';

  @override
  String get mirrorHudEveryLabel => 'Mirror HUD every';

  @override
  String get accountSection => 'Account';

  @override
  String get accountSettingsLabel => 'Account settings';

  @override
  String get outfitSuggestionsSection => 'Outfit Suggestions';

  @override
  String get outfitSuggestionsSettingsLabel =>
      'Suggestion settings and diagnostics';

  @override
  String get informationSection => 'Information';

  @override
  String get versionLabel => 'Version';

  @override
  String get appVersionDialogTitle => 'App version';

  @override
  String appVersionDialogBody(Object version) {
    return 'Magic Mirror $version\\n\\nYou can check details in the About page.';
  }

  @override
  String get closeButton => 'Close';

  @override
  String get seeAboutButton => 'View About';

  @override
  String get aboutLabel => 'About';

  @override
  String get advancedSection => 'Advanced settings';

  @override
  String get resetDefaultsLabel => 'Reset defaults';

  @override
  String get resetDialogTitle => 'Reset?';

  @override
  String get resetDialogBody => 'This will restore all settings to defaults.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get resetButton => 'Reset';

  @override
  String get settingsResetToast => 'Settings reset';

  @override
  String get secondsShort => 'sec';

  @override
  String get minuteSingular => 'minute';

  @override
  String get minutePlural => 'minutes';

  @override
  String get runtimeCameraInactive => 'Camera inactive';

  @override
  String get runtimeAiAnalyzing => 'AI analyzing';

  @override
  String get runtimeAiActive => 'AI active';

  @override
  String get runtimeAiWaiting => 'AI waiting';

  @override
  String unsupportedSettings(Object items) {
    return 'Unsupported settings: $items';
  }

  @override
  String get unsupportedZoom => 'zoom';

  @override
  String get unsupportedExposure => 'exposure';

  @override
  String get unsupportedFlash => 'flash';

  @override
  String get cameraControlsTooltip => 'Camera controls';

  @override
  String get cameraExposureTooltip => 'Exposure';

  @override
  String get quickSettingsTooltip => 'Camera and HUD settings';

  @override
  String get outfitReadyBadge => 'Full body detected - Outfits ready';

  @override
  String get cameraResetBadge => 'Camera reset';

  @override
  String fullBodyDetectedWithOutfit(
    Object morphology,
    Object title,
    Object reason,
  ) {
    return 'Full body detected. ${morphology}Recommended outfit: $title. $reason';
  }

  @override
  String fullBodyDetectedWithoutOutfit(Object morphology) {
    return 'Full body detected. ${morphology}Your outfit suggestions are ready.';
  }

  @override
  String detectedBodyType(Object bodyType) {
    return 'Detected body type: $bodyType. ';
  }

  @override
  String get supabaseNotConfigured => 'Supabase not configured in assets/.env';
}
