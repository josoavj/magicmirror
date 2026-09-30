import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/features/settings/presentation/widgets/account_settings_widgets.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditDialog extends ConsumerStatefulWidget {
  final UserProfile profile;

  const ProfileEditDialog({super.key, required this.profile});

  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
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

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _picker = ImagePicker();
  bool _saving = false;
  String _gender = _genders.last;
  String _morphology = _morphologies.first;
  int _heightCm = 170;
  DateTime? _birthDate;
  bool _clearBirthDate = false;
  Set<String> _selectedStyles = {'Casual'};
  Uint8List? _pendingAvatar;

  bool get _isEnglish => Localizations.localeOf(context).languageCode == 'en';

  String _tr(String fr, String en) => _isEnglish ? en : fr;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController.text = profile.displayName;
    _avatarController.text = profile.avatarUrl;
    _gender = _genders.contains(profile.gender)
        ? profile.gender
        : _genders.last;
    _morphology = _morphologies.contains(profile.morphology)
        ? profile.morphology
        : _morphologies.first;
    _heightCm = profile.heightCm.clamp(120, 230);
    _birthDate = profile.birthDate;
    _clearBirthDate = false;
    _selectedStyles = profile.preferredStyles.toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAvatar() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _showMessage(
        _tr(
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
          _tr('Impossible de lire cette image.', 'Could not read this image.'),
        );
      }
    }
  }

  Future<void> _pickBirthDate() async {
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
      helpText: _tr('Date de naissance', 'Birth date'),
    );

    if (value != null) {
      setState(() {
        _birthDate = value;
        _clearBirthDate = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStyles.isEmpty) {
      _showMessage(
        _tr('Choisis au moins un style.', 'Choose at least one style.'),
      );
      return;
    }

    setState(() => _saving = true);
    final photoUploadError = _tr(
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Profil enregistré.', 'Profile saved.'))),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error is StateError
            ? error.message.toString()
            : _tr(
                'Échec de l’enregistrement du profil.',
                'Could not save your profile.',
              ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final avatarProvider = _pendingAvatar != null
        ? MemoryImage(_pendingAvatar!)
        : widget.profile.avatarUrl.startsWith('http')
        ? NetworkImage(widget.profile.avatarUrl) as ImageProvider
        : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tr('Modifier le profil', 'Edit profile'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        onPressed: _saving ? null : _pickAvatar,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_tr('Choisir une photo', 'Choose a photo')),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: accountInputDecoration('Nom et prénom'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? _tr('Le nom est obligatoire.', 'Name is required.')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _avatarController,
                  keyboardType: TextInputType.url,
                  decoration: accountInputDecoration('URL de la photo'),
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
                  dropdownColor: const Color(0xFF1F2937),
                  decoration: accountInputDecoration('Genre'),
                  items: _genders
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _gender = value);
                        },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickBirthDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _birthDate == null
                        ? _tr('Ajouter une date de naissance', 'Add birth date')
                        : '${_tr('Date de naissance', 'Birth date')} : ${formatDisplayDate(_birthDate!, locale: Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'fr_FR')}',
                  ),
                ),
                if (_birthDate != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _birthDate = null;
                              _clearBirthDate = true;
                            }),
                      icon: const Icon(Icons.clear),
                      label: Text(_tr('Effacer la date', 'Clear date')),
                    ),
                  ),
                const SizedBox(height: 8),
                Text('${_tr('Taille', 'Height')} : $_heightCm cm'),
                Slider(
                  value: _heightCm.toDouble(),
                  min: 120,
                  max: 230,
                  divisions: 110,
                  label: '$_heightCm cm',
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _heightCm = value.round()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _morphology,
                  dropdownColor: const Color(0xFF1F2937),
                  decoration: accountInputDecoration('Morphologie'),
                  items: _morphologies
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _morphology = value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                Text(
                  _tr('Styles préférés', 'Preferred styles'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                          onSelected: _saving
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
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(_tr('Annuler', 'Cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveProfileChanges,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_tr('Enregistrer', 'Save changes')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
