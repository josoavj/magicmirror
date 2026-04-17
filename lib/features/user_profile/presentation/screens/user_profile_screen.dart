import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  static const List<String> _genders = ['Femme', 'Homme', 'Non précise'];

  static const List<String> _morphologies = [
    'Silhouette non définie',
    'Hanches et épaules équilibrées',
    'Hanches plus marquées',
    'Silhouette droite',
    'Épaules plus larges',
    'Épaules très marquées',
    'Taille très marquée',
    'Hanches très marquées',
  ];

  static const List<String> _styles = [
    'Casual',
    'Elegant',
    'Sport',
    'Streetwear',
    'Business',
    'Minimaliste',
  ];

  bool _isEditMode = false;
  bool _isAvatarUploading = false;

  Future<bool> _confirmBeforeAfterAvatar({
    required Uint8List afterBytes,
    Uint8List? beforeBytes,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la photo'),
          content: SizedBox(
            width: 320,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Avant'),
                      const SizedBox(height: 6),
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: beforeBytes != null
                              ? Image.memory(beforeBytes, fit: BoxFit.cover)
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Après'),
                      const SizedBox(height: 6),
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(afterBytes, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
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
    return confirmed ?? false;
  }

  Future<void> _pickCropAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) {
      return;
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [],
    );

    CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
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
      return;
    }

    final bytes = await cropped.readAsBytes();
    if (bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image invalide apres rognage.')),
      );
      return;
    }

    Uint8List? beforeBytes;
    try {
      beforeBytes = await picked.readAsBytes();
    } catch (_) {
      beforeBytes = null;
    }

    final confirmed = await _confirmBeforeAfterAvatar(
      afterBytes: bytes,
      beforeBytes: beforeBytes,
    );
    if (!confirmed) {
      return;
    }

    final dot = cropped.path.lastIndexOf('.');
    final ext = dot >= 0
        ? cropped.path.substring(dot + 1).toLowerCase()
        : 'jpg';

    setState(() {
      _isAvatarUploading = true;
    });

    try {
      final notifier = ref.read(userProfileProvider.notifier);
      final uploadedUrl = await notifier.uploadAvatar(
        bytes: bytes,
        fileExtension: ext,
      );
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        await notifier.syncToCloud();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload avatar impossible.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour de la photo.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAvatarUploading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(userProfileProvider.notifier);
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await notifier.setUserId(currentUser.id);
      }
      await notifier.pullFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(userProfileProvider);
    final detectedMorphology = ref.watch(currentMorphologyProvider);
    final syncStatus = ref.watch(profileSyncStatusProvider);
    final syncMessage = ref.watch(profileSyncMessageProvider);
    final lastSyncAt = ref.watch(profileLastSyncAtProvider);
    final schemaWarningAsync = ref.watch(profileSchemaWarningProvider);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final activeEmail =
        activeUser?.email ?? _tr(context, 'Non connecte', 'Not connected');
    final isEmailVerified = activeUser?.emailConfirmedAt != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'User Profile' : 'Profil utilisateur'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                schemaWarningAsync.when(
                  data: (warning) {
                    if (warning == null || warning.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        GlassContainer(
                          borderRadius: 14,
                          blur: 20,
                          opacity: 0.12,
                          tintColor: Colors.amber,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                if (syncStatus == ProfileSyncStatus.syncing) ...[
                  GlassContainer(
                    borderRadius: 14,
                    blur: 20,
                    opacity: 0.11,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Chargement des donnees cloud...',
                              'Loading cloud data...',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _SectionCard(
                  title: _tr(context, 'Compte actif', 'Active account'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: $activeEmail',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${activeUser?.id ?? profile.userId}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEmailVerified
                            ? _tr(context, 'Email verifie', 'Email verified')
                            : _tr(
                                context,
                                'Email non verifie',
                                'Email not verified',
                              ),
                        style: TextStyle(
                          color: isEmailVerified
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/account-settings');
                          },
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: Text(
                            _tr(
                              context,
                              'Gerer mon compte',
                              'Manage my account',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Identite', 'Identity'),
                  child: Column(
                    children: [
                      _ProfileHeader(
                        displayName: profile.displayName,
                        avatarUrl: profile.avatarUrl,
                      ),
                      const SizedBox(height: 12),
                      if (_isEditMode)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isAvatarUploading
                                ? null
                                : _pickCropAndUploadAvatar,
                            icon: _isAvatarUploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.crop),
                            label: Text(
                              _isAvatarUploading
                                  ? _tr(
                                      context,
                                      'Mise à jour photo...',
                                      'Updating photo...',
                                    )
                                  : _tr(
                                      context,
                                      'Importer et rogner la photo',
                                      'Import and crop photo',
                                    ),
                            ),
                          ),
                        ),
                      if (_isEditMode) const SizedBox(height: 12),
                      if (_isEditMode)
                        _EditableTextRow(
                          icon: Icons.person,
                          label: _tr(context, 'Nom', 'Name'),
                          value: profile.displayName,
                          hint: 'Ex: Alex',
                          onSubmitted: (value) {
                            ref
                                .read(userProfileProvider.notifier)
                                .setDisplayName(value);
                          },
                        )
                      else
                        _ReadOnlyInfoRow(
                          icon: Icons.person,
                          label: _tr(context, 'Nom', 'Name'),
                          value: profile.displayName,
                        ),
                      const SizedBox(height: 12),
                      if (_isEditMode)
                        _EditableTextRow(
                          icon: Icons.photo,
                          label: _tr(context, 'Avatar (URL)', 'Avatar (URL)'),
                          value: profile.avatarUrl,
                          hint: 'https://...',
                          onSubmitted: (value) {
                            ref
                                .read(userProfileProvider.notifier)
                                .setAvatarUrl(value);
                          },
                        )
                      else
                        _ReadOnlyInfoRow(
                          icon: Icons.photo,
                          label: _tr(context, 'Avatar (URL)', 'Avatar (URL)'),
                          value: profile.avatarUrl.isEmpty
                              ? _tr(context, 'Non renseignee', 'Not set')
                              : profile.avatarUrl,
                        ),
                      const SizedBox(height: 12),
                      if (_isEditMode)
                        _DropdownField(
                          icon: Icons.wc,
                          label: _tr(context, 'Sexe', 'Gender'),
                          value: profile.gender,
                          items: _genders,
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(userProfileProvider.notifier)
                                  .setGender(value);
                            }
                          },
                        )
                      else
                        _ReadOnlyInfoRow(
                          icon: Icons.wc,
                          label: _tr(context, 'Sexe', 'Gender'),
                          value: profile.gender,
                        ),
                      const SizedBox(height: 12),
                      _BirthDateField(
                        age: profile.age,
                        birthDate: profile.birthDate,
                        enabled: _isEditMode,
                      ),
                      const SizedBox(height: 12),
                      if (_isEditMode)
                        _EditableTextRow(
                          icon: Icons.height,
                          label: _tr(context, 'Taille (cm)', 'Height (cm)'),
                          value: profile.heightCm.toString(),
                          hint: '170',
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) {
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null ||
                                parsed < 120 ||
                                parsed > 230) {
                              return;
                            }
                            ref
                                .read(userProfileProvider.notifier)
                                .setHeightCm(parsed);
                          },
                        )
                      else
                        _ReadOnlyInfoRow(
                          icon: Icons.height,
                          label: _tr(context, 'Taille', 'Height'),
                          value:
                              '${profile.heightCm} ${_tr(context, 'cm', 'cm')}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Morphologie', 'Body Type'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditMode)
                        _DropdownField(
                          icon: Icons.accessibility_new,
                          label: _tr(context, 'Morphologie', 'Body Type'),
                          value: profile.morphology,
                          items: _morphologies,
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(userProfileProvider.notifier)
                                  .setMorphology(value);
                            }
                          },
                        )
                      else
                        _ReadOnlyInfoRow(
                          icon: Icons.accessibility_new,
                          label: _tr(context, 'Morphologie', 'Body Type'),
                          value: profile.morphology,
                        ),
                      const SizedBox(height: 12),
                      if (detectedMorphology != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_tr(context, 'Détection IA', 'AI detection')}: ${detectedMorphology.bodyType}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _isEditMode
                                  ? () {
                                      ref
                                          .read(userProfileProvider.notifier)
                                          .setMorphology(
                                            detectedMorphology.bodyType,
                                          );
                                    }
                                  : null,
                              child: Text(_tr(context, 'Utiliser', 'Use')),
                            ),
                          ],
                        )
                      else
                        Text(
                          _tr(
                            context,
                            'Lancez la detection ML pour proposer une morphologie automatiquement.',
                            'Run ML detection to suggest body type automatically.',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(
                    context,
                    'Préférences vestimentaires',
                    'Style preferences',
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _styles.map((style) {
                      final isSelected = profile.preferredStyles.contains(
                        style,
                      );
                      return FilterChip(
                        label: Text(style),
                        selected: isSelected,
                        onSelected: _isEditMode
                            ? (_) {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .togglePreferredStyle(style);
                              }
                            : null,
                        selectedColor: Colors.blue.withValues(alpha: 0.55),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        checkmarkColor: Colors.white,
                        labelStyle: const TextStyle(color: Colors.white),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                          });
                        },
                        icon: Icon(
                          _isEditMode ? Icons.check_circle : Icons.edit,
                        ),
                        label: Text(
                          _isEditMode
                              ? _tr(
                                  context,
                                  'Terminer la mise à jour',
                                  'Finish update',
                                )
                              : _tr(
                                  context,
                                  'Mettre à jour les infos et préférences',
                                  'Update info and preferences',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Synchronisation cloud', 'Cloud sync'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .syncToCloud();
                              },
                              icon: const Icon(Icons.cloud_upload),
                              label: Text(_tr(context, 'Sauvegarder', 'Save')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .pullFromCloud();
                              },
                              icon: const Icon(Icons.cloud_download),
                              label: Text(_tr(context, 'Synchroniser', 'Sync')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        syncMessage,
                        style: TextStyle(
                          color: _syncStatusColor(syncStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_tr(context, 'Derniere synchronisation', 'Last sync')}: ${_formatLastSync(lastSyncAt, context)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Resume', 'Summary'),
                  child: Text(
                    '${_tr(context, 'Profil', 'Profile')}: ${profile.displayName}, ${profile.gender}, ${profile.age} ${_tr(context, 'ans', 'years')}, ${profile.heightCm} cm, ${profile.morphology} - ${_tr(context, 'styles', 'styles')}: ${profile.preferredStyles.join(', ')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _syncStatusColor(ProfileSyncStatus status) {
    switch (status) {
      case ProfileSyncStatus.success:
        return Colors.greenAccent;
      case ProfileSyncStatus.failure:
        return Colors.redAccent;
      case ProfileSyncStatus.syncing:
        return Colors.amberAccent;
      case ProfileSyncStatus.idle:
        return Colors.white70;
    }
  }

  String _formatLastSync(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) {
      return _tr(context, 'Jamais', 'Never');
    }
    final local = dateTime.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy ${_tr(context, 'a', 'at')} $hh:$min';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      blur: 24,
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              hint: Text(label, style: const TextStyle(color: Colors.white70)),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _BirthDateField extends ConsumerWidget {
  final int age;
  final DateTime? birthDate;
  final bool enabled;

  const _BirthDateField({
    required this.age,
    required this.birthDate,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final birthDateText = birthDate == null
        ? (isEnglish ? 'Not set' : 'Non renseignee')
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cake, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              isEnglish ? 'Age: $age years' : 'Age: $age ans',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final now = DateTime.now();
                    final maxDate = DateTime(now.year - 12, now.month, now.day);
                    final minDate = DateTime(
                      now.year - 100,
                      now.month,
                      now.day,
                    );
                    final initialDate =
                        birthDate ??
                        DateTime(now.year - 25, now.month, now.day);

                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initialDate.isAfter(maxDate)
                          ? maxDate
                          : initialDate,
                      firstDate: minDate,
                      lastDate: maxDate,
                    );

                    if (selected == null) {
                      return;
                    }

                    await ref
                        .read(userProfileProvider.notifier)
                        .setBirthDate(
                          DateTime(selected.year, selected.month, selected.day),
                        );
                  },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              isEnglish
                  ? 'Birth date: $birthDateText'
                  : 'Date de naissance: $birthDateText',
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String avatarUrl;

  const _ProfileHeader({required this.displayName, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasNetworkAvatar =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          backgroundImage: hasNetworkAvatar ? NetworkImage(avatarUrl) : null,
          child: hasNetworkAvatar
              ? null
              : Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableTextRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String> onSubmitted;

  const _EditableTextRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.keyboardType,
    required this.onSubmitted,
  });

  @override
  State<_EditableTextRow> createState() => _EditableTextRowState();
}

class _EditableTextRowState extends State<_EditableTextRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _EditableTextRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
