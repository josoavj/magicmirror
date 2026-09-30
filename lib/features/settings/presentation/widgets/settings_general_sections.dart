import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_widgets.dart';

class SettingsGeneralSections extends ConsumerWidget {
  const SettingsGeneralSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        SettingsSection(
          title: l10n.accountSection,
          children: [
            SettingsActionTile(
              icon: Icons.manage_accounts_outlined,
              label: l10n.accountSettingsLabel,
              iconColor: Colors.tealAccent,
              onTap: () => Navigator.pushNamed(context, '/account-settings'),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.outfitSuggestionsSection,
          children: [
            SettingsActionTile(
              icon: Icons.tune,
              label: l10n.outfitSuggestionsSettingsLabel,
              iconColor: Colors.lightBlueAccent,
              onTap: () =>
                  Navigator.pushNamed(context, '/settings/outfit-insights'),
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
              onTap: () =>
                  _showVersionDialog(context, l10n, settings.appVersion),
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
              onTap: () => _showResetDialog(context, ref, l10n),
            ),
          ],
        ),
      ],
    );
  }

  void _showVersionDialog(
    BuildContext context,
    AppLocalizations l10n,
    String appVersion,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.appVersionDialogTitle),
        content: Text(l10n.appVersionDialogBody(appVersion)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.closeButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, '/about');
            },
            child: Text(l10n.seeAboutButton),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetDialogTitle),
        content: Text(l10n.resetDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).resetToDefaults();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.settingsResetToast)));
            },
            child: Text(l10n.resetButton),
          ),
        ],
      ),
    );
  }
}
