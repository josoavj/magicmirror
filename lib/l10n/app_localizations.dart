import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Magic Mirror iOS 26'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @displaySection.
  ///
  /// In fr, this message translates to:
  /// **'Affichage'**
  String get displaySection;

  /// No description provided for @darkModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkModeLabel;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le thème sombre'**
  String get darkModeSubtitle;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// No description provided for @notificationsSoundSection.
  ///
  /// In fr, this message translates to:
  /// **'Notifications & Son'**
  String get notificationsSoundSection;

  /// No description provided for @notificationsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les notifications'**
  String get notificationsSubtitle;

  /// No description provided for @audioFeedbackLabel.
  ///
  /// In fr, this message translates to:
  /// **'Retours audio'**
  String get audioFeedbackLabel;

  /// No description provided for @audioFeedbackSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sons et vibrations'**
  String get audioFeedbackSubtitle;

  /// No description provided for @ttsSection.
  ///
  /// In fr, this message translates to:
  /// **'Voix (TTS)'**
  String get ttsSection;

  /// No description provided for @ttsEnabledLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annonces vocales'**
  String get ttsEnabledLabel;

  /// No description provided for @ttsEnabledSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la synthèse vocale pour le miroir'**
  String get ttsEnabledSubtitle;

  /// No description provided for @ttsLanguageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue de la voix'**
  String get ttsLanguageLabel;

  /// No description provided for @ttsMorphologyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Inclure la morphologie détectée'**
  String get ttsMorphologyLabel;

  /// No description provided for @ttsMorphologySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prononcer aussi le type de morphologie dans les annonces'**
  String get ttsMorphologySubtitle;

  /// No description provided for @ttsSpeechRateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse de lecture'**
  String get ttsSpeechRateLabel;

  /// No description provided for @ttsPitchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tonalité de la voix'**
  String get ttsPitchLabel;

  /// No description provided for @ttsRepeatLabel.
  ///
  /// In fr, this message translates to:
  /// **'Anti-répétition des annonces'**
  String get ttsRepeatLabel;

  /// No description provided for @ttsInterruptLabel.
  ///
  /// In fr, this message translates to:
  /// **'Interrompre l\'annonce en cours'**
  String get ttsInterruptLabel;

  /// No description provided for @ttsInterruptSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Évite les annonces qui s\'empilent'**
  String get ttsInterruptSubtitle;

  /// No description provided for @ttsTestButton.
  ///
  /// In fr, this message translates to:
  /// **'Tester la voix'**
  String get ttsTestButton;

  /// No description provided for @ttsTestSpeechFr.
  ///
  /// In fr, this message translates to:
  /// **'Test vocal. Vos préférences de synthèse vocale sont appliquées.'**
  String get ttsTestSpeechFr;

  /// No description provided for @ttsTestSpeechEn.
  ///
  /// In fr, this message translates to:
  /// **'Voice test. Your text to speech preferences are now applied.'**
  String get ttsTestSpeechEn;

  /// No description provided for @locationWeatherSection.
  ///
  /// In fr, this message translates to:
  /// **'Localisation & Météo'**
  String get locationWeatherSection;

  /// No description provided for @locationTrackingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Suivi de localisation'**
  String get locationTrackingLabel;

  /// No description provided for @locationTrackingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser votre position pour la météo'**
  String get locationTrackingSubtitle;

  /// No description provided for @defaultCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville par défaut'**
  String get defaultCityLabel;

  /// No description provided for @defaultCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Antananarivo'**
  String get defaultCityHint;

  /// No description provided for @calendarSection.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendarSection;

  /// No description provided for @calendarSyncLabel.
  ///
  /// In fr, this message translates to:
  /// **'Agenda cloud au démarrage'**
  String get calendarSyncLabel;

  /// No description provided for @calendarSyncSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser votre agenda Supabase au lancement'**
  String get calendarSyncSubtitle;

  /// No description provided for @cameraSection.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get cameraSection;

  /// No description provided for @cameraFlipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Inverser caméra'**
  String get cameraFlipLabel;

  /// No description provided for @cameraFlipSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Retourner l\'affichage de la caméra'**
  String get cameraFlipSubtitle;

  /// No description provided for @flashModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode flash'**
  String get flashModeLabel;

  /// No description provided for @flashOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get flashOff;

  /// No description provided for @flashAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get flashAuto;

  /// No description provided for @flashAlways.
  ///
  /// In fr, this message translates to:
  /// **'Activé'**
  String get flashAlways;

  /// No description provided for @flashTorch.
  ///
  /// In fr, this message translates to:
  /// **'Torche'**
  String get flashTorch;

  /// No description provided for @compatibilityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité'**
  String get compatibilityLabel;

  /// No description provided for @cameraControlInfo.
  ///
  /// In fr, this message translates to:
  /// **'Le zoom et l’exposition se règlent directement sur la caméra avec une interface animée.'**
  String get cameraControlInfo;

  /// No description provided for @mirrorHudVisibleLabel.
  ///
  /// In fr, this message translates to:
  /// **'HUD miroir visible'**
  String get mirrorHudVisibleLabel;

  /// No description provided for @mirrorHudEveryLabel.
  ///
  /// In fr, this message translates to:
  /// **'HUD miroir toutes les'**
  String get mirrorHudEveryLabel;

  /// No description provided for @accountSection.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountSection;

  /// No description provided for @accountSettingsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get accountSettingsLabel;

  /// No description provided for @outfitSuggestionsSection.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions de tenue'**
  String get outfitSuggestionsSection;

  /// No description provided for @outfitSuggestionsSettingsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres et diagnostics des suggestions'**
  String get outfitSuggestionsSettingsLabel;

  /// No description provided for @informationSection.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get informationSection;

  /// No description provided for @versionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @appVersionDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'application'**
  String get appVersionDialogTitle;

  /// No description provided for @appVersionDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Magic Mirror {version}\\n\\nVous pouvez consulter les détails dans la page À propos.'**
  String appVersionDialogBody(Object version);

  /// No description provided for @closeButton.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// No description provided for @seeAboutButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir À propos'**
  String get seeAboutButton;

  /// No description provided for @aboutLabel.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutLabel;

  /// No description provided for @advancedSection.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres avancés'**
  String get advancedSection;

  /// No description provided for @resetDefaultsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser par défaut'**
  String get resetDefaultsLabel;

  /// No description provided for @resetDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser ?'**
  String get resetDialogTitle;

  /// No description provided for @resetDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Cela va restaurer tous les paramètres par défaut.'**
  String get resetDialogBody;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @resetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetButton;

  /// No description provided for @settingsResetToast.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres réinitialisés'**
  String get settingsResetToast;

  /// No description provided for @secondsShort.
  ///
  /// In fr, this message translates to:
  /// **'sec'**
  String get secondsShort;

  /// No description provided for @minuteSingular.
  ///
  /// In fr, this message translates to:
  /// **'minute'**
  String get minuteSingular;

  /// No description provided for @minutePlural.
  ///
  /// In fr, this message translates to:
  /// **'minutes'**
  String get minutePlural;

  /// No description provided for @runtimeCameraInactive.
  ///
  /// In fr, this message translates to:
  /// **'Caméra inactive'**
  String get runtimeCameraInactive;

  /// No description provided for @runtimeAiAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'IA en analyse'**
  String get runtimeAiAnalyzing;

  /// No description provided for @runtimeAiActive.
  ///
  /// In fr, this message translates to:
  /// **'IA active'**
  String get runtimeAiActive;

  /// No description provided for @runtimeAiWaiting.
  ///
  /// In fr, this message translates to:
  /// **'IA en attente'**
  String get runtimeAiWaiting;

  /// No description provided for @unsupportedSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages non supportés: {items}'**
  String unsupportedSettings(Object items);

  /// No description provided for @unsupportedZoom.
  ///
  /// In fr, this message translates to:
  /// **'zoom'**
  String get unsupportedZoom;

  /// No description provided for @unsupportedExposure.
  ///
  /// In fr, this message translates to:
  /// **'exposition'**
  String get unsupportedExposure;

  /// No description provided for @unsupportedFlash.
  ///
  /// In fr, this message translates to:
  /// **'flash'**
  String get unsupportedFlash;

  /// No description provided for @cameraControlsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Contrôles caméra'**
  String get cameraControlsTooltip;

  /// No description provided for @cameraExposureTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Exposition'**
  String get cameraExposureTooltip;

  /// No description provided for @quickSettingsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres caméra et HUD'**
  String get quickSettingsTooltip;

  /// No description provided for @outfitReadyBadge.
  ///
  /// In fr, this message translates to:
  /// **'Corps complet détecté - Tenues prêtes'**
  String get outfitReadyBadge;

  /// No description provided for @cameraResetBadge.
  ///
  /// In fr, this message translates to:
  /// **'Reset caméra'**
  String get cameraResetBadge;

  /// No description provided for @fullBodyDetectedWithOutfit.
  ///
  /// In fr, this message translates to:
  /// **'Corps complet détecté. {morphology}Tenue recommandée: {title}. {reason}'**
  String fullBodyDetectedWithOutfit(
    Object morphology,
    Object title,
    Object reason,
  );

  /// No description provided for @fullBodyDetectedWithoutOutfit.
  ///
  /// In fr, this message translates to:
  /// **'Corps complet détecté. {morphology}Vos suggestions de tenues sont prêtes.'**
  String fullBodyDetectedWithoutOutfit(Object morphology);

  /// No description provided for @detectedBodyType.
  ///
  /// In fr, this message translates to:
  /// **'Morphologie détectée: {bodyType}. '**
  String detectedBodyType(Object bodyType);

  /// No description provided for @supabaseNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Supabase non configuré dans assets/.env'**
  String get supabaseNotConfigured;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
