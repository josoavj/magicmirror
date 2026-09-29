// ignore_for_file: unused_field, unused_element, unused_import

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:magicmirror/features/settings/presentation/widgets/account_settings_widgets.dart';
import 'package:magicmirror/features/settings/presentation/widgets/profile_edit_dialog.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  static const _genders = ['Femme', 'Homme', 'Non binaire', 'Non précise'];
  static const _morphologies = [
    'Silhouette non définie',
    'Hanches et épaules équilibrées',
    'Hanches plus marquées',
    'Silhouette droite',
    'Épaules plus larges',
    'Épaules très marquées',
    'Taille très marquée',
    'Hanches très marquées',
  ];
  static const _styles = [
    'Casual',
    'Elegant',
    'Sport',
    'Streetwear',
    'Business',
    'Minimaliste',
  ];

  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _picker = ImagePicker();
  bool _editingProfile = false;
  bool _savingProfile = false;
  String _gender = _genders.last;
  String _morphology = _morphologies.first;
  int _heightCm = 170;
  DateTime? _birthDate;
  bool _clearBirthDate = false;
  Set<String> _selectedStyles = {'Casual'};
  Uint8List? _pendingAvatar;

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  String _buildUsername(User? activeUser, String fallbackUserId) {
    final email = activeUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return '@$localPart';
      }
    }

    final fallback = fallbackUserId.trim();
    return fallback.isNotEmpty ? '@$fallback' : '@utilisateur';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _startEditingProfile(UserProfile profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileEditDialog(profile: profile),
    );
  }

  Future<void> _pickProfileAvatar() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _showMessage(
        _tr(
          context,
          'Connecte-toi pour envoyer une photo.',
          'Sign in to upload a photo.',
        ),
      );
      return;
    }

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _pendingAvatar = bytes);
    } catch (_) {
      if (mounted) {
        _showMessage(
          _tr(
            context,
            'Impossible de lire cette image.',
            'Could not read this image.',
          ),
        );
      }
    }
  }

  Future<void> _pickProfileBirthDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year - 100);
    final lastDate = DateTime(today.year - 12, today.month, today.day);
    final initialCandidate =
        _birthDate ?? DateTime(today.year - 25, today.month, today.day);
    final initial = initialCandidate.isBefore(firstDate)
        ? firstDate
        : initialCandidate.isAfter(lastDate)
        ? lastDate
        : initialCandidate;

    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: _tr(context, 'Date de naissance', 'Birth date'),
    );

    if (value != null) {
      setState(() {
        _birthDate = value;
        _clearBirthDate = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfileChanges(BuildContext dialogContext) async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (_selectedStyles.isEmpty) {
      _showMessage(
        _tr(
          context,
          'Choisis au moins un style.',
          'Choose at least one style.',
        ),
      );
      return;
    }

    setState(() => _savingProfile = true);
    final photoUploadError = _tr(
      context,
      'La photo n’a pas pu être envoyée.',
      'The photo could not be uploaded.',
    );

    try {
      var avatarUrl = _avatarController.text.trim();
      if (_pendingAvatar != null) {
        final uploaded = await ref
            .read(userProfileProvider.notifier)
            .uploadAvatar(bytes: _pendingAvatar!);
        if (uploaded == null) {
          throw StateError(photoUploadError);
        }
        avatarUrl = uploaded;
      }

      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(
            displayName: _nameController.text,
            avatarUrl: avatarUrl,
            gender: _gender,
            birthDate: _birthDate,
            clearBirthDate: _clearBirthDate,
            heightCm: _heightCm,
            morphology: _morphology,
            preferredStyles: _selectedStyles.toList(),
          );

      if (!mounted) return;
      setState(() {
        _editingProfile = false;
        _pendingAvatar = null;
      });
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
      _showMessage(_tr(context, 'Profil enregistré.', 'Profile saved.'));
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error is StateError
            ? error.message.toString()
            : _tr(
                context,
                'Échec de l’enregistrement du profil.',
                'Could not save your profile.',
              ),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Widget _buildProfileEditor(UserProfile profile, BuildContext dialogContext) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final avatarProvider = _pendingAvatar != null
        ? MemoryImage(_pendingAvatar!)
        : profile.avatarUrl.startsWith('http')
        ? NetworkImage(profile.avatarUrl) as ImageProvider
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: avatarProvider,
                      backgroundColor: colors.primaryContainer,
                      child: avatarProvider == null
                          ? Text(
                              _nameController.text.isEmpty
                                  ? '?'
                                  : _nameController.text[0].toUpperCase(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _savingProfile ? null : _pickProfileAvatar,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _tr(context, 'Choisir une photo', 'Choose a photo'),
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom et prénom',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? _tr(
                        context,
                        'Le nom est obligatoire.',
                        'Name is required.',
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL de la photo',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  final url = value?.trim() ?? '';
                  if (url.isEmpty) return null;
                  final parsed = Uri.tryParse(url);
                  if (parsed == null ||
                      !parsed.hasAuthority ||
                      !{
                        'http',
                        'https',
                      }.contains(parsed.scheme.toLowerCase())) {
                    return _tr(
                      context,
                      'Saisis une URL http ou https valide.',
                      'Enter a valid http or https URL.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: _genders
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: _savingProfile
                    ? null
                    : (value) {
                        if (value != null) setState(() => _gender = value);
                      },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _savingProfile ? null : _pickProfileBirthDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _birthDate == null
                      ? _tr(
                          context,
                          'Ajouter une date de naissance',
                          'Add birth date',
                        )
                      : '${_tr(context, 'Date de naissance', 'Birth date')} : ${MaterialLocalizations.of(context).formatMediumDate(_birthDate!)}',
                ),
              ),
              if (_birthDate != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _savingProfile
                        ? null
                        : () => setState(() {
                            _birthDate = null;
                            _clearBirthDate = true;
                          }),
                    icon: const Icon(Icons.clear),
                    label: Text(_tr(context, 'Effacer la date', 'Clear date')),
                  ),
                ),
              const SizedBox(height: 8),
              Text('${_tr(context, 'Taille', 'Height')} : $_heightCm cm'),
              Slider(
                value: _heightCm.toDouble(),
                min: 120,
                max: 230,
                divisions: 110,
                label: '$_heightCm cm',
                onChanged: _savingProfile
                    ? null
                    : (value) => setState(() => _heightCm = value.round()),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _morphology,
                decoration: const InputDecoration(
                  labelText: 'Morphologie',
                  prefixIcon: Icon(Icons.accessibility_new),
                ),
                items: _morphologies
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _savingProfile
                    ? null
                    : (value) {
                        if (value != null) setState(() => _morphology = value);
                      },
              ),
              const SizedBox(height: 16),
              Text(
                _tr(context, 'Styles préférés', 'Preferred styles'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _styles
                    .map(
                      (style) => FilterChip(
                        label: Text(style),
                        selected: _selectedStyles.contains(style),
                        onSelected: _savingProfile
                            ? null
                            : (selected) => setState(() {
                                if (selected) {
                                  _selectedStyles.add(style);
                                } else {
                                  _selectedStyles.remove(style);
                                }
                              }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _savingProfile
                          ? null
                          : () {
                              Navigator.of(dialogContext).pop();
                              if (mounted) {
                                setState(() {
                                  _editingProfile = false;
                                  _pendingAvatar = null;
                                });
                              }
                            },
                      child: Text(_tr(context, 'Annuler', 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _savingProfile
                          ? null
                          : () => _saveProfileChanges(dialogContext),
                      icon: _savingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_tr(context, 'Enregistrer', 'Save changes')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isLoading = ref.watch(authLoadingProvider);
            final error = ref.watch(authErrorProvider);

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                'Sécurité',
                style: TextStyle(color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthTextField(
                        controller: oldPasswordController,
                        label: 'Mot de passe actuel',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: newPasswordController,
                        label: 'Nouveau mot de passe',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: confirmPasswordController,
                        label: 'Confirmer le nouveau',
                        obscureText: true,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            error,
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
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Les mots de passe ne correspondent pas.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (newPasswordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Minimum 6 caractères.'),
                              ),
                            );
                            return;
                          }

                          final success = await ref
                              .read(authServiceProvider)
                              .changePassword(
                                oldPassword: oldPasswordController.text,
                                newPassword: newPasswordController.text,
                              );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mot de passe mis à jour !'),
                              ),
                            );
                          }
                        },
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
          },
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final activeUser = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(userProfileProvider);
    final username = _buildUsername(activeUser, profile.userId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'Account Settings' : 'Paramètres du compte'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 72, 16, 32),
            children: [
              AccountSettingsSection(
                title: _tr(context, 'Compte actif', 'Active account'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${activeUser?.email ?? _tr(context, 'Non connecté', 'Not connected')}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${activeUser?.id ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Profil', 'Profile'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeader(
                      displayName: profile.displayName,
                      username: username,
                      avatarUrl: profile.avatarUrl,
                    ),
                    const SizedBox(height: 12),
                    if (!_editingProfile) ...[
                      Text(
                        _tr(
                          context,
                          'Les informations personnelles se modifient ici.',
                          'Personal information is edited here.',
                        ),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _editingProfile
                            ? null
                            : () => _startEditingProfile(profile),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          _tr(context, 'Modifier le profil', 'Edit profile'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Sécurité', 'Security'),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        _tr(
                          context,
                          'Changer le mot de passe',
                          'Change password',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSettingsSection(
                title: _tr(context, 'Actions', 'Actions'),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        _tr(context, 'Se déconnecter', 'Sign out'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (mounted) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
