import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/features/settings/data/models/app_settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour la gestion des réglages application
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings.defaults()) {
    _loadSettings();
  }

  static const Set<String> _supportedLocales = {'fr_FR', 'en_US'};
  static const Set<String> _supportedTtsLanguages = {'fr-FR', 'en-US'};
  static const Set<String> _supportedFlashModes = {
    'off',
    'auto',
    'always',
    'torch',
  };

  String _normalizeLocale(String? rawLocale) {
    if (rawLocale != null && _supportedLocales.contains(rawLocale)) {
      return rawLocale;
    }
    return 'fr_FR';
  }

  String _normalizeTtsLanguage(String? rawLanguage) {
    if (rawLanguage != null && _supportedTtsLanguages.contains(rawLanguage)) {
      return rawLanguage;
    }
    return 'fr-FR';
  }

  String _normalizeFlashMode(String? rawMode) {
    if (rawMode != null && _supportedFlashModes.contains(rawMode)) {
      return rawMode;
    }
    return 'off';
  }

  /// Charger les paramètres depuis shared_preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final settings = AppSettings(
        darkMode: prefs.getBool('darkMode') ?? true,
        locale: _normalizeLocale(prefs.getString('locale')),
        enableNotifications: prefs.getBool('enableNotifications') ?? true,
        enableLocationTracking: prefs.getBool('enableLocationTracking') ?? true,
        defaultCity: prefs.getString('defaultCity') ?? 'Antananarivo',
        syncCalendarOnStartup: prefs.getBool('syncCalendarOnStartup') ?? true,
        enableAudioFeedback: prefs.getBool('enableAudioFeedback') ?? true,
        ttsEnabled: prefs.getBool('ttsEnabled') ?? true,
        ttsLanguage: _normalizeTtsLanguage(prefs.getString('ttsLanguage')),
        ttsAnnounceMorphology: prefs.getBool('ttsAnnounceMorphology') ?? true,
        ttsSpeechRate: prefs.getDouble('ttsSpeechRate') ?? 0.50,
        ttsPitch: prefs.getDouble('ttsPitch') ?? 1.00,
        ttsMinRepeatSeconds: prefs.getInt('ttsMinRepeatSeconds') ?? 45,
        ttsInterruptCurrent: prefs.getBool('ttsInterruptCurrent') ?? true,
        cameraFlipped: prefs.getBool('cameraFlipped') ?? false,
        cameraZoom: prefs.getDouble('cameraZoom') ?? 1.0,
        cameraExposureOffset: prefs.getDouble('cameraExposureOffset') ?? 0.0,
        cameraFlashMode: _normalizeFlashMode(
          prefs.getString('cameraFlashMode'),
        ),
        mirrorHudDisplaySeconds: prefs.getInt('mirrorHudDisplaySeconds') ?? 30,
        mirrorHudCycleMinutes: prefs.getInt('mirrorHudCycleMinutes') ?? 5,
        appVersion: prefs.getString('appVersion') ?? '1.0.0',
      );

      state = settings;
    } catch (e) {
      logger.error(
        'Erreur chargement settings',
        tag: 'SettingsProvider',
        error: e,
      );
    }
  }

  /// Sauvegarder les paramètres
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('darkMode', state.darkMode);
      await prefs.setString('locale', state.locale);
      await prefs.setBool('enableNotifications', state.enableNotifications);
      await prefs.setBool(
        'enableLocationTracking',
        state.enableLocationTracking,
      );
      await prefs.setString('defaultCity', state.defaultCity);
      await prefs.setBool('syncCalendarOnStartup', state.syncCalendarOnStartup);
      await prefs.setBool('enableAudioFeedback', state.enableAudioFeedback);
      await prefs.setBool('ttsEnabled', state.ttsEnabled);
      await prefs.setString('ttsLanguage', state.ttsLanguage);
      await prefs.setBool('ttsAnnounceMorphology', state.ttsAnnounceMorphology);
      await prefs.setDouble('ttsSpeechRate', state.ttsSpeechRate);
      await prefs.setDouble('ttsPitch', state.ttsPitch);
      await prefs.setInt('ttsMinRepeatSeconds', state.ttsMinRepeatSeconds);
      await prefs.setBool('ttsInterruptCurrent', state.ttsInterruptCurrent);
      await prefs.setBool('cameraFlipped', state.cameraFlipped);
      await prefs.setDouble('cameraZoom', state.cameraZoom);
      await prefs.setDouble('cameraExposureOffset', state.cameraExposureOffset);
      await prefs.setString('cameraFlashMode', state.cameraFlashMode);
      await prefs.setInt(
        'mirrorHudDisplaySeconds',
        state.mirrorHudDisplaySeconds,
      );
      await prefs.setInt('mirrorHudCycleMinutes', state.mirrorHudCycleMinutes);
      await prefs.setString('appVersion', state.appVersion);
    } catch (e) {
      logger.error(
        'Erreur sauvegarde settings',
        tag: 'SettingsProvider',
        error: e,
      );
    }
  }

  /// Modifier le mode sombre
  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _saveSettings();
  }

  /// Modifier la langue
  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: _normalizeLocale(locale));
    await _saveSettings();
  }

  /// Modifier les notifications
  Future<void> setNotifications(bool value) async {
    state = state.copyWith(enableNotifications: value);
    await _saveSettings();
  }

  /// Modifier le suivi de localisation
  Future<void> setLocationTracking(bool value) async {
    state = state.copyWith(enableLocationTracking: value);
    await _saveSettings();
  }

  /// Modifier la ville par défaut
  Future<void> setDefaultCity(String city) async {
    state = state.copyWith(defaultCity: city);
    await _saveSettings();
  }

  /// Modifier sync calendrier au démarrage
  Future<void> setSyncCalendarOnStartup(bool value) async {
    state = state.copyWith(syncCalendarOnStartup: value);
    await _saveSettings();
  }

  /// Modifier retours audio
  Future<void> setAudioFeedback(bool value) async {
    state = state.copyWith(enableAudioFeedback: value);
    await _saveSettings();
  }

  /// Activer/desactiver les annonces TTS
  Future<void> setTtsEnabled(bool value) async {
    state = state.copyWith(ttsEnabled: value);
    await _saveSettings();
  }

  /// Choisir la langue de voix TTS
  Future<void> setTtsLanguage(String language) async {
    state = state.copyWith(ttsLanguage: _normalizeTtsLanguage(language));
    await _saveSettings();
  }

  /// Inclure la morphologie detectee dans les annonces vocales
  Future<void> setTtsAnnounceMorphology(bool value) async {
    state = state.copyWith(ttsAnnounceMorphology: value);
    await _saveSettings();
  }

  /// Ajuster la vitesse de voix TTS
  Future<void> setTtsSpeechRate(double value) async {
    final clamped = value.clamp(0.2, 0.8);
    state = state.copyWith(ttsSpeechRate: clamped);
    await _saveSettings();
  }

  /// Ajuster la tonalite de voix TTS
  Future<void> setTtsPitch(double value) async {
    final clamped = value.clamp(0.6, 1.6);
    state = state.copyWith(ttsPitch: clamped);
    await _saveSettings();
  }

  /// Cooldown anti-repetition pour les annonces TTS
  Future<void> setTtsMinRepeatSeconds(int seconds) async {
    final clamped = seconds.clamp(5, 300);
    state = state.copyWith(ttsMinRepeatSeconds: clamped);
    await _saveSettings();
  }

  /// Interrompre l'annonce en cours avant une nouvelle annonce
  Future<void> setTtsInterruptCurrent(bool value) async {
    state = state.copyWith(ttsInterruptCurrent: value);
    await _saveSettings();
  }

  /// Inverser la caméra
  Future<void> setCameraFlipped(bool value) async {
    state = state.copyWith(cameraFlipped: value);
    await _saveSettings();
  }

  /// Modifier le zoom caméra
  Future<void> setCameraZoom(double zoom) async {
    final clamped = zoom.clamp(1.0, 4.0);
    state = state.copyWith(cameraZoom: clamped);
    await _saveSettings();
  }

  /// Modifier l'exposition caméra
  Future<void> setCameraExposureOffset(double offset) async {
    final clamped = offset.clamp(-2.0, 2.0);
    state = state.copyWith(cameraExposureOffset: clamped);
    await _saveSettings();
  }

  /// Modifier le mode flash caméra
  Future<void> setCameraFlashMode(String mode) async {
    state = state.copyWith(cameraFlashMode: _normalizeFlashMode(mode));
    await _saveSettings();
  }

  /// Durée d'affichage du HUD mobile miroir (en secondes)
  Future<void> setMirrorHudDisplaySeconds(int seconds) async {
    final clamped = seconds.clamp(5, 180);
    state = state.copyWith(mirrorHudDisplaySeconds: clamped);
    await _saveSettings();
  }

  /// Fréquence d'apparition du HUD mobile miroir (en minutes)
  Future<void> setMirrorHudCycleMinutes(int minutes) async {
    final clamped = minutes.clamp(1, 60);
    state = state.copyWith(mirrorHudCycleMinutes: clamped);
    await _saveSettings();
  }

  /// Réinitialiser les paramètres par défaut
  Future<void> resetToDefaults() async {
    state = AppSettings.defaults();
    await _saveSettings();
  }
}
