// ignore_for_file: unused_field, unused_element

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
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
  bool _editing = false;
  bool _saving = false;
  String _gender = _genders.last;
  String _morphology = _morphologies.first;
  int _heightCm = 170;
  DateTime? _birthDate;
  bool _clearBirthDate = false;
  Set<String> _selectedStyles = {'Casual'};
  Uint8List? _pendingAvatar;

  bool _isEnglish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en';

  String _tr(BuildContext context, String fr, String en) =>
      _isEnglish(context) ? en : fr;

  String _formatBirthDate(BuildContext context, DateTime date) {
    final locale = _isEnglish(context) ? 'en_US' : 'fr_FR';
    return formatDisplayDate(date, locale: locale);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _startEditing(UserProfile profile) {
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
    _pendingAvatar = null;
    setState(() => _editing = true);
  }

  Future<void> _pickAvatar() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _showMessage(
        _tr(
          context,
          'Connecte-toi pour envoyer une photo. Tu peux aussi saisir une URL.',
          'Sign in to upload a photo, or enter an image URL.',
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
      helpText: _tr(context, 'Date de naissance', 'Date of birth'),
    );
    if (value != null) {
      setState(() {
        _birthDate = value;
        _clearBirthDate = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
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
    setState(() => _saving = true);
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
      final synced =
          ref.read(profileSyncStatusProvider) == ProfileSyncStatus.success;
      setState(() {
        _editing = false;
        _pendingAvatar = null;
      });
      _showMessage(
        synced
            ? _tr(
                context,
                'Profil enregistré et synchronisé.',
                'Profile saved and synced.',
              )
            : _tr(
                context,
                'Profil enregistré sur cet appareil. La synchronisation cloud est en attente ou indisponible.',
                'Profile saved on this device. Cloud sync is pending or unavailable.',
              ),
      );
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
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildUsername(User? activeUser, UserProfile profile) {
    final email = activeUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return '@$localPart';
      }
    }

    final fallback = profile.userId.trim();
    return fallback.isNotEmpty ? '@$fallback' : '@utilisateur';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final syncStatus = ref.watch(profileSyncStatusProvider);
    final syncMessage = ref.watch(profileSyncMessageProvider);
    final lastSyncAt = ref.watch(profileLastSyncAtProvider);
    final schemaWarning = ref
        .watch(profileSchemaWarningProvider)
        .maybeWhen(data: (warning) => warning, orElse: () => null);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final username = _buildUsername(activeUser, profile);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(_tr(context, 'Mon profil', 'My profile')),
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surface, colors.surfaceContainerHighest],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ProfileSectionCard(
                title: _tr(context, 'Compte', 'Account'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoLine(
                      Icons.email_outlined,
                      'Email',
                      activeUser?.email ??
                          _tr(context, 'Mode local', 'Local profile'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          syncStatus == ProfileSyncStatus.success
                              ? Icons.cloud_done_outlined
                              : syncStatus == ProfileSyncStatus.syncing
                              ? Icons.sync
                              : syncStatus == ProfileSyncStatus.failure
                              ? Icons.cloud_off_outlined
                              : Icons.cloud_queue_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            syncMessage,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (lastSyncAt != null) ...[
                      const SizedBox(height: 8),
                      _infoLine(
                        Icons.history,
                        _tr(context, 'Dernière synchronisation', 'Last sync'),
                        formatDisplayDateTime(
                          lastSyncAt,
                          locale: _isEnglish(context) ? 'en_US' : 'fr_FR',
                        ),
                      ),
                    ],
                    if (schemaWarning != null && schemaWarning.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: colors.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              schemaWarning,
                              style: TextStyle(
                                color: colors.tertiary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                activeUser == null ||
                                    syncStatus == ProfileSyncStatus.syncing
                                ? null
                                : () => ref
                                      .read(userProfileProvider.notifier)
                                      .syncToCloud(),
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: Text(
                              _tr(context, 'Synchroniser', 'Sync now'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/account-settings',
                            ),
                            icon: const Icon(Icons.security_outlined),
                            label: Text(
                              _tr(
                                context,
                                'Sécurité du compte',
                                'Account security',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSummary(profile, username),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(UserProfile profile, String username) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ProfileSectionCard(
          title: _tr(context, 'Identité', 'Identity'),
          child: Column(
            children: [
              ProfileHeader(
                displayName: profile.displayName,
                username: username,
                avatarUrl: profile.avatarUrl,
              ),
              const SizedBox(height: 18),
              _infoLine(
                Icons.person_outline,
                _tr(context, 'Nom et prénom', 'Full name'),
                profile.displayName,
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.alternate_email,
                _tr(context, 'Nom d’utilisateur', 'Username'),
                username,
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.wc,
                _tr(context, 'Genre', 'Gender'),
                profile.gender,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: _tr(
            context,
            'Mesure et morphologie',
            'Measurements and shape',
          ),
          child: Column(
            children: [
              _infoLine(
                Icons.cake_outlined,
                _tr(context, 'Âge', 'Age'),
                '${profile.age} ${_tr(context, 'ans', 'years')}',
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.straighten,
                _tr(context, 'Taille', 'Height'),
                '${profile.heightCm} cm',
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.accessibility_new,
                _tr(context, 'Morphologie', 'Body shape'),
                profile.morphology,
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.event_outlined,
                _tr(context, 'Date de naissance', 'Birth date'),
                profile.birthDate == null
                    ? _tr(context, 'Non renseignée', 'Not set')
                    : _formatBirthDate(context, profile.birthDate!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: _tr(context, 'Styles préférés', 'Preferred styles'),
          child: profile.preferredStyles.isEmpty
              ? Text(
                  _tr(
                    context,
                    'Aucun style sélectionné.',
                    'No styles selected.',
                  ),
                  style: TextStyle(color: colors.onSurfaceVariant),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: profile.preferredStyles
                      .map(
                        (style) => Chip(
                          avatar: Icon(
                            Icons.check,
                            size: 16,
                            color: colors.onSecondaryContainer,
                          ),
                          label: Text(
                            style,
                            style: TextStyle(
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                          backgroundColor: colors.secondaryContainer,
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildEditor(UserProfile profile) {
    final isEnglish = _isEnglish(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final avatarProvider = _pendingAvatar != null
        ? MemoryImage(_pendingAvatar!)
        : profile.avatarUrl.startsWith('http')
        ? NetworkImage(profile.avatarUrl) as ImageProvider
        : null;
    return ProfileSectionCard(
      title: _tr(context, 'Modifier mes informations', 'Edit my information'),
      child: Form(
        key: _formKey,
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
                    onPressed: _saving ? null : _pickAvatar,
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
              style: theme.textTheme.bodyLarge,
              decoration: _inputDecoration(
                _tr(context, 'Nom affiché', 'Display name'),
                Icons.person_outline,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? _tr(context, 'Le nom est obligatoire.', 'Name is required.')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _avatarController,
              style: theme.textTheme.bodyLarge,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(
                _tr(
                  context,
                  'URL de la photo (facultatif)',
                  'Photo URL (optional)',
                ),
                Icons.link,
              ),
              validator: (value) {
                final url = value?.trim() ?? '';
                if (url.isEmpty) return null;
                final parsed = Uri.tryParse(url);
                if (parsed == null ||
                    !parsed.hasAuthority ||
                    !{'http', 'https'}.contains(parsed.scheme.toLowerCase())) {
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
              dropdownColor: colors.surfaceContainer,
              decoration: _inputDecoration(
                _tr(context, 'Genre', 'Gender'),
                Icons.wc,
              ),
              items: _genders
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value, style: theme.textTheme.bodyLarge),
                    ),
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
                    ? _tr(
                        context,
                        'Ajouter une date de naissance',
                        'Add birth date',
                      )
                    : '${_tr(context, 'Date de naissance', 'Birth date')} : ${_formatBirthDate(context, _birthDate!)}',
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
                  label: Text(_tr(context, 'Effacer la date', 'Clear date')),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${_tr(context, 'Taille', 'Height')} : $_heightCm cm',
              style: theme.textTheme.bodyMedium,
            ),
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
              dropdownColor: colors.surfaceContainer,
              decoration: _inputDecoration(
                _tr(context, 'Morphologie', 'Body shape'),
                Icons.accessibility_new,
              ),
              items: _morphologies
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
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
                        : () => setState(() {
                            _editing = false;
                            _pendingAvatar = null;
                          }),
                    child: Text(_tr(context, 'Annuler', 'Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isEnglish ? 'Save changes' : 'Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colors.onSurfaceVariant),
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }
}
