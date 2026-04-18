// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Magic Mirror iOS 26';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get displaySection => 'Affichage';

  @override
  String get darkModeLabel => 'Mode sombre';

  @override
  String get darkModeSubtitle => 'Utiliser le thème sombre';

  @override
  String get languageLabel => 'Langue';

  @override
  String get notificationsSoundSection => 'Notifications & Son';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get notificationsSubtitle => 'Recevoir les notifications';

  @override
  String get audioFeedbackLabel => 'Retours audio';

  @override
  String get audioFeedbackSubtitle => 'Sons et vibrations';

  @override
  String get ttsSection => 'Voix (TTS)';

  @override
  String get ttsEnabledLabel => 'Annonces vocales';

  @override
  String get ttsEnabledSubtitle => 'Activer la synthèse vocale pour le miroir';

  @override
  String get ttsLanguageLabel => 'Langue de la voix';

  @override
  String get ttsMorphologyLabel => 'Inclure la morphologie détectée';

  @override
  String get ttsMorphologySubtitle =>
      'Prononcer aussi le type de morphologie dans les annonces';

  @override
  String get ttsSpeechRateLabel => 'Vitesse de lecture';

  @override
  String get ttsPitchLabel => 'Tonalité de la voix';

  @override
  String get ttsRepeatLabel => 'Anti-répétition des annonces';

  @override
  String get ttsInterruptLabel => 'Interrompre l\'annonce en cours';

  @override
  String get ttsInterruptSubtitle => 'Évite les annonces qui s\'empilent';

  @override
  String get ttsTestButton => 'Tester la voix';

  @override
  String get ttsTestSpeechFr =>
      'Test vocal. Vos préférences de synthèse vocale sont appliquées.';

  @override
  String get ttsTestSpeechEn =>
      'Voice test. Your text to speech preferences are now applied.';

  @override
  String get locationWeatherSection => 'Localisation & Météo';

  @override
  String get locationTrackingLabel => 'Suivi de localisation';

  @override
  String get locationTrackingSubtitle =>
      'Utiliser votre position pour la météo';

  @override
  String get defaultCityLabel => 'Ville par défaut';

  @override
  String get defaultCityHint => 'Ex: Antananarivo';

  @override
  String get calendarSection => 'Calendrier';

  @override
  String get calendarSyncLabel => 'Agenda cloud au démarrage';

  @override
  String get calendarSyncSubtitle =>
      'Synchroniser votre agenda Supabase au lancement';

  @override
  String get cameraSection => 'Caméra';

  @override
  String get cameraFlipLabel => 'Inverser caméra';

  @override
  String get cameraFlipSubtitle => 'Retourner l\'affichage de la caméra';

  @override
  String get flashModeLabel => 'Mode flash';

  @override
  String get flashOff => 'Désactivé';

  @override
  String get flashAuto => 'Auto';

  @override
  String get flashAlways => 'Activé';

  @override
  String get flashTorch => 'Torche';

  @override
  String get compatibilityLabel => 'Compatibilité';

  @override
  String get cameraControlInfo =>
      'Le zoom et l’exposition se règlent directement sur la caméra avec une interface animée.';

  @override
  String get mirrorHudVisibleLabel => 'HUD miroir visible';

  @override
  String get mirrorHudEveryLabel => 'HUD miroir toutes les';

  @override
  String get accountSection => 'Compte';

  @override
  String get accountSettingsLabel => 'Paramètres du compte';

  @override
  String get outfitSuggestionsSection => 'Suggestions de tenue';

  @override
  String get outfitSuggestionsSettingsLabel =>
      'Paramètres et diagnostics des suggestions';

  @override
  String get informationSection => 'Informations';

  @override
  String get versionLabel => 'Version';

  @override
  String get appVersionDialogTitle => 'Version de l\'application';

  @override
  String appVersionDialogBody(Object version) {
    return 'Magic Mirror $version\\n\\nVous pouvez consulter les détails dans la page À propos.';
  }

  @override
  String get closeButton => 'Fermer';

  @override
  String get seeAboutButton => 'Voir À propos';

  @override
  String get aboutLabel => 'À propos';

  @override
  String get advancedSection => 'Paramètres avancés';

  @override
  String get resetDefaultsLabel => 'Réinitialiser par défaut';

  @override
  String get resetDialogTitle => 'Réinitialiser ?';

  @override
  String get resetDialogBody =>
      'Cela va restaurer tous les paramètres par défaut.';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get resetButton => 'Réinitialiser';

  @override
  String get settingsResetToast => 'Paramètres réinitialisés';

  @override
  String get secondsShort => 'sec';

  @override
  String get minuteSingular => 'minute';

  @override
  String get minutePlural => 'minutes';

  @override
  String get runtimeCameraInactive => 'Caméra inactive';

  @override
  String get runtimeAiAnalyzing => 'IA en analyse';

  @override
  String get runtimeAiActive => 'IA active';

  @override
  String get runtimeAiWaiting => 'IA en attente';

  @override
  String unsupportedSettings(Object items) {
    return 'Réglages non supportés: $items';
  }

  @override
  String get unsupportedZoom => 'zoom';

  @override
  String get unsupportedExposure => 'exposition';

  @override
  String get unsupportedFlash => 'flash';

  @override
  String get cameraControlsTooltip => 'Contrôles caméra';

  @override
  String get cameraExposureTooltip => 'Exposition';

  @override
  String get quickSettingsTooltip => 'Paramètres caméra et HUD';

  @override
  String get outfitReadyBadge => 'Corps complet détecté - Tenues prêtes';

  @override
  String get cameraResetBadge => 'Reset caméra';

  @override
  String fullBodyDetectedWithOutfit(
    Object morphology,
    Object title,
    Object reason,
  ) {
    return 'Corps complet détecté. ${morphology}Tenue recommandée: $title. $reason';
  }

  @override
  String fullBodyDetectedWithoutOutfit(Object morphology) {
    return 'Corps complet détecté. ${morphology}Vos suggestions de tenues sont prêtes.';
  }

  @override
  String detectedBodyType(Object bodyType) {
    return 'Morphologie détectée: $bodyType. ';
  }

  @override
  String get supabaseNotConfigured => 'Supabase non configuré dans assets/.env';
}
