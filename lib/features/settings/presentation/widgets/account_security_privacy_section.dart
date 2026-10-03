import 'package:flutter/material.dart';
import 'package:magicmirror/features/settings/presentation/widgets/account_settings_widgets.dart';
import 'package:magicmirror/presentation/widgets/framed_list_tile.dart';

class AccountSecurityPrivacySection extends StatelessWidget {
  const AccountSecurityPrivacySection({
    super.key,
    required this.isEnglish,
    required this.onChangePassword,
    required this.onEraseData,
    required this.onDeleteAccount,
    required this.onOpenPrivacy,
  });

  final bool isEnglish;
  final VoidCallback onChangePassword;
  final VoidCallback onEraseData;
  final VoidCallback onDeleteAccount;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String tr(String fr, String en) => isEnglish ? en : fr;
    return AccountSettingsSection(
      title: tr('Sécurité et confidentialité', 'Security and privacy'),
      child: Column(
        children: [
          FramedListTile(
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.blueAccent),
              title: Text(
                tr('Changer le mot de passe', 'Change password'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: onChangePassword,
            ),
          ),
          FramedListTile(
            child: ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: colors.error),
              title: Text(
                tr('Effacer mes données', 'Erase my data'),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                tr(
                  'Efface tes données personnelles en gardant le compte.',
                  'Erase personal data while keeping the account.',
                ),
              ),
              onTap: onEraseData,
            ),
          ),
          FramedListTile(
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: colors.error),
              title: Text(
                tr('Supprimer le compte', 'Delete account'),
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                tr(
                  'Supprime le compte et les données associées.',
                  'Delete the account and associated data.',
                ),
              ),
              onTap: onDeleteAccount,
            ),
          ),
          FramedListTile(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(
                tr('Notice de confidentialité', 'Privacy notice'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: onOpenPrivacy,
            ),
          ),
        ],
      ),
    );
  }
}
