enum PasswordIssue {
  empty,
  tooShort,
  missingUppercase,
  missingLowercase,
  missingDigit,
  containsPersonalInfo,
  confirmationMismatch,
}

class PasswordPolicy {
  const PasswordPolicy._();

  static const minimumLength = 8;

  static bool hasMinimumLength(String password) =>
      password.length >= minimumLength;

  static bool hasUppercase(String password) =>
      RegExp(r'[A-Z]').hasMatch(password);

  static bool hasLowercase(String password) =>
      RegExp(r'[a-z]').hasMatch(password);

  static bool hasDigit(String password) => RegExp(r'[0-9]').hasMatch(password);

  static bool containsPersonalInfo(String password, String personalInfo) {
    final normalizedPassword = _normalize(password);
    final nameParts = personalInfo
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .map(_normalize)
        .where((part) => part.length >= 2);
    return nameParts.any(normalizedPassword.contains);
  }

  static PasswordIssue? validate({
    required String password,
    required String confirmation,
    required String personalInfo,
  }) {
    if (password.isEmpty) return PasswordIssue.empty;
    if (!hasMinimumLength(password)) return PasswordIssue.tooShort;
    if (!hasUppercase(password)) return PasswordIssue.missingUppercase;
    if (!hasLowercase(password)) return PasswordIssue.missingLowercase;
    if (!hasDigit(password)) return PasswordIssue.missingDigit;
    if (containsPersonalInfo(password, personalInfo)) {
      return PasswordIssue.containsPersonalInfo;
    }
    if (password != confirmation) return PasswordIssue.confirmationMismatch;
    return null;
  }

  static int strengthScore(String password) {
    var score = 0;
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    if (hasLowercase(password)) score += 15;
    if (hasUppercase(password)) score += 15;
    if (hasDigit(password)) score += 15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 15;
    return score;
  }

  static String strengthLabel(int score, {required bool isEnglish}) {
    if (score < 30) return isEnglish ? 'Very weak' : 'Très faible';
    if (score < 50) return isEnglish ? 'Weak' : 'Faible';
    if (score < 70) return isEnglish ? 'Medium' : 'Moyen';
    if (score < 85) return isEnglish ? 'Strong' : 'Fort';
    return isEnglish ? 'Very strong' : 'Très fort';
  }

  static String issueMessage(PasswordIssue issue, {required bool isEnglish}) {
    if (isEnglish) {
      return switch (issue) {
        PasswordIssue.empty => 'Please enter a password.',
        PasswordIssue.tooShort => 'Use at least $minimumLength characters.',
        PasswordIssue.missingUppercase => 'Add at least one uppercase letter.',
        PasswordIssue.missingLowercase => 'Add at least one lowercase letter.',
        PasswordIssue.missingDigit => 'Add at least one number.',
        PasswordIssue.containsPersonalInfo =>
          'Do not include your name in the password.',
        PasswordIssue.confirmationMismatch =>
          'The passwords do not match. Please try again.',
      };
    }

    return switch (issue) {
      PasswordIssue.empty => 'Veuillez saisir un mot de passe.',
      PasswordIssue.tooShort =>
        'Le mot de passe doit contenir au moins $minimumLength caractères.',
      PasswordIssue.missingUppercase =>
        'Ajoutez au moins une lettre majuscule.',
      PasswordIssue.missingLowercase =>
        'Ajoutez au moins une lettre minuscule.',
      PasswordIssue.missingDigit => 'Ajoutez au moins un chiffre.',
      PasswordIssue.containsPersonalInfo =>
        'N’incluez pas votre nom dans le mot de passe.',
      PasswordIssue.confirmationMismatch =>
        'Les mots de passe ne correspondent pas. Veuillez réessayer.',
    };
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }
}
