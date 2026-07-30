import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);
final authErrorProvider = StateProvider<String?>((ref) => null);
final authInfoProvider = StateProvider<String?>((ref) => null);

/// Nombre de tentatives de connexion échouées consécutives
final authFailedAttemptsProvider = StateProvider<int>((ref) => 0);

/// Heure à laquelle le verrouillage expire
final authLockoutTimeProvider = StateProvider<DateTime?>((ref) => null);

final authServiceProvider = Provider((ref) => AuthService(ref));

class AuthService {
  final Ref _ref;
  AuthService(this._ref);

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    // Vérifier si le verrouillage est actif
    final lockoutTime = _ref.read(authLockoutTimeProvider);
    if (lockoutTime != null && DateTime.now().isBefore(lockoutTime)) {
      return;
    }

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
        // Réinitialiser les compteurs sur succès
        _ref.read(authFailedAttemptsProvider.notifier).state = 0;
        _ref.read(authLockoutTimeProvider.notifier).state = null;
        
        await _ref.read(userProfileProvider.notifier).setUserId(userId);
      }
    } on AuthException catch (e) {
      _handleSignInFailure(e.message);
    } catch (_) {
      _handleSignInFailure('Une erreur est survenue, veuillez réessayer.');
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  void _handleSignInFailure(String message) {
    _ref.read(authErrorProvider.notifier).state = message;
    
    final attempts = _ref.read(authFailedAttemptsProvider.notifier).state += 1;
    
    // Verrouillage progressif
    if (attempts >= 10) {
      // 15 minutes pour les cas extrêmes
      _ref.read(authLockoutTimeProvider.notifier).state = 
          DateTime.now().add(const Duration(minutes: 15));
    } else if (attempts >= 5) {
      // 5 minutes
      _ref.read(authLockoutTimeProvider.notifier).state = 
          DateTime.now().add(const Duration(minutes: 5));
    } else if (attempts >= 3) {
      // 30 secondes
      _ref.read(authLockoutTimeProvider.notifier).state = 
          DateTime.now().add(const Duration(seconds: 30));
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

  /// Change le mot de passe de l'utilisateur après vérification de l'ancien
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) throw const AuthException('Utilisateur non identifié');

      // 1. Vérification de l'ancien mot de passe (Re-authentification)
      await _client.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );

      // 2. Si succès, mise à jour vers le nouveau
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      
      _ref.read(authInfoProvider.notifier).state = 'Mot de passe mis à jour avec succès.';
      return true;
    } on AuthException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      return false;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = 'Erreur lors du changement de mot de passe.';
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _ref.read(userProfileProvider.notifier).setUserId('');
  }
}
