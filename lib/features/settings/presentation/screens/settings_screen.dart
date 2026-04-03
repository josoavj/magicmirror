import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  // BUG FIX #10: Super parameter - simplifier avec super keyword
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                SettingsSection(
                  title: 'Affichage',
                  children: [
                    SettingsToggle(
                      icon: Icons.dark_mode,
                      label: 'Mode sombre',
                      subtitle: 'Utiliser le thème sombre',
                      value: settings.darkMode,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setDarkMode(value);
                      },
                    ),
                    SettingsDropdown<String>(
                      icon: Icons.language,
                      label: 'Langue',
                      value: settings.locale,
                      items: [
                        const DropdownMenuItem(
                          value: 'fr_FR',
                          child: Text(
                            'Français',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'en_US',
                          child: Text(
                            'English',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setLocale(value);
                        }
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Notifications & Son',
                  children: [
                    SettingsToggle(
                      icon: Icons.notifications,
                      label: 'Notifications',
                      subtitle: 'Recevoir les notifications',
                      value: settings.enableNotifications,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setNotifications(value);
                      },
                    ),
                    SettingsToggle(
                      icon: Icons.volume_up,
                      label: 'Retours audio',
                      subtitle: 'Sons et vibrations',
                      value: settings.enableAudioFeedback,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setAudioFeedback(value);
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Voix (TTS)',
                  children: [
                    SettingsToggle(
                      icon: Icons.record_voice_over,
                      label: 'Annonces vocales',
                      subtitle: 'Activer la synthèse vocale pour le miroir',
                      value: settings.ttsEnabled,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsEnabled(value);
                      },
                    ),
                    SettingsDropdown<String>(
                      icon: Icons.language,
                      label: 'Langue de la voix',
                      value: settings.ttsLanguage,
                      items: const [
                        DropdownMenuItem(
                          value: 'fr-FR',
                          child: Text(
                            'Français (France)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en-US',
                          child: Text(
                            'English (US)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setTtsLanguage(value);
                        }
                      },
                    ),
                    SettingsToggle(
                      icon: Icons.accessibility_new,
                      label: 'Inclure la morphologie détectée',
                      subtitle:
                          'Prononcer aussi le type de morphologie dans les annonces',
                      value: settings.ttsAnnounceMorphology,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsAnnounceMorphology(value);
                      },
                    ),
                    SettingsSlider(
                      icon: Icons.speed,
                      label: 'Vitesse de lecture',
                      value: settings.ttsSpeechRate,
                      min: 0.25,
                      max: 0.75,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsSpeechRate(value);
                      },
                    ),
                    SettingsSlider(
                      icon: Icons.tune,
                      label: 'Tonalité de la voix',
                      value: settings.ttsPitch,
                      min: 0.7,
                      max: 1.4,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsPitch(value);
                      },
                    ),
                    SettingsDropdown<int>(
                      icon: Icons.timer_off,
                      label: 'Anti-répétition des annonces',
                      value: settings.ttsMinRepeatSeconds,
                      items: const [
                        DropdownMenuItem(
                          value: 15,
                          child: Text(
                            '15 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(
                            '30 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text(
                            '45 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(
                            '60 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text(
                            '90 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setTtsMinRepeatSeconds(value);
                        }
                      },
                    ),
                    SettingsToggle(
                      icon: Icons.pause_circle_filled,
                      label: 'Interrompre l\'annonce en cours',
                      subtitle: 'Évite les annonces qui s\'empilent',
                      value: settings.ttsInterruptCurrent,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsInterruptCurrent(value);
                      },
                    ),
                    SettingsButton(
                      icon: Icons.play_arrow,
                      label: 'Tester la voix',
                      onPressed: () {
                        final tts = ref.read(ttsServiceProvider);
                        final testSpeech = settings.ttsLanguage.startsWith('en')
                            ? 'Voice test. Your text to speech preferences are now applied.'
                            : 'Test vocal. Vos préférences de synthèse vocale sont appliquées.';
                        tts.speak(
                          testSpeech,
                          enabled:
                              settings.enableAudioFeedback &&
                              settings.ttsEnabled,
                          interruptCurrent: settings.ttsInterruptCurrent,
                          language: settings.ttsLanguage,
                          speechRate: settings.ttsSpeechRate,
                          pitch: settings.ttsPitch,
                          minRepeatInterval: const Duration(seconds: 1),
                        );
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Localisation & Météo',
                  children: [
                    SettingsToggle(
                      icon: Icons.location_on,
                      label: 'Suivi de localisation',
                      subtitle: 'Utiliser votre position pour la météo',
                      value: settings.enableLocationTracking,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setLocationTracking(value);
                      },
                    ),
                    SettingsTextField(
                      icon: Icons.location_city,
                      label: 'Ville par défaut',
                      initialValue: settings.defaultCity,
                      hint: 'Ex: Antananarivo',
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setDefaultCity(value);
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Calendrier',
                  children: [
                    SettingsToggle(
                      icon: Icons.calendar_today,
                      label: 'Agenda cloud au démarrage',
                      subtitle:
                          'Synchroniser votre agenda Supabase au lancement',
                      value: settings.syncCalendarOnStartup,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setSyncCalendarOnStartup(value);
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Caméra',
                  children: [
                    SettingsToggle(
                      icon: Icons.flip,
                      label: 'Inverser caméra',
                      subtitle: 'Retourner l\'affichage de la caméra',
                      value: settings.cameraFlipped,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setCameraFlipped(value);
                      },
                    ),
                    SettingsDropdown<String>(
                      icon: Icons.flash_on,
                      label: 'Mode flash',
                      value: settings.cameraFlashMode,
                      items: const [
                        DropdownMenuItem(
                          value: 'off',
                          child: Text(
                            'Désactivé',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'auto',
                          child: Text(
                            'Auto',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'always',
                          child: Text(
                            'Activé',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'torch',
                          child: Text(
                            'Torche',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setCameraFlashMode(value);
                        }
                      },
                    ),
                    SettingsInfo(
                      icon: Icons.info_outline,
                      label: 'Compatibilité',
                      value:
                          'Le zoom et l’exposition se règlent directement sur la caméra avec une interface animée.',
                    ),
                    SettingsDropdown<int>(
                      icon: Icons.timer,
                      label: 'HUD miroir visible',
                      value: settings.mirrorHudDisplaySeconds,
                      items: const [
                        DropdownMenuItem(
                          value: 15,
                          child: Text(
                            '15 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 20,
                          child: Text(
                            '20 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(
                            '30 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text(
                            '45 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(
                            '60 sec',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setMirrorHudDisplaySeconds(value);
                        }
                      },
                    ),
                    SettingsDropdown<int>(
                      icon: Icons.schedule,
                      label: 'HUD miroir toutes les',
                      value: settings.mirrorHudCycleMinutes,
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            '1 minute',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            '2 minutes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(
                            '3 minutes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text(
                            '5 minutes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text(
                            '10 minutes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setMirrorHudCycleMinutes(value);
                        }
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Compte',
                  children: [
                    SettingsActionTile(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Paramètres du compte',
                      iconColor: Colors.tealAccent,
                      onTap: () =>
                          Navigator.pushNamed(context, '/account-settings'),
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Informations',
                  children: [
                    SettingsInfo(
                      icon: Icons.info,
                      label: 'Version',
                      value: settings.appVersion,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Version de l\'application'),
                            content: Text(
                              'Magic Mirror ${settings.appVersion}\n\nVous pouvez consulter les détails dans la page À propos.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/about');
                                },
                                child: const Text('Voir À propos'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SettingsActionTile(
                      icon: Icons.help_outline,
                      label: 'À propos',
                      iconColor: Colors.blueAccent,
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ],
                ),

                SettingsSection(
                  title: 'Paramètres avancés',
                  children: [
                    SettingsActionTile(
                      icon: Icons.restore,
                      label: 'Réinitialiser par défaut',
                      iconColor: Colors.orangeAccent,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Réinitialiser ?'),
                            content: const Text(
                              'Cela va restaurer tous les paramètres par défaut.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(appSettingsProvider.notifier)
                                      .resetToDefaults();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Paramètres réinitialisés'),
                                    ),
                                  );
                                },
                                child: const Text('Réinitialiser'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
