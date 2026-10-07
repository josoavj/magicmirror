import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/error/offline_queue.dart';
import 'package:magicmirror/core/services/cache_service.dart';
import 'package:magicmirror/core/services/storage_service.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_favorites_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_shared_providers.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/weather/data/services/weather_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AccountDataAction { erasePersonalData, deleteAccount }

class AccountDataService {
  Future<void> execute({
    required WidgetRef ref,
    required String password,
    required AccountDataAction action,
    required bool isEnglish,
  }) async {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    final email = currentUser?.email?.trim();
    if (currentUser == null || email == null || email.isEmpty) {
      throw AccountDataException(
        isEnglish
            ? 'No email-and-password account is currently signed in.'
            : 'Aucun compte e-mail avec mot de passe n’est connecté.',
      );
    }

    try {
      final verification = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (verification.user?.id != currentUser.id) {
        throw AccountDataException(
          isEnglish
              ? 'Account verification failed. Sign in again and retry.'
              : 'La vérification du compte a échoué. Reconnecte-toi puis réessaie.',
        );
      }
    } on AuthException {
      throw AccountDataException(
        isEnglish ? 'Incorrect password.' : 'Mot de passe incorrect.',
      );
    }

    final favorites = ref.read(outfitFavoritesProvider.notifier);
    await favorites.beginPrivacyPurge();
    var remotePurgeCompleted = false;
    try {
      final response = await client.functions.invoke(
        'account-data',
        body: {
          'action': action == AccountDataAction.deleteAccount
              ? 'delete_account'
              : 'erase_data',
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw AccountDataException(
          isEnglish
              ? 'Supabase did not confirm the deletion (HTTP ${response.status}).'
              : 'Supabase n’a pas confirmé la suppression (HTTP ${response.status}).',
        );
      }
      if (response.data is! Map || response.data['success'] != true) {
        throw AccountDataException(
          isEnglish
              ? 'Supabase did not confirm the deletion.'
              : 'Supabase n’a pas confirmé la suppression.',
        );
      }
      remotePurgeCompleted = true;

      if (action == AccountDataAction.deleteAccount) {
        try {
          await favorites.finishPrivacyPurge();
          await _clearLocalData(ref);
        } finally {
          // The account is already deleted remotely; always clear its local
          // session, even if a device cache cannot be removed.
          await client.auth.signOut(scope: SignOutScope.local);
        }
      } else {
        await favorites.finishPrivacyPurge();
        await _clearLocalData(ref);
      }
    } catch (error) {
      if (!remotePurgeCompleted) favorites.cancelPrivacyPurge();
      if (error is AccountDataException) rethrow;
      if (error is FunctionException) {
        throw AccountDataException(
          isEnglish
              ? 'The Supabase deletion service is unavailable or refused the request. Check that it is deployed and retry.'
              : 'Le service Supabase de suppression est indisponible ou a refusé la demande. Vérifie son déploiement et réessaie.',
        );
      }
      if (remotePurgeCompleted) {
        throw AccountDataException(
          action == AccountDataAction.deleteAccount
              ? (isEnglish
                    ? 'The account was deleted, but this device could not finish clearing local data. Restart the app.'
                    : 'Le compte a été supprimé, mais l’appareil n’a pas terminé la purge locale. Redémarre l’application.')
              : (isEnglish
                    ? 'Cloud data was erased, but this device could not finish clearing local data. Restart the app or retry.'
                    : 'Les données cloud ont été effacées, mais l’appareil n’a pas terminé la purge locale. Redémarre l’application ou réessaie.'),
        );
      }
      logger.error(
        'Échec de l’effacement des données du compte',
        tag: 'AccountDataService',
        error: error,
      );
      throw AccountDataException(
        isEnglish
            ? 'The request could not be completed. Check your connection and retry.'
            : 'La demande n’a pas pu être terminée. Vérifie ta connexion et réessaie.',
      );
    }
  }

  Future<void> _clearLocalData(WidgetRef ref) async {
    await ref.read(userProfileProvider.notifier).clearPersonalData();
    await ref.read(outfitPersonalizationProvider.notifier).clearPersonalData();
    await ref.read(outfitTelemetryProvider.notifier).reset();
    await ref.read(storageServiceProvider).remove('defaultCity');
    ref.invalidate(appSettingsProvider);
    await OfflineQueue.clear();
    await WeatherService.clearPersonalCache();
    cacheService.invalidatePattern('weather.');
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await logger.clearLogs();
    ref.invalidate(agendaEventsProvider);
  }
}

class AccountDataException implements Exception {
  const AccountDataException(this.message);
  final String message;

  @override
  String toString() => message;
}
