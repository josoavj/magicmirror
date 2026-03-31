import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Parametres'),
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
                      subtitle: 'Utiliser le theme sombre',
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
                            'Francais',
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
                  title: 'Localisation & Meteo',
                  children: [
                    SettingsToggle(
                      icon: Icons.location_on,
                      label: 'Suivi de localisation',
                      subtitle: 'Utiliser votre position pour la meteo',
                      value: settings.enableLocationTracking,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setLocationTracking(value);
                      },
                    ),
                    SettingsTextField(
                      icon: Icons.location_city,
                      label: 'Ville par defaut',
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
                      label: 'Agenda cloud au demarrage',
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
                  title: 'Camera',
                  children: [
                    SettingsToggle(
                      icon: Icons.flip,
                      label: 'Inverser camera',
                      subtitle: 'Retourner l\'affichage de la camera',
                      value: settings.cameraFlipped,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setCameraFlipped(value);
                      },
                    ),
                    SettingsSlider(
                      icon: Icons.zoom_in,
                      label: 'Zoom camera',
                      value: settings.cameraZoom,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setCameraZoom(value);
                      },
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
                      label: 'Parametres du compte',
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
                  title: 'Parametres Avancés',
                  children: [
                    SettingsActionTile(
                      icon: Icons.restore,
                      label: 'Reinitialiser par defaut',
                      iconColor: Colors.orangeAccent,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reinitialiser?'),
                            content: const Text(
                              'Cela va restaurer tous les parametres par defaut.',
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
                                      content: Text('Parametres reinitialises'),
                                    ),
                                  );
                                },
                                child: const Text('Reinitialiser'),
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
