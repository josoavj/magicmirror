import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  bool _isUploadingAvatar = false;
  bool _isSavingProfile = false;

  void _applyProfileToControllers(UserProfile profile) {
    _displayNameController.text = profile.displayName;
    _avatarUrlController.text = profile.avatarUrl;
  }

  Future<void> _refreshProfileFromCloud() async {
    await ref.read(userProfileProvider.notifier).pullFromCloud();
    if (!mounted) {
      return;
    }
    _applyProfileToControllers(ref.read(userProfileProvider));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await ref.read(userProfileProvider.notifier).setUserId(currentUser.id);
      }
      await _refreshProfileFromCloud();
      if (!mounted) {
        return;
      }
      _applyProfileToControllers(ref.read(userProfileProvider));
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileBasics() async {
    setState(() {
      _isSavingProfile = true;
    });
    try {
      final notifier = ref.read(userProfileProvider.notifier);
      await notifier.setDisplayName(_displayNameController.text);
      await notifier.setAvatarUrl(_avatarUrlController.text);
      await notifier.syncToCloud();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _uploadAvatarFromDevice() async {
    if (_isUploadingAvatar) {
      return;
    }

    Future<Uint8List?> pickWithFilePicker() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return bytes;
    }

    Future<Uint8List?> pickWithImagePicker() async {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile == null) {
        return null;
      }
      return pickedFile.readAsBytes();
    }

    try {
      setState(() {
        _isUploadingAvatar = true;
      });

      Uint8List? bytes;
      try {
        bytes = await pickWithFilePicker();
      } on MissingPluginException {
        bytes = await pickWithImagePicker();
      } on PlatformException {
        bytes = await pickWithImagePicker();
      }

      if (bytes == null || bytes.isEmpty) {
        return;
      }

      final notifier = ref.read(userProfileProvider.notifier);
      final uploadedUrl = await notifier.uploadAvatar(bytes: bytes);
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de mise à jour de la photo.')),
        );
        return;
      }

      _avatarUrlController.text = uploadedUrl;
      await notifier.syncToCloud();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'importer la photo.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    var isSaving = false;
    var showNew = false;
    var showConfirm = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: const Text('Changer le mot de passe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: !showNew,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setLocalState(() {
                            showNew = !showNew;
                          });
                        },
                        icon: Icon(
                          showNew ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: !showConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setLocalState(() {
                            showConfirm = !showConfirm;
                          });
                        },
                        icon: Icon(
                          showConfirm ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          final password = newPasswordController.text;
                          final confirm = confirmController.text;
                          if (password.length < 6) {
                            setLocalState(() {
                              localError =
                                  'Le mot de passe doit contenir au moins 6 caractères.';
                            });
                            return;
                          }
                          if (password != confirm) {
                            setLocalState(() {
                              localError =
                                  'La confirmation du mot de passe ne correspond pas.';
                            });
                            return;
                          }

                          setLocalState(() {
                            localError = null;
                            isSaving = true;
                          });

                          try {
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(password: password),
                            );
                            if (!mounted) {
                              return;
                            }
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Mot de passe mis à jour.'),
                              ),
                            );
                          } on AuthException catch (e) {
                            setLocalState(() {
                              localError = e.message;
                              isSaving = false;
                            });
                          } catch (_) {
                            setLocalState(() {
                              localError =
                                  'Impossible de changer le mot de passe.';
                              isSaving = false;
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    newPasswordController.dispose();
    confirmController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final syncStatus = ref.watch(profileSyncStatusProvider);
    final syncMessage = ref.watch(profileSyncMessageProvider);
    final lastSyncAt = ref.watch(profileLastSyncAtProvider);
    final hasNetworkAvatar =
        profile.avatarUrl.startsWith('http://') ||
        profile.avatarUrl.startsWith('https://');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Paramètres du compte'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: GlassContainer(
                    borderRadius: 18,
                    blur: 24,
                    opacity: 0.1,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compte actif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Email: ${activeUser?.email ?? 'Non connecte'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID: ${activeUser?.id ?? profile.userId}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  borderRadius: 18,
                  blur: 24,
                  opacity: 0.1,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            backgroundImage: hasNetworkAvatar
                                ? NetworkImage(profile.avatarUrl)
                                : null,
                            child: hasNetworkAvatar
                                ? null
                                : Text(
                                    profile.displayName.isNotEmpty
                                        ? profile.displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploadingAvatar
                                  ? null
                                  : _uploadAvatarFromDevice,
                              icon: _isUploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_a_photo_outlined),
                              label: Text(
                                _isUploadingAvatar
                                    ? 'Import en cours...'
                                    : 'Changer la photo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _displayNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Nom affiche'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _avatarUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Photo (URL)'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSavingProfile
                              ? null
                              : _saveProfileBasics,
                          icon: _isSavingProfile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Enregistrer les modifications'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  borderRadius: 18,
                  blur: 24,
                  opacity: 0.1,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Securite',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Changer le mot de passe'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await Supabase.instance.client.auth.signOut();
                            if (!mounted) {
                              return;
                            }
                            navigator.pop();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Se déconnecter'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  borderRadius: 18,
                  blur: 24,
                  opacity: 0.1,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (syncStatus == ProfileSyncStatus.syncing) ...[
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chargement des données cloud...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      const Text(
                        'Synchronisation cloud',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                              label: const Text('Sauvegarder'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _refreshProfileFromCloud();
                              },
                              icon: const Icon(Icons.cloud_download),
                              label: const Text('Synchroniser'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        syncMessage,
                        style: TextStyle(
                          color: _syncStatusColor(syncStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Derniere synchronisation: ${_formatLastSync(lastSyncAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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

  String _formatLastSync(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Jamais';
    }
    final local = dateTime.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy a $hh:$min';
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
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
