import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/features/settings/data/models/app_settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour la gestion des reglages application
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings.defaults()) {
    _loadSettings();
  }

  /// Charger les parametres depuis shared_preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final settings = AppSettings(
        darkMode: prefs.getBool('darkMode') ?? true,
        locale: prefs.getString('locale') ?? 'fr_FR',
        enableNotifications: prefs.getBool('enableNotifications') ?? true,
        enableLocationTracking: prefs.getBool('enableLocationTracking') ?? true,
        defaultCity: prefs.getString('defaultCity') ?? 'Antananarivo',
        syncCalendarOnStartup: prefs.getBool('syncCalendarOnStartup') ?? true,
        enableAudioFeedback: prefs.getBool('enableAudioFeedback') ?? true,
        cameraFlipped: prefs.getBool('cameraFlipped') ?? false,
        cameraZoom: prefs.getDouble('cameraZoom') ?? 1.0,
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

  /// Sauvegarder les parametres
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
      await prefs.setBool('cameraFlipped', state.cameraFlipped);
      await prefs.setDouble('cameraZoom', state.cameraZoom);
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
    state = state.copyWith(locale: locale);
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

  /// Modifier la ville par defaut
  Future<void> setDefaultCity(String city) async {
    state = state.copyWith(defaultCity: city);
    await _saveSettings();
  }

  /// Modifier sync calendrier au demarrage
  Future<void> setSyncCalendarOnStartup(bool value) async {
    state = state.copyWith(syncCalendarOnStartup: value);
    await _saveSettings();
  }

  /// Modifier retours audio
  Future<void> setAudioFeedback(bool value) async {
    state = state.copyWith(enableAudioFeedback: value);
    await _saveSettings();
  }

  /// Inverser la camera
  Future<void> setCameraFlipped(bool value) async {
    state = state.copyWith(cameraFlipped: value);
    await _saveSettings();
  }

  /// Modifier le zoom camera
  Future<void> setCameraZoom(double zoom) async {
    state = state.copyWith(cameraZoom: zoom);
    await _saveSettings();
  }

  /// Reinitialiser les parametres par defaut
  Future<void> resetToDefaults() async {
    state = AppSettings.defaults();
    await _saveSettings();
  }
}
