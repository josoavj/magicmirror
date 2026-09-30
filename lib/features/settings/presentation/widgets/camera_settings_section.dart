import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_widgets.dart';

class CameraSettingsSection extends ConsumerWidget {
  const CameraSettingsSection({super.key});

  String _secondsLabel(AppLocalizations l10n, int seconds) =>
      '$seconds ${l10n.secondsShort}';

  String _minutesLabel(AppLocalizations l10n, int minutes) =>
      '$minutes ${minutes > 1 ? l10n.minutePlural : l10n.minuteSingular}';

  List<DropdownMenuItem<String>> _cameraProfiles(AppLocalizations l10n) => [
    DropdownMenuItem(
      value: 'auto',
      child: Text(l10n.cameraProfileAuto, style: _menuTextStyle),
    ),
    DropdownMenuItem(
      value: 'low',
      child: Text(l10n.cameraProfileLow, style: _menuTextStyle),
    ),
    DropdownMenuItem(
      value: 'medium',
      child: Text(l10n.cameraProfileMedium, style: _menuTextStyle),
    ),
    DropdownMenuItem(
      value: 'high',
      child: Text(l10n.cameraProfileHigh, style: _menuTextStyle),
    ),
  ];

  static const _menuTextStyle = TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(appSettingsProvider.notifier);
    final hudDurations = [15, 20, 30, 45, 60];
    final hudIntervals = [1, 2, 3, 5, 10];

    return SettingsSection(
      title: l10n.cameraSection,
      children: [
        SettingsToggle(
          icon: Icons.flip,
          label: l10n.cameraFlipLabel,
          subtitle: l10n.cameraFlipSubtitle,
          value: settings.cameraFlipped,
          onChanged: notifier.setCameraFlipped,
        ),
        SettingsDropdown<String>(
          icon: Icons.speed,
          label: l10n.cameraProfileLabel,
          value: settings.cameraProfile,
          items: _cameraProfiles(l10n),
          onChanged: (value) {
            if (value != null) notifier.setCameraProfile(value);
          },
        ),
        SettingsInfo(
          icon: Icons.info_outline,
          label: l10n.cameraProfileLabel,
          value: l10n.cameraProfileSubtitle,
        ),
        SettingsDropdown<String>(
          icon: Icons.flash_on,
          label: l10n.flashModeLabel,
          value: settings.cameraFlashMode,
          items: [
            DropdownMenuItem(
              value: 'off',
              child: Text(l10n.flashOff, style: _menuTextStyle),
            ),
            DropdownMenuItem(
              value: 'auto',
              child: Text(l10n.flashAuto, style: _menuTextStyle),
            ),
            DropdownMenuItem(
              value: 'always',
              child: Text(l10n.flashAlways, style: _menuTextStyle),
            ),
            DropdownMenuItem(
              value: 'torch',
              child: Text(l10n.flashTorch, style: _menuTextStyle),
            ),
          ],
          onChanged: (value) {
            if (value != null) notifier.setCameraFlashMode(value);
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
          items: hudDurations
              .map(
                (seconds) => DropdownMenuItem(
                  value: seconds,
                  child: Text(
                    _secondsLabel(l10n, seconds),
                    style: _menuTextStyle,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.setMirrorHudDisplaySeconds(value);
          },
        ),
        SettingsDropdown<int>(
          icon: Icons.schedule,
          label: l10n.mirrorHudEveryLabel,
          value: settings.mirrorHudCycleMinutes,
          items: hudIntervals
              .map(
                (minutes) => DropdownMenuItem(
                  value: minutes,
                  child: Text(
                    _minutesLabel(l10n, minutes),
                    style: _menuTextStyle,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.setMirrorHudCycleMinutes(value);
          },
        ),
      ],
    );
  }
}
