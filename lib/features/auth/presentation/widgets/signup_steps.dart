import 'package:flutter/material.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/auth/presentation/widgets/password_rules_panel.dart';

class SignupAccountStep extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController displayNameController;
  final String? passwordError;
  final VoidCallback onPasswordEdited;

  const SignupAccountStep({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.displayNameController,
    required this.onPasswordEdited,
    this.passwordError,
  });

  @override
  State<SignupAccountStep> createState() => _SignupAccountStepState();
}

class _SignupAccountStepState extends State<SignupAccountStep> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _passwordHasFocus = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 6),
          AuthTextField(
            controller: widget.emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Focus(
            onFocusChange: (focused) =>
                setState(() => _passwordHasFocus = focused),
            child: AuthTextField(
              controller: widget.passwordController,
              label: 'Mot de passe',
              obscureText: !_showPassword,
              onChanged: (_) {
                setState(() {});
                widget.onPasswordEdited();
              },
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          if (_passwordHasFocus ||
              widget.passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            PasswordRulesPanel(
              password: widget.passwordController.text,
              personalInfo: widget.displayNameController.text,
              isEnglish: Localizations.localeOf(context).languageCode == 'en',
            ),
          ],
          if (widget.passwordError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.passwordError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AuthTextField(
            controller: widget.confirmPasswordController,
            label: 'Confirmer mot de passe',
            obscureText: !_showConfirmPassword,
            onChanged: (_) {
              setState(() {});
              widget.onPasswordEdited();
            },
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
            ),
          ),
          PasswordConfirmationStatus(
            password: widget.passwordController.text,
            confirmation: widget.confirmPasswordController.text,
            isEnglish: Localizations.localeOf(context).languageCode == 'en',
          ),
        ],
      ),
    );
  }
}

class SignupProfileStep extends StatelessWidget {
  final TextEditingController displayNameController;
  final TextEditingController avatarUrlController;
  final String gender;
  final DateTime? birthDate;
  final int heightCm;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickBirthDate;
  final VoidCallback onPickHeight;
  final Function(String?) onGenderChanged;
  final bool isLoading;

  const SignupProfileStep({
    super.key,
    required this.displayNameController,
    required this.avatarUrlController,
    required this.gender,
    this.birthDate,
    required this.heightCm,
    required this.onPickAvatar,
    required this.onPickBirthDate,
    required this.onPickHeight,
    required this.onGenderChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final birthDateLabel = birthDate == null
        ? 'Choisir une date'
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPickAvatar,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Importer une photo'),
            ),
          ),
          const SizedBox(height: 10),
          AuthTextField(
            controller: displayNameController,
            label:
                'Nom d'
                'utilisateur',
          ),
          const SizedBox(height: 12),
          AuthTextField(controller: avatarUrlController, label: 'Photo (URL)'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Sexe',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            items: ['Femme', 'Homme', 'Non binaire', 'Non précise']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPickBirthDate,
              icon: const Icon(Icons.cake_outlined),
              label: Text(birthDateLabel),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPickHeight,
              icon: const Icon(Icons.height),
              label: Text(
                isEnglish
                    ? 'Choose height · $heightCm cm'
                    : 'Choisir la taille · $heightCm cm',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupPreferenceStep extends StatelessWidget {
  final String morphology;
  final Set<String> selectedStyles;
  final Function(String?) onMorphologyChanged;
  final Function(String, bool) onStyleToggled;

  const SignupPreferenceStep({
    super.key,
    required this.morphology,
    required this.selectedStyles,
    required this.onMorphologyChanged,
    required this.onStyleToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: morphology,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Morphologie',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            items:
                [
                      'Silhouette non définie',
                      'Hanches et épaules équilibrées',
                      'Hanches plus marquées',
                      'Silhouette droite',
                      'Épaules plus larges',
                      'Épaules très marquées',
                      'Taille très marquée',
                      'Hanches très marquées',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: onMorphologyChanged,
          ),
          const SizedBox(height: 14),
          const Text(
            'Styles vestimentaires',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'Casual',
                  'Elegant',
                  'Sport',
                  'Streetwear',
                  'Business',
                  'Minimaliste',
                ].map((style) {
                  final selected = selectedStyles.contains(style);
                  return FilterChip(
                    label: Text(style),
                    selected: selected,
                    onSelected: (val) => onStyleToggled(style, val),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class SignupConsentStep extends StatelessWidget {
  const SignupConsentStep({
    super.key,
    required this.termsAccepted,
    required this.privacyNoticeAcknowledged,
    required this.showTermsError,
    required this.showPrivacyError,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.isLoading,
  });

  final bool termsAccepted;
  final bool privacyNoticeAcknowledged;
  final bool showTermsError;
  final bool showPrivacyError;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Avant de créer votre compte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prenez connaissance des informations suivantes et confirmez chaque point.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          _ConsentItem(
            title: 'Conditions d’utilisation',
            description:
                'Elles expliquent les règles applicables à l’utilisation de Magic Mirror.',
            checked: termsAccepted,
            onChanged: isLoading ? null : onTermsChanged,
            error: showTermsError
                ? isEnglish
                      ? 'Please accept the terms to create your account.'
                      : 'Veuillez accepter les conditions pour créer votre compte.'
                : null,
            linkLabel: isEnglish ? 'Read the terms' : 'Lire les conditions',
            onOpen: () => Navigator.pushNamed(context, '/terms'),
          ),
          const SizedBox(height: 10),
          _ConsentItem(
            title: 'Politique de confidentialité',
            description:
                'Elle décrit les données utilisées, leurs finalités, leur conservation et vos droits. Cette confirmation atteste que vous en avez pris connaissance.',
            checked: privacyNoticeAcknowledged,
            onChanged: isLoading ? null : onPrivacyChanged,
            error: showPrivacyError
                ? isEnglish
                      ? 'Please confirm that you have read the privacy notice.'
                      : 'Veuillez confirmer la lecture de la politique de confidentialité.'
                : null,
            linkLabel: isEnglish
                ? 'Read the privacy notice'
                : 'Lire la politique',
            onOpen: () => Navigator.pushNamed(context, '/privacy'),
          ),
        ],
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  const _ConsentItem({
    required this.title,
    required this.description,
    required this.checked,
    required this.onChanged,
    required this.linkLabel,
    required this.onOpen,
    this.error,
  });

  final String title;
  final String description;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String linkLabel;
  final VoidCallback onOpen;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error == null
              ? Colors.white.withValues(alpha: 0.18)
              : errorColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: CheckboxListTile(
              value: checked,
              onChanged: onChanged == null
                  ? null
                  : (value) => onChanged!(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              activeColor: Theme.of(context).colorScheme.primary,
              checkColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Text(
              description,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(linkLabel),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
              child: Text(
                error!,
                style: TextStyle(color: errorColor, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
