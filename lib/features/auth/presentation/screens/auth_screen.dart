import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/user_facing_error.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/auth/presentation/widgets/login_form.dart';
import 'package:magicmirror/features/auth/presentation/widgets/signup_stepper.dart';
import 'package:magicmirror/features/auth/presentation/widgets/signup_steps.dart';
import 'package:magicmirror/presentation/widgets/glass_dialog.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _signupPageController = PageController();

  bool _isLoginMode = true;
  bool _termsAccepted = false;
  bool _privacyNoticeAcknowledged = false;
  bool _showTermsError = false;
  bool _showPrivacyError = false;
  int _signupStep = 0;
  DateTime? _birthDate;
  int _heightCm = 170;
  String _gender = 'Non précise';
  String _morphology = 'Silhouette non définie';
  final Set<String> _styles = {'Casual'};

  // Gestion du compte à rebours de verrouillage
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    _signupPageController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiry) {
    _countdownTimer?.cancel();
    _updateRemainingTime(expiry);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime(expiry);
    });
  }

  void _updateRemainingTime(DateTime expiry) {
    final diff = expiry.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() => _secondsRemaining = 0);
      }
    } else {
      if (mounted) {
        setState(() => _secondsRemaining = diff);
      }
    }
  }

  Future<void> _submit() async {
    final authService = ref.read(authServiceProvider);
    if (_isLoginMode) {
      await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      return;
    }

    if (_signupStep < 3) {
      ref.read(authErrorProvider.notifier).state = null;
      ref.read(authInfoProvider.notifier).state = null;
      setState(() => _signupStep++);
      _signupPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (!_termsAccepted || !_privacyNoticeAcknowledged) {
      setState(() {
        _showTermsError = !_termsAccepted;
        _showPrivacyError = !_privacyNoticeAcknowledged;
      });
      return;
    }

    await authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
      gender: _gender,
      birthDate: _birthDate,
      heightCm: _heightCm,
      morphology: _morphology,
      preferredStyles: _styles.toList(),
      avatarUrl: _avatarUrlController.text,
      termsVersion: '1.0.0',
      privacyNoticeVersion: '2026-10-02',
    );
  }

  Future<void> _goToPreviousSignupStep() async {
    if (_signupStep == 0) return;
    ref.read(authErrorProvider.notifier).state = null;
    ref.read(authInfoProvider.notifier).state = null;
    setState(() => _signupStep--);
    await _signupPageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);
    final info = ref.watch(authInfoProvider);
    final lockoutTime = ref.watch(authLockoutTimeProvider);

    // Écouter les changements de verrouillage pour démarrer le timer
    ref.listen<DateTime?>(authLockoutTimeProvider, (previous, next) {
      if (next != null && next.isAfter(DateTime.now())) {
        _startCountdown(next);
      }
    });

    final isLockedOut = lockoutTime != null && _secondsRemaining > 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AuthCardContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLoginMode ? 'Connexion' : 'Inscription',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoginMode)
                      LoginForm(
                        emailController: _emailController,
                        passwordController: _passwordController,
                      )
                    else
                      SizedBox(
                        height: 400,
                        child: SignupStepper(
                          pageController: _signupPageController,
                          currentStep: _signupStep,
                          stepTitles: isEnglish
                              ? const [
                                  'Account details',
                                  'Personal information',
                                  'Style preferences',
                                  'Terms and privacy',
                                ]
                              : const [
                                  'Informations du compte',
                                  'Vos informations personnelles',
                                  'Vos préférences de style',
                                  'Conditions et confidentialité',
                                ],
                          steps: [
                            SignupAccountStep(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                            ),
                            SignupProfileStep(
                              displayNameController: _displayNameController,
                              avatarUrlController: _avatarUrlController,
                              gender: _gender,
                              birthDate: _birthDate,
                              heightCm: _heightCm,
                              onPickAvatar: () {}, // To be implemented
                              onPickBirthDate: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  builder: glassDialogBuilder,
                                );
                                if (date != null) {
                                  setState(() => _birthDate = date);
                                }
                              },
                              onGenderChanged: (val) =>
                                  setState(() => _gender = val!),
                              onHeightChanged: (val) =>
                                  setState(() => _heightCm = val.round()),
                              isLoading: isLoading,
                            ),
                            SignupPreferenceStep(
                              morphology: _morphology,
                              selectedStyles: _styles,
                              onMorphologyChanged: (val) =>
                                  setState(() => _morphology = val!),
                              onStyleToggled: (style, selected) {
                                setState(() {
                                  if (selected) {
                                    _styles.add(style);
                                  } else {
                                    _styles.remove(style);
                                  }
                                });
                              },
                            ),
                            SignupConsentStep(
                              termsAccepted: _termsAccepted,
                              privacyNoticeAcknowledged:
                                  _privacyNoticeAcknowledged,
                              showTermsError: _showTermsError,
                              showPrivacyError: _showPrivacyError,
                              onTermsChanged: (value) => setState(() {
                                _termsAccepted = value;
                                if (value) _showTermsError = false;
                              }),
                              onPrivacyChanged: (value) => setState(() {
                                _privacyNoticeAcknowledged = value;
                                if (value) _showPrivacyError = false;
                              }),
                              isLoading: isLoading,
                            ),
                          ],
                        ),
                      ),
                    if (_isLoginMode && isLockedOut)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_clock,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'en'
                                      ? 'Too many attempts. Please wait $_secondsRemaining seconds.'
                                      : 'Vous avez effectué trop de tentatives. Veuillez patienter $_secondsRemaining secondes.',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (error != null &&
                        (_isLoginMode || _signupStep == 3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          userFacingError(
                            context,
                            error,
                            frenchFallback:
                                'La connexion ou la création du compte a échoué. Veuillez réessayer.',
                            englishFallback:
                                'We could not sign you in or create your account. Please try again.',
                          ),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (info != null && (_isLoginMode || _signupStep == 3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          info,
                          style: const TextStyle(color: Colors.amberAccent),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_isLoginMode)
                      ElevatedButton(
                        onPressed: (isLoading || isLockedOut) ? null : _submit,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Se connecter'),
                      )
                    else
                      Row(
                        children: [
                          if (_signupStep > 0) ...[
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _goToPreviousSignupStep,
                                  child: const Text('Précédent'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _signupStep < 3
                                            ? 'Suivant'
                                            : 'S’inscrire',
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: Colors.transparent,
                        side: BorderSide.none,
                        minimumSize: Size.zero,
                      ),
                      onPressed: (isLoading || isLockedOut)
                          ? null
                          : () => setState(() {
                              _isLoginMode = !_isLoginMode;
                              _signupStep = 0;
                              _termsAccepted = false;
                              _privacyNoticeAcknowledged = false;
                              _showTermsError = false;
                              _showPrivacyError = false;
                              ref.read(authErrorProvider.notifier).state = null;
                              ref.read(authInfoProvider.notifier).state = null;
                            }),
                      child: Text(
                        _isLoginMode
                            ? 'Pas de compte ? S\'inscrire'
                            : 'Déjà un compte ? Se connecter',
                      ),
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
