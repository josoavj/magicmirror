import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_widgets.dart';

class LocationCalendarSettingsSection extends ConsumerWidget {
  const LocationCalendarSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Column(
      children: [
        SettingsSection(
          title: l10n.locationWeatherSection,
          children: [
            SettingsToggle(
              icon: Icons.location_on,
              label: l10n.locationTrackingLabel,
              subtitle: l10n.locationTrackingSubtitle,
              value: settings.enableLocationTracking,
              onChanged: notifier.setLocationTracking,
            ),
            SettingsTextField(
              icon: Icons.location_city,
              label: l10n.defaultCityLabel,
              initialValue: settings.defaultCity,
              hint: l10n.defaultCityHint,
              onChanged: notifier.setDefaultCity,
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
              onChanged: notifier.setSyncCalendarOnStartup,
            ),
          ],
        ),
      ],
    );
  }
}
