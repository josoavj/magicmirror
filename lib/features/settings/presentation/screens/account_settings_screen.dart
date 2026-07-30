import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/settings/presentation/widgets/account_settings_widgets.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _displayNameController.text = profile.displayName;
    _avatarUrlController.text = profile.avatarUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isLoading = ref.watch(authLoadingProvider);
            final error = ref.watch(authErrorProvider);

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Sécurité', style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthTextField(
                        controller: oldPasswordController,
                        label: 'Mot de passe actuel',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: newPasswordController,
                        label: 'Nouveau mot de passe',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: confirmPasswordController,
                        label: 'Confirmer le nouveau',
                        obscureText: true,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Les mots de passe ne correspondent pas.')),
                            );
                            return;
                          }
                          if (newPasswordController.text.length < 6) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Minimum 6 caractères.')),
                            );
                            return;
                          }

                          final success = await ref.read(authServiceProvider).changePassword(
                            oldPassword: oldPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mot de passe mis à jour !')),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final activeUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          child: ListView(
            padding: const EdgeInsets.all(16),
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
                  children: [
                    TextField(
                      controller: _displayNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: accountInputDecoration(
                        _tr(context, 'Nom affiché', 'Display name'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _avatarUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: accountInputDecoration('Avatar URL'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(userProfileProvider.notifier)
                            .updateProfile(
                              displayName: _displayNameController.text,
                              avatarUrl: _avatarUrlController.text,
                            );
                      },
                      child: Text(_tr(context, 'Enregistrer', 'Save')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Sécurité', 'Security'),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                      title: Text(
                        _tr(context, 'Changer le mot de passe', 'Change password'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Actions', 'Actions'),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(
                        _tr(context, 'Se déconnecter', 'Sign out'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (mounted) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
