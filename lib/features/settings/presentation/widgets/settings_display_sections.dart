import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_widgets.dart';

class DisplaySettingsSection extends ConsumerWidget {
  const DisplaySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(appSettingsProvider.notifier);

    return SettingsSection(
      title: l10n.displaySection,
      children: [
        SettingsToggle(
          icon: Icons.dark_mode,
          label: l10n.darkModeLabel,
          subtitle: l10n.darkModeSubtitle,
          value: settings.darkMode,
          onChanged: notifier.setDarkMode,
        ),
        SettingsToggle(
          icon: Icons.speed,
          label: 'Mode Performance',
          subtitle: 'Désactive les effets de flou pour plus de fluidité',
          value: settings.lowPerformanceMode,
          onChanged: notifier.setLowPerformanceMode,
        ),
        SettingsDropdown<String>(
          icon: Icons.language,
          label: l10n.languageLabel,
          value: settings.locale,
          items: const [
            DropdownMenuItem(value: 'fr_FR', child: Text('Français')),
            DropdownMenuItem(value: 'en_US', child: Text('English')),
          ],
          onChanged: (value) {
            if (value != null) notifier.setLocale(value);
          },
        ),
      ],
    );
  }
}

class NotificationSettingsSection extends ConsumerWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(appSettingsProvider.notifier);

    return SettingsSection(
      title: l10n.notificationsSoundSection,
      children: [
        SettingsToggle(
          icon: Icons.notifications,
          label: l10n.notificationsLabel,
          subtitle: l10n.notificationsSubtitle,
          value: settings.enableNotifications,
          onChanged: notifier.setNotifications,
        ),
        SettingsToggle(
          icon: Icons.volume_up,
          label: l10n.audioFeedbackLabel,
          subtitle: l10n.audioFeedbackSubtitle,
          value: settings.enableAudioFeedback,
          onChanged: notifier.setAudioFeedback,
        ),
      ],
    );
  }
}
