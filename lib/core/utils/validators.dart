/// Validateurs réutilisables

class AppValidators {
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email requis';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value!)) {
      return 'Email invalide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Mot de passe requis';
    }
    if (value!.length < 8) {
      return 'Minimum 8 caractères';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Numéro de téléphone requis';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,}$');
    if (!phoneRegex.hasMatch(value!)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? validateNotEmpty(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength) {
    if (value?.isEmpty ?? true) {
      return 'Ce champ est obligatoire';
    }
    if (value!.length < minLength) {
      return 'Minimum $minLength caractères';
    }
    return null;
  }
}
