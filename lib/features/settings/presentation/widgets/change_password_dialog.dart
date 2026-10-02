import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/password_policy.dart';
import 'package:magicmirror/core/utils/user_facing_error.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/auth/presentation/widgets/password_rules_panel.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.read(userProfileProvider);
    final issue = PasswordPolicy.validate(
      password: _newPasswordController.text,
      confirmation: _confirmPasswordController.text,
      personalInfo: profile.isDefault ? '' : profile.displayName,
    );
    if (issue != null) {
      setState(() {
        _validationError = PasswordPolicy.issueMessage(
          issue,
          isEnglish: isEnglish,
        );
      });
      return;
    }
    setState(() => _validationError = null);

    final success = await ref
        .read(authServiceProvider)
        .changePassword(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted || !success) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour !')));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(userProfileProvider);
    final displayName = profile.isDefault ? '' : profile.displayName;

    return AlertDialog(
      title: const Text('Sécurité', style: TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextField(
                controller: _oldPasswordController,
                label: 'Mot de passe actuel',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _newPasswordController,
                label: 'Nouveau mot de passe',
                obscureText: true,
                onChanged: (_) => setState(() => _validationError = null),
              ),
              if (_newPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 9),
                PasswordRulesPanel(
                  password: _newPasswordController.text,
                  personalInfo: displayName,
                  isEnglish: isEnglish,
                ),
              ],
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirmer le nouveau',
                obscureText: true,
                onChanged: (_) => setState(() {}),
              ),
              PasswordConfirmationStatus(
                password: _newPasswordController.text,
                confirmation: _confirmPasswordController.text,
                isEnglish: isEnglish,
              ),
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _validationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    userFacingError(
                      context,
                      error,
                      frenchFallback:
                          'La mise à jour du mot de passe a échoué. Veuillez réessayer.',
                      englishFallback:
                          'We could not update your password. Please try again.',
                    ),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1.2,
            ),
          ),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }
}
