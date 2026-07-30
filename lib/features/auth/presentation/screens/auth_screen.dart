import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/auth/presentation/widgets/login_form.dart';
import 'package:magicmirror/features/auth/presentation/widgets/signup_stepper.dart';
import 'package:magicmirror/features/auth/presentation/widgets/signup_steps.dart';

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

    if (_signupStep < 2) {
      setState(() => _signupStep++);
      _signupPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    await authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
      gender: _gender,
      birthDate: _birthDate ?? DateTime.now(),
      heightCm: _heightCm,
      morphology: _morphology,
      preferredStyles: _styles.toList(),
      avatarUrl: _avatarUrlController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                );
                                if (date != null) {
                                  setState(() => _birthDate = date);
                                }
                              },
                              onGenderChanged:
                                  (val) => setState(() => _gender = val!),
                              onHeightChanged:
                                  (val) =>
                                      setState(() => _heightCm = val.round()),
                              isLoading: isLoading,
                            ),
                            SignupPreferenceStep(
                              morphology: _morphology,
                              selectedStyles: _styles,
                              onMorphologyChanged:
                                  (val) => setState(() => _morphology = val!),
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
                          ],
                        ),
                      ),
                    if (isLockedOut)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_clock, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Trop de tentatives. Veuillez patienter $_secondsRemaining secondes.',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (info != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          info,
                          style: const TextStyle(color: Colors.amberAccent),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (isLoading || isLockedOut) ? null : _submit,
                      child:
                          isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                _isLoginMode
                                    ? 'Se connecter'
                                    : (_signupStep < 2
                                        ? 'Suivant'
                                        : 'S\'inscrire'),
                              ),
                    ),
                    TextButton(
                      onPressed:
                          (isLoading || isLockedOut) 
                          ? null 
                          : () => setState(() {
                            _isLoginMode = !_isLoginMode;
                            _signupStep = 0;
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
