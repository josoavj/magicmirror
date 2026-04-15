import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = false;
  bool _showLoginPassword = false;
  bool _showSignupPassword = false;
  bool _showSignupConfirmPassword = false;
  String? _error;
  String? _info;

  Uint8List? _selectedAvatarBytes;
  String _selectedAvatarExt = 'jpg';

  static const _pendingAvatarDataKey = 'auth.pendingAvatar.base64';
  static const _pendingAvatarExtKey = 'auth.pendingAvatar.ext';
  static const _maxPersistedAvatarBytes = 500 * 1024;

  DateTime? _birthDate;
  int _heightCm = 170;
  String _gender = 'Non precise';
  String _morphology = 'Silhouette non definie';
  final Set<String> _styles = {'Casual'};

  static const List<String> _genders = [
    'Femme',
    'Homme',
    'Non binaire',
    'Non precise',
  ];

  static const List<String> _morphologies = [
    'Silhouette non definie',
    'Hanches et epaules equilibrees',
    'Hanches plus marquees',
    'Silhouette droite',
    'Epaules plus larges',
    'Epaules tres marquees',
    'Taille tres marquee',
    'Hanches tres marquees',
  ];

  static const List<String> _availableStyles = [
    'Casual',
    'Elegant',
    'Sport',
    'Streetwear',
    'Business',
    'Minimaliste',
  ];

  @override
  void initState() {
    super.initState();
    _restorePendingAvatarPreview();
  }

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

  Future<void> _restorePendingAvatarPreview() async {
    final prefs = await SharedPreferences.getInstance();
    final base64 = prefs.getString(_pendingAvatarDataKey);
    if (base64 == null || base64.isEmpty) {
      return;
    }

    try {
      final bytes = base64Decode(base64);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarExt = (prefs.getString(_pendingAvatarExtKey) ?? 'jpg')
            .toLowerCase();
      });
    } catch (_) {
      await _clearPendingAvatarStorage();
    }
  }

  Future<void> _savePendingAvatarStorage(
    Uint8List bytes,
    String extension,
  ) async {
    if (bytes.length > _maxPersistedAvatarBytes) {
      setState(() {
        _info =
            'Photo volumineuse: elle sera envoyée si vous terminez la connexion dans cette session.';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingAvatarDataKey, base64Encode(bytes));
    await prefs.setString(_pendingAvatarExtKey, extension.toLowerCase());
  }

  Future<void> _clearPendingAvatarStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAvatarDataKey);
    await prefs.remove(_pendingAvatarExtKey);
  }

  Future<void> _tryUploadPendingAvatarAfterLogin(
    UserProfileNotifier profileNotifier,
  ) async {
    Uint8List? bytes = _selectedAvatarBytes;
    var ext = _selectedAvatarExt;

    if (bytes == null) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingAvatarDataKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          bytes = base64Decode(raw);
          ext = (prefs.getString(_pendingAvatarExtKey) ?? 'jpg').toLowerCase();
        } catch (_) {
          bytes = null;
        }
      }
    }

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    final uploadedUrl = await profileNotifier.uploadAvatar(
      bytes: bytes,
      fileExtension: ext,
    );

    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
      _avatarUrlController.text = uploadedUrl;
      await profileNotifier.syncToCloud();
      await _clearPendingAvatarStorage();
      if (mounted) {
        setState(() {
          _selectedAvatarBytes = null;
          _info = 'Photo de profil synchronisee apres connexion.';
        });
      }
    }
  }

  bool _isValidEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  bool _validateSignupStep() {
    if (_signupStep == 0) {
      if (!_isValidEmail(_emailController.text.trim())) {
        _error = 'Email invalide.';
        return false;
      }
      if (_passwordController.text.length < 6) {
        _error = '6 caracteres minimum pour le mot de passe.';
        return false;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _error = 'La confirmation du mot de passe ne correspond pas.';
        return false;
      }
    }

    if (_signupStep == 1 && _displayNameController.text.trim().isEmpty) {
      _error = 'Veuillez renseigner votre nom.';
      return false;
    }

    if (_signupStep == 1 && _birthDate == null) {
      _error = 'Veuillez renseigner votre date de naissance.';
      return false;
    }

    if (_signupStep == 1 && (_heightCm < 120 || _heightCm > 230)) {
      _error = 'Veuillez renseigner une taille valide (120-230 cm).';
      return false;
    }

    if (_signupStep == 2 && _styles.isEmpty) {
      _error = 'Choisissez au moins un style vestimentaire.';
      return false;
    }

    return true;
  }

  int _computeAge(DateTime birthDate) {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    final hadBirthdayThisYear =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthdayThisYear) {
      years -= 1;
    }
    return years.clamp(12, 100);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 12, now.month, now.day);
    final minDate = DateTime(now.year - 100, now.month, now.day);
    final initialDate =
        _birthDate ?? DateTime(now.year - 25, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(maxDate) ? maxDate : initialDate,
      firstDate: minDate,
      lastDate: maxDate,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _birthDate = DateTime(selected.year, selected.month, selected.day);
      _error = null;
    });
  }

  Future<void> _pickAvatarImage() async {
    final imagePicker = ImagePicker();

    Future<bool> confirmBeforeAfter({
      required Uint8List afterBytes,
      Uint8List? beforeBytes,
    }) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirmer la photo'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Avant'),
                            const SizedBox(height: 6),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: beforeBytes != null
                                    ? Image.memory(
                                        beforeBytes,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.black12,
                                        alignment: Alignment.center,
                                        child: const Text('N/A'),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Apres'),
                            const SizedBox(height: 6),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  afterBytes,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Utiliser'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }

    Future<bool> cropAndSaveFromPath(String path) async {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [],
      );

      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: path,
          compressQuality: 92,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Rogner la photo',
              toolbarColor: const Color(0xFF0F172A),
              toolbarWidgetColor: Colors.white,
              statusBarLight: false,
              navBarLight: false,
              backgroundColor: const Color(0xFF0F172A),
              activeControlsWidgetColor: const Color(0xFF22D3EE),
              hideBottomControls: false,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Rogner la photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
      } finally {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }

      if (cropped == null) {
        return false;
      }

      final bytes = await cropped.readAsBytes();
      if (bytes.isEmpty) {
        return false;
      }

      Uint8List? beforeBytes;
      try {
        beforeBytes = await File(path).readAsBytes();
      } catch (_) {
        beforeBytes = null;
      }

      final confirmed = await confirmBeforeAfter(
        afterBytes: bytes,
        beforeBytes: beforeBytes,
      );
      if (!confirmed) {
        return false;
      }

      final dotIndex = cropped.path.lastIndexOf('.');
      final extension = dotIndex >= 0
          ? cropped.path.substring(dotIndex + 1).toLowerCase()
          : 'jpg';

      if (!mounted) {
        return false;
      }
      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarExt = extension;
        _error = null;
      });
      await _savePendingAvatarStorage(bytes, extension);
      return true;
    }

    Future<bool> pickWithImagePickerFallback() async {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (pickedFile == null) {
        return false;
      }
      return cropAndSaveFromPath(pickedFile.path);
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final picked = await pickWithImagePickerFallback();
      if (!picked && mounted) {
        setState(() {
          _error = 'Impossible de sélectionner la photo.';
        });
      }
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: false,
      );
      final file = result?.files.single;
      final path = file?.path;
      if (path == null || path.isEmpty) {
        final picked = await pickWithImagePickerFallback();
        if (!picked && mounted) {
          setState(() {
            _error = 'Impossible de sélectionner la photo.';
          });
        }
        return;
      }
      final picked = await cropAndSaveFromPath(path);
      if (!picked && mounted) {
        setState(() {
          _error = 'Rognage annule ou photo invalide.';
        });
      }
    } on MissingPluginException {
      final picked = await pickWithImagePickerFallback();
      if (!picked && mounted) {
        setState(() {
          _error =
              'Import indisponible: redemarrez l\'application puis reessayez.';
        });
      }
    } on PlatformException {
      final picked = await pickWithImagePickerFallback();
      if (!picked && mounted) {
        setState(() {
          _error = 'Impossible de sélectionner la photo.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Impossible de sélectionner la photo.';
      });
    }
  }

  Future<void> _submitLogin() async {
    if (!_isValidEmail(_emailController.text.trim()) ||
        _passwordController.text.length < 6) {
      setState(() {
        _error = 'Email ou mot de passe invalide.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = response.user?.id;
      if (userId != null) {
        final profileNotifier = ref.read(userProfileProvider.notifier);
        await profileNotifier.setUserId(userId);
        await profileNotifier.pullFromCloud();
        await _tryUploadPendingAvatarAfterLogin(profileNotifier);
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Une erreur est survenue, veuillez reessayer.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitSignup() async {
    if (!_validateSignupStep()) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final profileNotifier = ref.read(userProfileProvider.notifier);
      await profileNotifier.applyOnboardingProfile(
        userId: response.user?.id,
        displayName: _displayNameController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
        gender: _gender,
        birthDate: _birthDate!,
        heightCm: _heightCm,
        morphology: _morphology,
        preferredStyles: _styles.toList(),
        syncIfConnected: response.session != null,
      );

      if (_selectedAvatarBytes != null && response.session != null) {
        final uploadedUrl = await profileNotifier.uploadAvatar(
          bytes: _selectedAvatarBytes!,
          fileExtension: _selectedAvatarExt,
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          _avatarUrlController.text = uploadedUrl;
          await profileNotifier.syncToCloud();
          await _clearPendingAvatarStorage();
        }
      }

      if (response.session == null) {
        _info = _selectedAvatarBytes == null
            ? 'Compte créé. Confirmez votre email puis connectez-vous pour activer la synchronisation.'
            : 'Compte créé. Confirmez votre email puis connectez-vous: la photo sera envoyée au cloud à la première session active.';
        _isLoginMode = true;
        _signupStep = 0;
        _signupPageController.jumpToPage(0);
      } else {
        _info = 'Compte créé et profil initialisé.';
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Une erreur est survenue, veuillez réessayer.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Entrez un email valide pour réinitialiser le mot de passe.';
      });
      return;
    }

    setState(() {
      _error = null;
      _info = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() {
        _info = 'Email de réinitialisation envoyé.';
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible d\'envoyer l\'email de réinitialisation.';
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoginMode) {
      await _submitLogin();
      return;
    }

    if (_signupStep < 2) {
      if (!_validateSignupStep()) {
        setState(() {});
        return;
      }
      setState(() {
        _error = null;
      });
      await _signupPageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      setState(() {
        _signupStep++;
      });
      return;
    }

    await _submitSignup();
  }

  Future<void> _goBackStep() async {
    if (_signupStep == 0) {
      return;
    }
    await _signupPageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    setState(() {
      _signupStep--;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyan.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -90,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + keyboardInset,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Card(
                            color: Colors.white.withValues(alpha: 0.08),
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    child: Text(
                                      _isLoginMode
                                          ? 'Connexion'
                                          : 'Inscription et profil',
                                      key: ValueKey(_isLoginMode),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isLoginMode
                                        ? 'Connectez-vous avec votre compte existant'
                                        : 'Etape ${_signupStep + 1}/3: compte, profil, preferences',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (!_isLoginMode) _buildStepProgress(),
                                  if (!_isLoginMode) const SizedBox(height: 14),
                                  SizedBox(
                                    height: _isLoginMode ? null : 460,
                                    child: _isLoginMode
                                        ? _buildLoginForm()
                                        : _buildSignupStepper(),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  if (_info != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        _info!,
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      if (!_isLoginMode)
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : _goBackStep,
                                            child: const Text('Retour'),
                                          ),
                                        ),
                                      if (!_isLoginMode)
                                        const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _submit,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Text(
                                                  _isLoginMode
                                                      ? 'Se connecter'
                                                      : (_signupStep < 2
                                                            ? 'Continuer'
                                                            : 'Finaliser inscription'),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_isLoginMode)
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _sendPasswordReset,
                                      child: const Text(
                                        'Mot de passe oublie ?',
                                      ),
                                    ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isLoginMode = !_isLoginMode;
                                              _signupStep = 0;
                                              _error = null;
                                              _info = null;
                                            });
                                            _signupPageController.jumpToPage(0);
                                          },
                                    child: Text(
                                      _isLoginMode
                                          ? 'Pas de compte ? Inscrivez-vous'
                                          : 'Deja un compte ? Connectez-vous',
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgress() {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= _signupStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? Colors.cyanAccent
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: !_showLoginPassword,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'Mot de passe',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showLoginPassword = !_showLoginPassword;
                });
              },
              icon: Icon(
                _showLoginPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupStepper() {
    return PageView(
      controller: _signupPageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSignupAccountStep(),
        _buildSignupProfileStep(),
        _buildSignupPreferenceStep(),
      ],
    );
  }

  Widget _buildSignupAccountStep() {
    return Column(
      children: [
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: !_showSignupPassword,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'Mot de passe',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showSignupPassword = !_showSignupPassword;
                });
              },
              icon: Icon(
                _showSignupPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_showSignupConfirmPassword,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'Confirmer mot de passe',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showSignupConfirmPassword = !_showSignupConfirmPassword;
                });
              },
              icon: Icon(
                _showSignupConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupProfileStep() {
    final hasImportedAvatar = _selectedAvatarBytes != null;
    final hasNetworkAvatar =
        _avatarUrlController.text.startsWith('http://') ||
        _avatarUrlController.text.startsWith('https://');
    final birthDateLabel = _birthDate == null
        ? 'Choisir une date'
        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';
    final computedAge = _birthDate == null ? null : _computeAge(_birthDate!);

    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          backgroundImage: _selectedAvatarBytes != null
              ? MemoryImage(_selectedAvatarBytes!)
              : (hasNetworkAvatar
                    ? NetworkImage(_avatarUrlController.text)
                    : null),
          child: _selectedAvatarBytes != null || hasNetworkAvatar
              ? null
              : Text(
                  _displayNameController.text.trim().isEmpty
                      ? 'U'
                      : _displayNameController.text.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickAvatarImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Importer une photo'),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _displayNameController,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('Nom affiche'),
          onChanged: (_) => setState(() {}),
        ),
        if (!hasImportedAvatar) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _avatarUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Photo (URL)'),
            onChanged: (_) => setState(() {}),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo importee: le champ URL est masque.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAvatarBytes = null;
                    });
                    _clearPendingAvatarStorage();
                  },
                  child: const Text('Retirer'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('Sexe'),
          items: _genders
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _gender = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Date de naissance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickBirthDate,
            icon: const Icon(Icons.cake_outlined),
            label: Text(birthDateLabel),
          ),
        ),
        if (computedAge != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Age calcule: $computedAge ans',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Taille: $_heightCm cm',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.cyanAccent,
            thumbColor: Colors.cyanAccent,
            inactiveTrackColor: Colors.white24,
            overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
          ),
          child: Slider(
            min: 120,
            max: 230,
            divisions: 110,
            value: _heightCm.toDouble(),
            label: '$_heightCm cm',
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _heightCm = value.round();
                      _error = null;
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildSignupPreferenceStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _morphology,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Morphologie'),
            items: _morphologies
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _morphology = value;
                });
              }
            },
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
            children: _availableStyles.map((style) {
              final selected = _styles.contains(style);
              return FilterChip(
                label: Text(style),
                selected: selected,
                selectedColor: Colors.cyan.withValues(alpha: 0.45),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                labelStyle: const TextStyle(color: Colors.white),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      if (_styles.length > 1) {
                        _styles.remove(style);
                      }
                    } else {
                      _styles.add(style);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }
}
