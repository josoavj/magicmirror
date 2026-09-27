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
                const SizedBox(height: 16),
                ProfileSectionCard(
                  title: _tr(context, 'Détails physiques', 'Physical Details'),
                  child: Column(
                    children: [
                      ProfileReadOnlyInfoRow(
                        icon: Icons.calendar_today,
                        label: _tr(context, 'Âge', 'Age'),
                        value: '${profile.age} ${_tr(context, 'ans', 'years')}',
                      ),
                      const SizedBox(height: 12),
                      ProfileReadOnlyInfoRow(
                        icon: Icons.straighten,
                        label: _tr(context, 'Taille', 'Height'),
                        value: '${profile.heightCm} cm',
                      ),
                      const SizedBox(height: 12),
                      ProfileReadOnlyInfoRow(
                        icon: Icons.accessibility_new,
                        label: _tr(context, 'Morphologie', 'Body Type'),
                        value: profile.morphology,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ProfileSectionCard(
                  title: _tr(context, 'Styles préférés', 'Preferred Styles'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        profile.preferredStyles.map((style) {
                          return Chip(
                            label: Text(
                              style,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
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
