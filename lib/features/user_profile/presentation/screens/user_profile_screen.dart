import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(userProfileProvider);
    final activeUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'User Profile' : 'Profil utilisateur'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProfileSectionCard(
                  title: _tr(context, 'Compte', 'Account'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: ${activeUser?.email ?? _tr(context, 'Non connecté', 'Not connected')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/account-settings');
                        },
                        child: Text(_tr(context, 'Gérer mon compte', 'Manage')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ProfileSectionCard(
                  title: _tr(context, 'Identité', 'Identity'),
                  child: Column(
                    children: [
                      ProfileHeader(
                        displayName: profile.displayName,
                        avatarUrl: profile.avatarUrl,
                      ),
                      const SizedBox(height: 16),
                      ProfileReadOnlyInfoRow(
                        icon: Icons.person,
                        label: _tr(context, 'Nom', 'Name'),
                        value: profile.displayName,
                      ),
                      const SizedBox(height: 12),
                      ProfileReadOnlyInfoRow(
                        icon: Icons.wc,
                        label: _tr(context, 'Sexe', 'Gender'),
                        value: profile.gender,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
