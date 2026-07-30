import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/core/constants/app_constants.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/core/services/storage_service.dart';
import 'package:magicmirror/features/settings/data/models/app_settings_model.dart';

/// Provider pour la gestion des réglages application
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return AppSettingsNotifier(storageService);
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;

  AppSettingsNotifier(this._storageService) : super(AppSettings.defaults()) {
    Future.microtask(_loadSettings);
  }

  static const Set<String> _supportedLocales = {'fr_FR', 'en_US'};
  static const Set<String> _supportedTtsLanguages = {'fr-FR', 'en-US'};
  static const Set<String> _supportedFlashModes = {
    'off',
    'auto',
    'always',
    'torch',
  };
  static const Set<String> _supportedCameraProfiles = {
    'auto',
    'low',
    'medium',
    'high',
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

  String? _normalizeSupportedValue(
    String? rawValue,
    Set<String> supportedValues,
  ) {
    if (rawValue == null) {
      return null;
    }

    final normalizedValue = rawValue.trim().toLowerCase();
    if (supportedValues.contains(normalizedValue)) {
      return normalizedValue;
    }

    return null;
  }

  String _normalizeCameraProfile(String? rawProfile) {
    return _normalizeSupportedValue(rawProfile, _supportedCameraProfiles) ??
        _normalizeSupportedValue(
          AppConfig.cameraProfile,
          _supportedCameraProfiles,
        ) ??
        'auto';
  }

  /// Charger les paramètres depuis le stockage
  Future<void> _loadSettings() async {
    try {
      final settings = AppSettings(
        darkMode: await _storageService.getBool('darkMode') ?? true,
        locale: _normalizeLocale(await _storageService.getString('locale')),
        enableNotifications: await _storageService.getBool('enableNotifications') ?? true,
        enableLocationTracking: await _storageService.getBool('enableLocationTracking') ?? true,
        defaultCity: await _storageService.getString('defaultCity') ?? 'Antananarivo',
        syncCalendarOnStartup: await _storageService.getBool('syncCalendarOnStartup') ?? true,
        enableAudioFeedback: await _storageService.getBool('enableAudioFeedback') ?? true,
        ttsEnabled: await _storageService.getBool('ttsEnabled') ?? true,
        ttsLanguage: _normalizeTtsLanguage(await _storageService.getString('ttsLanguage')),
        ttsAnnounceMorphology: await _storageService.getBool('ttsAnnounceMorphology') ?? true,
        ttsSpeechRate: await _storageService.getDouble('ttsSpeechRate') ?? 0.50,
        ttsPitch: await _storageService.getDouble('ttsPitch') ?? 1.00,
        ttsMinRepeatSeconds: await _storageService.getInt('ttsMinRepeatSeconds') ?? 45,
        ttsInterruptCurrent: await _storageService.getBool('ttsInterruptCurrent') ?? true,
        cameraFlipped: await _storageService.getBool('cameraFlipped') ?? false,
        cameraZoom: await _storageService.getDouble('cameraZoom') ?? 1.0,
        cameraExposureOffset: await _storageService.getDouble('cameraExposureOffset') ?? 0.0,
        cameraFlashMode: _normalizeFlashMode(
          await _storageService.getString('cameraFlashMode'),
        ),
        cameraProfile: _normalizeCameraProfile(
          await _storageService.getString('cameraProfile'),
        ),
        mirrorHudDisplaySeconds: await _storageService.getInt('mirrorHudDisplaySeconds') ?? 30,
        mirrorHudCycleMinutes: await _storageService.getInt('mirrorHudCycleMinutes') ?? 5,
        appVersion: AppConstants.appVersion,
        lowPerformanceMode: await _storageService.getBool('lowPerformanceMode') ?? false,
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
      await _storageService.saveBool('darkMode', state.darkMode);
      await _storageService.saveString('locale', state.locale);
      await _storageService.saveBool('enableNotifications', state.enableNotifications);
      await _storageService.saveBool('enableLocationTracking', state.enableLocationTracking);
      await _storageService.saveString('defaultCity', state.defaultCity);
      await _storageService.saveBool('syncCalendarOnStartup', state.syncCalendarOnStartup);
      await _storageService.saveBool('enableAudioFeedback', state.enableAudioFeedback);
      await _storageService.saveBool('ttsEnabled', state.ttsEnabled);
      await _storageService.saveString('ttsLanguage', state.ttsLanguage);
      await _storageService.saveBool('ttsAnnounceMorphology', state.ttsAnnounceMorphology);
      await _storageService.saveDouble('ttsSpeechRate', state.ttsSpeechRate);
      await _storageService.saveDouble('ttsPitch', state.ttsPitch);
      await _storageService.saveInt('ttsMinRepeatSeconds', state.ttsMinRepeatSeconds);
      await _storageService.saveBool('ttsInterruptCurrent', state.ttsInterruptCurrent);
      await _storageService.saveBool('cameraFlipped', state.cameraFlipped);
      await _storageService.saveDouble('cameraZoom', state.cameraZoom);
      await _storageService.saveDouble('cameraExposureOffset', state.cameraExposureOffset);
      await _storageService.saveString('cameraFlashMode', state.cameraFlashMode);
      await _storageService.saveString('cameraProfile', state.cameraProfile);
      await _storageService.saveInt('mirrorHudDisplaySeconds', state.mirrorHudDisplaySeconds);
      await _storageService.saveInt('mirrorHudCycleMinutes', state.mirrorHudCycleMinutes);
      await _storageService.saveBool('lowPerformanceMode', state.lowPerformanceMode);
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
    final normalizedLocale = _normalizeLocale(locale);
    final autoTtsLanguage = normalizedLocale == 'en_US' ? 'en-US' : 'fr-FR';
    state = state.copyWith(
      locale: normalizedLocale,
      ttsLanguage: autoTtsLanguage,
    );
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

  /// Modifier le profil performance camera
  Future<void> setCameraProfile(String profile) async {
    state = state.copyWith(cameraProfile: _normalizeCameraProfile(profile));
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

  /// Activer/désactiver le mode basse performance (désactive les flous)
  Future<void> setLowPerformanceMode(bool value) async {
    state = state.copyWith(lowPerformanceMode: value);
    await _saveSettings();
  }

  /// Réinitialiser les paramètres par défaut
  Future<void> resetToDefaults() async {
    state = AppSettings.defaults();
    await _saveSettings();
  }
}
