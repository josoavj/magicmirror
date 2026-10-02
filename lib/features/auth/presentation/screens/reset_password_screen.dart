import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/password_policy.dart';
import 'package:magicmirror/core/utils/user_facing_error.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/auth/presentation/widgets/password_rules_panel.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final profile = ref.read(userProfileProvider);
    final issue = PasswordPolicy.validate(
      password: password,
      confirmation: confirm,
      personalInfo: profile.isDefault ? '' : profile.displayName,
    );
    if (issue != null) {
      setState(() {
        _error = PasswordPolicy.issueMessage(
          issue,
          isEnglish: Localizations.localeOf(context).languageCode == 'en',
        );
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) return;
      setState(() {
        _message = 'Mot de passe mis à jour. Vous pouvez continuer.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(
          context,
          e,
          frenchFallback:
              'La mise à jour du mot de passe a échoué. Veuillez réessayer.',
          englishFallback:
              'We could not update your password. Please try again.',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _tr(
          'La mise à jour du mot de passe a échoué. Veuillez réessayer.',
          'We could not update your password. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _tr(String french, String english) =>
      Localizations.localeOf(context).languageCode == 'en' ? english : french;

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(userProfileProvider);
    final displayName = profile.isDefault ? '' : profile.displayName;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AuthCardContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nouveau mot de passe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      obscureText: true,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      PasswordRulesPanel(
                        password: _passwordController.text,
                        personalInfo: displayName,
                        isEnglish: isEnglish,
                      ),
                    ],
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _confirmController,
                      label: 'Confirmer mot de passe',
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    PasswordConfirmationStatus(
                      password: _passwordController.text,
                      confirmation: _confirmController.text,
                      isEnglish: isEnglish,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    if (_message != null)
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amberAccent),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _updatePassword,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Mettre à jour'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
