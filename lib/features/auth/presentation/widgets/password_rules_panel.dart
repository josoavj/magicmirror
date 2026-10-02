import 'package:flutter/material.dart';
import 'package:magicmirror/core/utils/password_policy.dart';

/// Compact live feedback shared by signup, password reset and password change.
class PasswordRulesPanel extends StatelessWidget {
  const PasswordRulesPanel({
    super.key,
    required this.password,
    required this.personalInfo,
    required this.isEnglish,
  });

  final String password;
  final String personalInfo;
  final bool isEnglish;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = PasswordPolicy.strengthScore(password);
    final hasPassword = password.isNotEmpty;
    final rules = <(String, bool)>[
      (
        isEnglish ? 'At least 8 characters' : 'Au moins 8 caractères',
        PasswordPolicy.hasMinimumLength(password),
      ),
      (
        isEnglish ? 'An uppercase letter' : 'Une lettre majuscule',
        PasswordPolicy.hasUppercase(password),
      ),
      (
        isEnglish ? 'A lowercase letter' : 'Une lettre minuscule',
        PasswordPolicy.hasLowercase(password),
      ),
      (
        isEnglish ? 'A number' : 'Un chiffre',
        PasswordPolicy.hasDigit(password),
      ),
      (
        isEnglish ? 'Does not contain your name' : 'Ne contient pas votre nom',
        personalInfo.trim().isEmpty ||
            !PasswordPolicy.containsPersonalInfo(password, personalInfo),
      ),
    ];
    final strengthColor = score < 30
        ? colors.error
        : score < 70
        ? Colors.orange
        : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEnglish
                      ? 'Password strength'
                      : 'Robustesse du mot de passe',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                hasPassword
                    ? PasswordPolicy.strengthLabel(score, isEnglish: isEnglish)
                    : (isEnglish ? 'Not entered' : 'Non renseigné'),
                style: TextStyle(
                  color: strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: hasPassword ? (score / 100).clamp(0.0, 1.0) : 0,
              minHeight: 6,
              color: strengthColor,
              backgroundColor: colors.outline.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 9),
          ...rules.map((rule) => _RuleRow(label: rule.$1, satisfied: rule.$2)),
          Padding(
            padding: const EdgeInsets.only(left: 23, top: 2),
            child: Text(
              isEnglish
                  ? 'A special character can make it stronger (optional).'
                  : 'Un caractère spécial peut le renforcer (facultatif).',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordConfirmationStatus extends StatelessWidget {
  const PasswordConfirmationStatus({
    super.key,
    required this.password,
    required this.confirmation,
    required this.isEnglish,
  });

  final String password;
  final String confirmation;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    if (confirmation.isEmpty) return const SizedBox.shrink();
    final matches = password == confirmation;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: _RuleRow(
        label: isEnglish
            ? (matches ? 'Passwords match' : 'Passwords do not match')
            : (matches
                  ? 'Les mots de passe correspondent'
                  : 'Les mots de passe ne correspondent pas'),
        satisfied: matches,
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: satisfied ? Colors.green : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
