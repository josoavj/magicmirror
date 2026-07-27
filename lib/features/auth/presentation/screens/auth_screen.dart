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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    _signupPageController.dispose();
    super.dispose();
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
                    if (error != null)
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
                      onPressed: isLoading ? null : _submit,
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
                          () => setState(() {
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
