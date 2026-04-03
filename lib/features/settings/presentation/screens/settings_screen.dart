import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);

    String secondsLabel(int seconds) => '$seconds ${l10n.secondsShort}';
    String minutesLabel(int minutes) =>
        '$minutes ${minutes > 1 ? l10n.minutePlural : l10n.minuteSingular}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
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
                  title: l10n.displaySection,
                  children: [
                    SettingsToggle(
                      icon: Icons.dark_mode,
                      label: l10n.darkModeLabel,
                      subtitle: l10n.darkModeSubtitle,
                      value: settings.darkMode,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setDarkMode(value);
                      },
                    ),
                    SettingsDropdown<String>(
                      icon: Icons.language,
                      label: l10n.languageLabel,
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
                  title: l10n.notificationsSoundSection,
                  children: [
                    SettingsToggle(
                      icon: Icons.notifications,
                      label: l10n.notificationsLabel,
                      subtitle: l10n.notificationsSubtitle,
                      value: settings.enableNotifications,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setNotifications(value);
                      },
                    ),
                    SettingsToggle(
                      icon: Icons.volume_up,
                      label: l10n.audioFeedbackLabel,
                      subtitle: l10n.audioFeedbackSubtitle,
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
                  title: l10n.ttsSection,
                  children: [
                    SettingsToggle(
                      icon: Icons.record_voice_over,
                      label: l10n.ttsEnabledLabel,
                      subtitle: l10n.ttsEnabledSubtitle,
                      value: settings.ttsEnabled,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsEnabled(value);
                      },
                    ),
                    SettingsDropdown<String>(
                      icon: Icons.language,
                      label: l10n.ttsLanguageLabel,
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
                      label: l10n.ttsMorphologyLabel,
                      subtitle: l10n.ttsMorphologySubtitle,
                      value: settings.ttsAnnounceMorphology,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsAnnounceMorphology(value);
                      },
                    ),
                    SettingsSlider(
                      icon: Icons.speed,
                      label: l10n.ttsSpeechRateLabel,
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
                      label: l10n.ttsPitchLabel,
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
                      label: l10n.ttsRepeatLabel,
                      value: settings.ttsMinRepeatSeconds,
                      items: [
                        DropdownMenuItem(
                          value: 15,
                          child: Text(
                            secondsLabel(15),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(
                            secondsLabel(30),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text(
                            secondsLabel(45),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(
                            secondsLabel(60),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text(
                            secondsLabel(90),
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
                      label: l10n.ttsInterruptLabel,
                      subtitle: l10n.ttsInterruptSubtitle,
                      value: settings.ttsInterruptCurrent,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setTtsInterruptCurrent(value);
                      },
                    ),
                    SettingsButton(
                      icon: Icons.play_arrow,
                      label: l10n.ttsTestButton,
                      onPressed: () {
                        final tts = ref.read(ttsServiceProvider);
                        final testSpeech = settings.ttsLanguage.startsWith('en')
                            ? l10n.ttsTestSpeechEn
                            : l10n.ttsTestSpeechFr;
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
                  title: l10n.locationWeatherSection,
                  children: [
                    SettingsToggle(
                      icon: Icons.location_on,
                      label: l10n.locationTrackingLabel,
                      subtitle: l10n.locationTrackingSubtitle,
                      value: settings.enableLocationTracking,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setLocationTracking(value);
                      },
                    ),
                    SettingsTextField(
                      icon: Icons.location_city,
                      label: l10n.defaultCityLabel,
                      initialValue: settings.defaultCity,
                      hint: l10n.defaultCityHint,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setDefaultCity(value);
                      },
                    ),
                  ],
                ),

                SettingsSection(
                  title: l10n.calendarSection,
                  children: [
                    SettingsToggle(
                      icon: Icons.calendar_today,
                      label: l10n.calendarSyncLabel,
                      subtitle: l10n.calendarSyncSubtitle,
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
                  title: l10n.cameraSection,
                  children: [
                    SettingsToggle(
                      icon: Icons.flip,
                      label: l10n.cameraFlipLabel,
                      subtitle: l10n.cameraFlipSubtitle,
                      value: settings.cameraFlipped,
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setCameraFlipped(value);
                      },
                    ),
                    SettingsDropdown<String>(
                      icon: Icons.flash_on,
                      label: l10n.flashModeLabel,
                      value: settings.cameraFlashMode,
                      items: [
                        DropdownMenuItem(
                          value: 'off',
                          child: Text(
                            l10n.flashOff,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'auto',
                          child: Text(
                            l10n.flashAuto,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'always',
                          child: Text(
                            l10n.flashAlways,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'torch',
                          child: Text(
                            l10n.flashTorch,
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
                      label: l10n.compatibilityLabel,
                      value: l10n.cameraControlInfo,
                    ),
                    SettingsDropdown<int>(
                      icon: Icons.timer,
                      label: l10n.mirrorHudVisibleLabel,
                      value: settings.mirrorHudDisplaySeconds,
                      items: [
                        DropdownMenuItem(
                          value: 15,
                          child: Text(
                            secondsLabel(15),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 20,
                          child: Text(
                            secondsLabel(20),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(
                            secondsLabel(30),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text(
                            secondsLabel(45),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(
                            secondsLabel(60),
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
                      label: l10n.mirrorHudEveryLabel,
                      value: settings.mirrorHudCycleMinutes,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            minutesLabel(1),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            minutesLabel(2),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(
                            minutesLabel(3),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text(
                            minutesLabel(5),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text(
                            minutesLabel(10),
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
                  title: l10n.accountSection,
                  children: [
                    SettingsActionTile(
                      icon: Icons.manage_accounts_outlined,
                      label: l10n.accountSettingsLabel,
                      iconColor: Colors.tealAccent,
                      onTap: () =>
                          Navigator.pushNamed(context, '/account-settings'),
                    ),
                  ],
                ),

                SettingsSection(
                  title: l10n.informationSection,
                  children: [
                    SettingsInfo(
                      icon: Icons.info,
                      label: l10n.versionLabel,
                      value: settings.appVersion,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.appVersionDialogTitle),
                            content: Text(
                              l10n.appVersionDialogBody(settings.appVersion),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.closeButton),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/about');
                                },
                                child: Text(l10n.seeAboutButton),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SettingsActionTile(
                      icon: Icons.help_outline,
                      label: l10n.aboutLabel,
                      iconColor: Colors.blueAccent,
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ],
                ),

                SettingsSection(
                  title: l10n.advancedSection,
                  children: [
                    SettingsActionTile(
                      icon: Icons.restore,
                      label: l10n.resetDefaultsLabel,
                      iconColor: Colors.orangeAccent,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.resetDialogTitle),
                            content: Text(l10n.resetDialogBody),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancelButton),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(appSettingsProvider.notifier)
                                      .resetToDefaults();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.settingsResetToast),
                                    ),
                                  );
                                },
                                child: Text(l10n.resetButton),
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
