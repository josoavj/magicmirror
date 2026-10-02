import 'package:flutter/widgets.dart';

/// Turns technical or provider errors into short, localized messages for users.
String userFacingError(
  BuildContext context,
  Object? error, {
  required String frenchFallback,
  required String englishFallback,
}) {
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final message = error?.toString().toLowerCase() ?? '';

  if (message.contains('invalid login credentials') ||
      message.contains('invalid_credentials') ||
      message.contains('invalid password')) {
    return isEnglish
        ? 'The email address or password is incorrect.'
        : 'L’adresse e-mail ou le mot de passe est incorrect.';
  }
  if (message.contains('email not confirmed') ||
      message.contains('email_not_confirmed')) {
    return isEnglish
        ? 'Please verify your email address before signing in.'
        : 'Veuillez confirmer votre adresse e-mail avant de vous connecter.';
  }
  if (message.contains('user already registered') ||
      message.contains('already registered') ||
      message.contains('user_already_exists')) {
    return isEnglish
        ? 'An account already exists for this email address.'
        : 'Un compte existe déjà pour cette adresse e-mail.';
  }
  if (message.contains('invalid email') ||
      message.contains('email_address_invalid')) {
    return isEnglish
        ? 'Please enter a valid email address.'
        : 'Veuillez saisir une adresse e-mail valide.';
  }
  if (message.contains('password') &&
      (message.contains('weak') ||
          message.contains('at least') ||
          message.contains('minimum'))) {
    return isEnglish
        ? 'Choose a stronger password that meets the minimum length.'
        : 'Choisissez un mot de passe plus sûr qui respecte la longueur minimale.';
  }
  if (message.contains('rate limit') || message.contains('too many requests')) {
    return isEnglish
        ? 'Too many attempts. Please wait a moment and try again.'
        : 'Vous avez effectué trop de tentatives. Attendez un instant avant de réessayer.';
  }
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('host lookup') ||
      message.contains('timed out')) {
    return isEnglish
        ? 'The service could not be reached. Check your connection and try again.'
        : 'Le service est momentanément inaccessible. Vérifiez votre connexion et réessayez.';
  }
  if (message.contains('permission denied') ||
      message.contains('not authorized') ||
      message.contains('unauthorized')) {
    return isEnglish
        ? 'You do not have permission to complete this action.'
        : 'Vous n’êtes pas autorisé à effectuer cette action.';
  }

  return isEnglish ? englishFallback : frenchFallback;
}
