import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_widgets.dart';

class TtsSettingsSection extends ConsumerWidget {
  const TtsSettingsSection({super.key});

  String _secondsLabel(AppLocalizations l10n, int seconds) =>
      '$seconds ${l10n.secondsShort}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(appSettingsProvider.notifier);
    final repeatIntervals = [15, 30, 45, 60, 90];

    return SettingsSection(
      title: l10n.ttsSection,
      children: [
        SettingsToggle(
          icon: Icons.record_voice_over,
          label: l10n.ttsEnabledLabel,
          subtitle: l10n.ttsEnabledSubtitle,
          value: settings.ttsEnabled,
          onChanged: notifier.setTtsEnabled,
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
            if (value != null) notifier.setTtsLanguage(value);
          },
        ),
        SettingsToggle(
          icon: Icons.accessibility_new,
          label: l10n.ttsMorphologyLabel,
          subtitle: l10n.ttsMorphologySubtitle,
          value: settings.ttsAnnounceMorphology,
          onChanged: notifier.setTtsAnnounceMorphology,
        ),
        SettingsSlider(
          icon: Icons.speed,
          label: l10n.ttsSpeechRateLabel,
          value: settings.ttsSpeechRate,
          min: 0.25,
          max: 0.75,
          onChanged: notifier.setTtsSpeechRate,
        ),
        SettingsSlider(
          icon: Icons.tune,
          label: l10n.ttsPitchLabel,
          value: settings.ttsPitch,
          min: 0.7,
          max: 1.4,
          onChanged: notifier.setTtsPitch,
        ),
        SettingsDropdown<int>(
          icon: Icons.timer_off,
          label: l10n.ttsRepeatLabel,
          value: settings.ttsMinRepeatSeconds,
          items: repeatIntervals
              .map(
                (seconds) => DropdownMenuItem(
                  value: seconds,
                  child: Text(
                    _secondsLabel(l10n, seconds),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.setTtsMinRepeatSeconds(value);
          },
        ),
        SettingsToggle(
          icon: Icons.pause_circle_filled,
          label: l10n.ttsInterruptLabel,
          subtitle: l10n.ttsInterruptSubtitle,
          value: settings.ttsInterruptCurrent,
          onChanged: notifier.setTtsInterruptCurrent,
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
              enabled: settings.enableAudioFeedback && settings.ttsEnabled,
              interruptCurrent: settings.ttsInterruptCurrent,
              language: settings.ttsLanguage,
              speechRate: settings.ttsSpeechRate,
              pitch: settings.ttsPitch,
              minRepeatInterval: const Duration(seconds: 1),
            );
          },
        ),
      ],
    );
  }
}
