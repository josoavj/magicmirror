import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileAccountSyncSection extends ConsumerWidget {
  const ProfileAccountSyncSection({super.key});

  bool _isEnglish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en';

  String _tr(BuildContext context, String fr, String en) =>
      _isEnglish(context) ? en : fr;

  String _syncMessage(BuildContext context, String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('hors ligne') || normalized.contains('offline')) {
      return _tr(
        context,
        'Vous êtes hors ligne. La synchronisation reprendra dès que la connexion sera rétablie.',
        'You are offline. Sync will resume when your connection is restored.',
      );
    }
    if (normalized.contains('authentification') ||
        normalized.contains('sign in') ||
        normalized.contains('auth')) {
      return _tr(
        context,
        'Connectez-vous pour synchroniser votre profil.',
        'Sign in to sync your profile.',
      );
    }
    if (normalized.contains('déjà utilisé') || normalized.contains('already')) {
      return _tr(
        context,
        'Ce profil est déjà associé à un autre compte.',
        'This profile is already linked to another account.',
      );
    }
    if (normalized.contains('introuvable') ||
        normalized.contains('not found')) {
      return _tr(
        context,
        'Aucun profil synchronisé n’a été trouvé.',
        'No synchronized profile was found.',
      );
    }
    if (normalized.contains('réseau') || normalized.contains('network')) {
      return _tr(
        context,
        'La connexion a échoué. Vérifiez votre réseau et réessayez.',
        'The connection failed. Check your network and try again.',
      );
    }
    return _tr(
      context,
      'La synchronisation a échoué. Veuillez réessayer.',
      'Synchronization failed. Please try again.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final syncStatus = ref.watch(profileSyncStatusProvider);
    final syncMessage = ref.watch(profileSyncMessageProvider);
    final lastSyncAt = ref.watch(profileLastSyncAtProvider);
    final schemaWarning = ref
        .watch(profileSchemaWarningProvider)
        .maybeWhen(data: (warning) => warning, orElse: () => null);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final syncColor = switch (syncStatus) {
      ProfileSyncStatus.syncing || ProfileSyncStatus.success =>
        theme.brightness == Brightness.dark
            ? Colors.greenAccent
            : Colors.green.shade700,
      ProfileSyncStatus.failure =>
        theme.brightness == Brightness.dark
            ? Colors.redAccent
            : Colors.red.shade700,
      ProfileSyncStatus.idle => colors.primary,
    };
    final syncIcon = switch (syncStatus) {
      ProfileSyncStatus.success => Icons.cloud_done_outlined,
      ProfileSyncStatus.failure => Icons.cloud_off_outlined,
      ProfileSyncStatus.idle ||
      ProfileSyncStatus.syncing => Icons.cloud_sync_outlined,
    };
    final syncButtonColor = switch (syncStatus) {
      ProfileSyncStatus.syncing || ProfileSyncStatus.failure => syncColor,
      ProfileSyncStatus.idle || ProfileSyncStatus.success => colors.primary,
    };
    final syncButtonLabel = switch (syncStatus) {
      ProfileSyncStatus.syncing => _tr(context, 'Synchronisation…', 'Syncing…'),
      ProfileSyncStatus.failure => _tr(
        context,
        'Échec · Réessayer',
        'Sync failed · Retry',
      ),
      ProfileSyncStatus.idle ||
      ProfileSyncStatus.success => _tr(context, 'Synchroniser', 'Sync now'),
    };

    return ProfileSectionCard(
      title: _tr(context, 'Compte', 'Account'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoLine(
            Icons.email_outlined,
            'Email',
            activeUser?.email ?? _tr(context, 'Mode local', 'Local profile'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: syncStatus == ProfileSyncStatus.syncing
                    ? SizedBox(
                        key: const ValueKey('profile-sync-progress'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: syncColor,
                        ),
                      )
                    : Icon(
                        syncIcon,
                        key: ValueKey(syncStatus),
                        color: syncColor,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  syncStatus == ProfileSyncStatus.failure
                      ? _syncMessage(context, syncMessage)
                      : syncMessage,
                  style: TextStyle(color: syncColor),
                ),
              ),
            ],
          ),
          if (lastSyncAt != null) ...[
            const SizedBox(height: 8),
            _infoLine(
              Icons.history,
              _tr(context, 'Dernière synchronisation', 'Last sync'),
              formatDisplayDateTime(
                lastSyncAt,
                locale: _isEnglish(context) ? 'en_US' : 'fr_FR',
              ),
            ),
          ],
          if (schemaWarning != null && schemaWarning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: colors.tertiary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schemaWarning,
                    style: TextStyle(color: colors.tertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      activeUser == null ||
                          syncStatus == ProfileSyncStatus.syncing
                      ? null
                      : () => ref
                            .read(userProfileProvider.notifier)
                            .syncToCloud(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: syncButtonColor,
                    disabledForegroundColor: syncButtonColor,
                    side: BorderSide(
                      color: syncButtonColor.withValues(alpha: 0.65),
                    ),
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: syncStatus == ProfileSyncStatus.syncing
                        ? SizedBox(
                            key: const ValueKey('sync-button-progress'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: syncButtonColor,
                            ),
                          )
                        : Icon(
                            syncStatus == ProfileSyncStatus.failure
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_upload_outlined,
                            key: ValueKey('sync-button-$syncStatus'),
                          ),
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      syncButtonLabel,
                      key: ValueKey('sync-label-$syncStatus'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/account-settings'),
                  icon: const Icon(Icons.security_outlined),
                  label: Text(
                    _tr(context, 'Sécurité du compte', 'Account security'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) =>
      ProfileReadOnlyInfoRow(icon: icon, label: label, value: value);
}
