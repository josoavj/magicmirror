import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'dart:typed_data';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/data/services/user_profile_sync_service.dart';
import 'package:magicmirror/core/error/index.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ProfileSyncStatus { idle, syncing, success, failure }

final profileSyncStatusProvider = StateProvider<ProfileSyncStatus>((ref) {
  return ProfileSyncStatus.idle;
});

final profileSyncMessageProvider = StateProvider<String>((ref) {
  return 'Aucune synchronisation';
});

final profileLastSyncAtProvider = StateProvider<DateTime?>((ref) {
  return null;
});

final userProfileSyncServiceProvider = Provider<UserProfileSyncService>((ref) {
  return UserProfileSyncService();
});

final profileSchemaWarningProvider = FutureProvider<String?>((ref) async {
  final syncService = ref.watch(userProfileSyncServiceProvider);
  final result = await syncService.validateProfileSchema();
  return result.fold(
    (failure) {
      // Si error, on retourne le message d'erreur
      if (failure is DatabaseException && failure.code == '42703') {
        return 'Schéma Supabase obsolète. Contactez l\'administrateur.';
      }
      return 'Vérification du schéma échouée.';
    },
    (warning) => warning, // success: null = pas d'erreur
  );
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      final syncService = ref.watch(userProfileSyncServiceProvider);
      return UserProfileNotifier(ref: ref, syncService: syncService);
    });

int _ageFromBirthDate(DateTime birthDate) {
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

String _foldDiacritics(String value) {
  const diacriticsMap = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(diacriticsMap[char] ?? char);
  }
  return buffer.toString();
}

String _normalizeMorphologyKey(String value) {
  final lowered = value.trim().toLowerCase();
  final folded = _foldDiacritics(lowered);
  return folded.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _canonicalizeMorphology(String raw) {
  const fallback = 'Silhouette non définie';
  final value = raw.trim();
  if (value.isEmpty) {
    return fallback;
  }

  const canonicalByKey = <String, String>{
    'silhouettenondefinie': 'Silhouette non définie',
    'hanchesetepaulesequilibrees': 'Hanches et épaules équilibrées',
    'hanchesplusmarquees': 'Hanches plus marquées',
    'silhouettedroite': 'Silhouette droite',
    'epaulespluslarges': 'Épaules plus larges',
    'epaulestresmarquees': 'Épaules très marquées',
    'tailletresmarquee': 'Taille très marquée',
    'hanchestresmarquees': 'Hanches très marquées',
  };

  return canonicalByKey[_normalizeMorphologyKey(value)] ?? fallback;
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier({
    required Ref ref,
    required UserProfileSyncService syncService,
  }) : _ref = ref,
       _syncService = syncService,
       super(UserProfile.defaults()) {
    Future.microtask(_loadProfile);
  }

  final Ref _ref;
  final UserProfileSyncService _syncService;

  UserProfile _normalizeDerivedFields(UserProfile profile) {
    final normalizedMorphology = _canonicalizeMorphology(profile.morphology);
    final normalizedProfile = profile.copyWith(
      morphology: normalizedMorphology,
    );

    if (profile.birthDate == null) {
      return normalizedProfile;
    }
    return normalizedProfile.copyWith(
      age: _ageFromBirthDate(normalizedProfile.birthDate!),
    );
  }

  Future<void> _loadProfile() async {
    const storage = FlutterSecureStorage();
    final localUserId =
        await storage.read(key: 'profile.userId') ?? 'local-user';
    final userIdResult = await _syncService.resolveUserId(
      fallback: localUserId,
    );
    final resolvedUserId = userIdResult.getOrNull() ?? localUserId;

    final displayName =
        await storage.read(key: 'profile.displayName') ?? 'Utilisateur';
    final avatarUrl = await storage.read(key: 'profile.avatarUrl') ?? '';
    final gender = await storage.read(key: 'profile.gender') ?? 'Non précise';

    final ageStr = await storage.read(key: 'profile.age');
    final age = ageStr != null ? int.tryParse(ageStr) ?? 25 : 25;

    final heightCmStr = await storage.read(key: 'profile.heightCm');
    final heightCm =
        (heightCmStr != null ? int.tryParse(heightCmStr) ?? 170 : 170).clamp(
          120,
          230,
        );

    final birthDateStr = await storage.read(key: 'profile.birthDate');
    final morphology =
        await storage.read(key: 'profile.morphology') ??
        'Silhouette non définie';

    final preferredStylesStr = await storage.read(
      key: 'profile.preferredStyles',
    );
    final preferredStyles =
        preferredStylesStr != null && preferredStylesStr.isNotEmpty
        ? preferredStylesStr.split('|||')
        : ['Casual'];

    state = UserProfile(
      userId: resolvedUserId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      gender: gender,
      age: age,
      heightCm: heightCm,
      birthDate: _readBirthDate(birthDateStr),
      morphology: morphology,
      preferredStyles: preferredStyles,
    );

    final normalizedLocal = _normalizeDerivedFields(state);
    if (normalizedLocal.age != state.age ||
        normalizedLocal.morphology != state.morphology) {
      state = normalizedLocal;
      await _saveProfile();
    }

    // Si un profil cloud existe pour l'utilisateur authentifie, il devient la source de verite.
    try {
      final authUserIdResult = await _syncService.resolveUserId();
      if (authUserIdResult.isSuccess) {
        final authUserId = authUserIdResult.getOrNull()!;
        if (authUserId != state.userId) {
          state = state.copyWith(userId: authUserId);
        }
        final remoteResult = await _syncService.fetchProfile(authUserId);
        if (remoteResult.isSuccess) {
          final remote = remoteResult.getOrNull()!;
          state = _normalizeDerivedFields(remote);
          await _saveProfile();
          _ref.read(profileLastSyncAtProvider.notifier).state = DateTime.now();
        }
      }
    } catch (_) {
      // On garde le profil local si la récupération cloud échoue au démarrage.
    }
  }

  DateTime? _readBirthDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> _saveProfile() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'profile.userId', value: state.userId);
    await storage.write(key: 'profile.displayName', value: state.displayName);
    await storage.write(key: 'profile.avatarUrl', value: state.avatarUrl);
    await storage.write(key: 'profile.gender', value: state.gender);
    await storage.write(key: 'profile.age', value: state.age.toString());
    await storage.write(
      key: 'profile.heightCm',
      value: state.heightCm.toString(),
    );
    await storage.write(
      key: 'profile.birthDate',
      value: state.birthDate?.toIso8601String() ?? '',
    );
    await storage.write(key: 'profile.morphology', value: state.morphology);
    await storage.write(
      key: 'profile.preferredStyles',
      value: state.preferredStyles.join('|||'),
    );
  }

  Future<void> setUserId(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return;
    }
    state = state.copyWith(userId: normalized);
    await _saveProfile();

    // Quand l'utilisateur actif est connu, on recharge depuis Supabase.
    try {
      final remoteResult = await _syncService.fetchProfile(normalized);
      if (remoteResult.isSuccess) {
        final remote = remoteResult.getOrNull()!;
        state = _normalizeDerivedFields(remote);
        await _saveProfile();
      }
    } catch (_) {
      // On conserve l'etat local si la lecture cloud echoue.
    }
  }

  Future<void> setDisplayName(String displayName) async {
    final normalized = displayName.trim();
    state = state.copyWith(
      displayName: normalized.isEmpty ? 'Utilisateur' : normalized,
    );
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> setAvatarUrl(String avatarUrl) async {
    state = state.copyWith(avatarUrl: avatarUrl.trim());
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<String?> uploadAvatar({
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    final userIdResult = await _syncService.resolveUserId(
      fallback: state.userId,
    );

    if (userIdResult.isFailure) {
      return null;
    }

    final resolvedUserId = userIdResult.getOrNull()!;

    final uploadResult = await _syncService.uploadAvatarBytes(
      bytes: bytes,
      userId: resolvedUserId,
      fileExtension: fileExtension,
    );

    if (uploadResult.isFailure) {
      return null;
    }

    final uploadedUrl = uploadResult.getOrNull()!;
    if (uploadedUrl.isEmpty) {
      return null;
    }

    state = state.copyWith(userId: resolvedUserId, avatarUrl: uploadedUrl);
    await _saveProfile();
    return uploadedUrl;
  }

  Future<void> applyOnboardingProfile({
    required String displayName,
    required String avatarUrl,
    required String gender,
    required DateTime birthDate,
    required int heightCm,
    required String morphology,
    required List<String> preferredStyles,
    String? userId,
    bool syncIfConnected = true,
  }) async {
    final resolvedName = displayName.trim().isEmpty
        ? 'Utilisateur'
        : displayName.trim();
    final resolvedStyles = preferredStyles.isEmpty
        ? const ['Casual']
        : preferredStyles;

    final normalizedBirthDate = DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day,
    );

    state = state.copyWith(
      userId: (userId?.trim().isNotEmpty ?? false)
          ? userId!.trim()
          : state.userId,
      displayName: resolvedName,
      avatarUrl: avatarUrl.trim(),
      gender: gender,
      age: _ageFromBirthDate(normalizedBirthDate),
      heightCm: heightCm.clamp(120, 230),
      birthDate: normalizedBirthDate,
      morphology: _canonicalizeMorphology(morphology),
      preferredStyles: resolvedStyles,
    );

    await _saveProfile();

    if (syncIfConnected) {
      await syncToCloud();
    }
  }

  Future<void> setGender(String gender) async {
    state = state.copyWith(gender: gender);
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> setAge(int age) async {
    state = state.copyWith(age: age.clamp(12, 100));
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> setBirthDate(DateTime birthDate) async {
    final normalizedBirthDate = DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day,
    );
    state = state.copyWith(
      birthDate: normalizedBirthDate,
      age: _ageFromBirthDate(normalizedBirthDate),
    );
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> setHeightCm(int heightCm) async {
    state = state.copyWith(heightCm: heightCm.clamp(120, 230));
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> setMorphology(String morphology) async {
    state = state.copyWith(morphology: _canonicalizeMorphology(morphology));
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> togglePreferredStyle(String style) async {
    final styles = [...state.preferredStyles];

    if (styles.contains(style)) {
      if (styles.length > 1) {
        styles.remove(style);
      }
    } else {
      styles.add(style);
    }

    state = state.copyWith(preferredStyles: styles);
    await _saveProfile();
    await _syncToCloudSilently();
  }

  Future<void> _syncToCloudSilently() async {
    try {
      await syncToCloud();
    } catch (_) {
      // Le statut de sync est deja gere par syncToCloud.
    }
  }

  Future<void> syncToCloud() async {
    _ref.read(profileSyncStatusProvider.notifier).state =
        ProfileSyncStatus.syncing;
    _ref.read(profileSyncMessageProvider.notifier).state =
        'Synchronisation en cours...';

    try {
      final authUserIdResult = await _syncService.resolveUserId();
      if (authUserIdResult.isFailure) {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Connectez-vous pour synchroniser votre profil.';
        return;
      }

      final authUserId = authUserIdResult.getOrNull()!;
      if (authUserId != state.userId) {
        state = state.copyWith(userId: authUserId);
      }

      final saveResult = await _syncService.pushProfile(state);

      if (saveResult.isFailure) {
        final error = saveResult.exceptionOrNull()!;

        // Si c'est une erreur réseau, enqueue pour retry offline
        if (error is NetworkException) {
          // Enqueue the update to the offline queue for later retry
          final queueItem = ProfileUpdateQueueItem(
            id: state.userId,
            displayName: state.displayName,
            avatarUrl: state.avatarUrl,
            gender: state.gender,
            heightCm: state.heightCm,
            birthDate: state.birthDate,
            morphology: state.morphology,
            preferredStyles: state.preferredStyles,
          );

          try {
            await OfflineQueue.enqueue(
              state.userId,
              jsonEncode(queueItem.toJson()),
            );
          } catch (_) {
            // Silent fail if queue can't persist
          }

          _ref.read(profileSyncStatusProvider.notifier).state =
              ProfileSyncStatus.failure;
          _ref.read(profileSyncMessageProvider.notifier).state =
              'Hors ligne. Synchronisation différée.';
          return;
        }

        // Si c'est une erreur d'auth, afficher le message
        if (error is AuthException) {
          _ref.read(profileSyncStatusProvider.notifier).state =
              ProfileSyncStatus.failure;
          _ref.read(profileSyncMessageProvider.notifier).state =
              'Authentification requise pour synchroniser.';
          return;
        }

        // Autres erreurs
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref
            .read(profileSyncMessageProvider.notifier)
            .state = error is DatabaseException && error.code == '23505'
            ? 'Profil déjà utilisé par un autre compte.'
            : 'Synchronisation échouée: ${error.message}';
        return;
      }

      final saved = saveResult.getOrNull()!;
      state = _normalizeDerivedFields(saved);
      await _saveProfile();
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.success;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Profil synchronisé avec Supabase.';
      _ref.read(profileLastSyncAtProvider.notifier).state = DateTime.now();
    } catch (e) {
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.failure;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Erreur inattendue lors de la synchronisation.';
    }
  }

  Future<void> pullFromCloud() async {
    _ref.read(profileSyncStatusProvider.notifier).state =
        ProfileSyncStatus.syncing;
    _ref.read(profileSyncMessageProvider.notifier).state =
        'Récupération du profil cloud...';

    try {
      final authUserIdResult = await _syncService.resolveUserId();
      if (authUserIdResult.isFailure) {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Connectez-vous pour récupérer votre profil cloud.';
        return;
      }

      final authUserId = authUserIdResult.getOrNull()!;
      if (authUserId != state.userId) {
        state = state.copyWith(userId: authUserId);
      }

      final remoteResult = await _syncService.fetchProfile(authUserId);

      if (remoteResult.isFailure) {
        final error = remoteResult.exceptionOrNull()!;
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;

        if (error is DatabaseException && error.code == 'NOT_FOUND') {
          _ref.read(profileSyncMessageProvider.notifier).state =
              'Profil introuvable sur Supabase.';
        } else if (error is NetworkException) {
          _ref.read(profileSyncMessageProvider.notifier).state =
              'Erreur réseau lors de la récupération.';
        } else {
          _ref.read(profileSyncMessageProvider.notifier).state =
              'Récupération échouée: ${error.message}';
        }
        return;
      }

      final remote = remoteResult.getOrNull()!;
      state = _normalizeDerivedFields(remote);
      await _saveProfile();
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.success;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Profil récupéré depuis Supabase.';
      _ref.read(profileLastSyncAtProvider.notifier).state = DateTime.now();
    } catch (e) {
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.failure;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Erreur inattendue lors de la récupération.';
    }
  }
}
