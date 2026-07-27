import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);
final authErrorProvider = StateProvider<String?>((ref) => null);
final authInfoProvider = StateProvider<String?>((ref) => null);

final authServiceProvider = Provider((ref) => AuthService(ref));

class AuthService {
  final Ref _ref;
  AuthService(this._ref);

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    _ref.read(authInfoProvider.notifier).state = null;

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        await _ref.read(userProfileProvider.notifier).setUserId(userId);
      }
    } on AuthException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Une erreur est survenue, veuillez réessayer.';
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String gender,
    required DateTime birthDate,
    required int heightCm,
    required String morphology,
    required List<String> preferredStyles,
    String? avatarUrl,
  }) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      await _ref.read(userProfileProvider.notifier).applyOnboardingProfile(
        userId: response.user?.id,
        displayName: displayName,
        avatarUrl: avatarUrl ?? '',
        gender: gender,
        birthDate: birthDate,
        heightCm: heightCm,
        morphology: morphology,
        preferredStyles: preferredStyles,
        syncIfConnected: response.session != null,
      );

      if (response.session == null) {
        _ref.read(authInfoProvider.notifier).state =
            'Compte créé. Confirmez votre email puis connectez-vous.';
      } else {
        _ref.read(authInfoProvider.notifier).state =
            'Compte créé et profil initialisé.';
      }
    } on AuthException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Une erreur est survenue, veuillez réessayer.';
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> resetPassword(String email) async {
    _ref.read(authErrorProvider.notifier).state = null;
    _ref.read(authInfoProvider.notifier).state = null;

    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      _ref.read(authInfoProvider.notifier).state =
          'Email de réinitialisation envoyé.';
    } on AuthException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Impossible d\'envoyer l\'email de réinitialisation.';
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _ref.read(userProfileProvider.notifier).setUserId('');
  }
}
