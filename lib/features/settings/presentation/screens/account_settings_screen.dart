import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:magicmirror/features/settings/presentation/widgets/account_settings_widgets.dart';
import 'package:magicmirror/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:magicmirror/features/settings/presentation/widgets/profile_edit_dialog.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_widgets.dart';
import 'package:magicmirror/presentation/widgets/framed_list_tile.dart';
import 'package:magicmirror/presentation/widgets/glass_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  String _buildUsername(User? activeUser, String fallbackUserId) {
    final email = activeUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) return '@$localPart';
    }
    final fallback = fallbackUserId.trim();
    return fallback.isNotEmpty ? '@$fallback' : '@utilisateur';
  }

  void _editProfile(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider);
    showGlassDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileEditDialog(profile: profile),
    );
  }

  void _changePassword(BuildContext context) {
    showGlassDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final activeUser = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(userProfileProvider);
    final username = _buildUsername(activeUser, profile.userId);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(isEnglish ? 'Account Settings' : 'Paramètres du compte'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AccountSettingsSection(
                title: _tr(context, 'Compte actif', 'Active account'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${activeUser?.email ?? _tr(context, 'Non connecté', 'Not connected')}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${activeUser?.id ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Profil', 'Profile'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeader(
                      displayName: profile.displayName,
                      username: username,
                      avatarUrl: profile.avatarUrl,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _tr(
                        context,
                        'Les informations personnelles se modifient ici.',
                        'Personal information is edited here.',
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _editProfile(context, ref),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          _tr(context, 'Modifier le profil', 'Edit profile'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Sécurité', 'Security'),
                child: FramedListTile(
                  child: ListTile(
                    leading: const Icon(
                      Icons.lock_outline,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      _tr(
                        context,
                        'Changer le mot de passe',
                        'Change password',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => _changePassword(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Actions', 'Actions'),
                child: FramedListTile(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(
                      _tr(context, 'Se déconnecter', 'Sign out'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
