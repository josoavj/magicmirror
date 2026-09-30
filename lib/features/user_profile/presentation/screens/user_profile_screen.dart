import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_account_sync_section.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_summary_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  String _buildUsername(User? activeUser, UserProfile profile) {
    final email = activeUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) return '@$localPart';
    }

    final fallback = profile.userId.trim();
    return fallback.isNotEmpty ? '@$fallback' : '@utilisateur';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final username = _buildUsername(activeUser, profile);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'My profile'
              : 'Mon profil',
        ),
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surface, colors.surfaceContainerHighest],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const ProfileAccountSyncSection(),
              const SizedBox(height: 16),
              ProfileSummarySection(profile: profile, username: username),
            ],
          ),
        ),
      ),
    );
  }
}
