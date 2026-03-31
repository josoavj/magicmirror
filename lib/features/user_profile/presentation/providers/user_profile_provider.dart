import 'package:flutter_riverpod/legacy.dart';
import 'dart:typed_data';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/data/services/user_profile_sync_service.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier({
    required Ref ref,
    required UserProfileSyncService syncService,
  }) : _ref = ref,
       _syncService = syncService,
       super(UserProfile.defaults()) {
    _loadProfile();
  }

  final Ref _ref;
  final UserProfileSyncService _syncService;

  UserProfile _normalizeDerivedFields(UserProfile profile) {
    if (profile.birthDate == null) {
      return profile;
    }
    return profile.copyWith(age: _ageFromBirthDate(profile.birthDate!));
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final localUserId = prefs.getString('profile.userId') ?? 'local-user';
    final resolvedUserId = await _syncService.resolveUserId(
      fallback: localUserId,
    );

    state = UserProfile(
      userId: resolvedUserId ?? localUserId,
      displayName: prefs.getString('profile.displayName') ?? 'Utilisateur',
      avatarUrl: prefs.getString('profile.avatarUrl') ?? '',
      gender: prefs.getString('profile.gender') ?? 'Non precise',
      age: prefs.getInt('profile.age') ?? 25,
      birthDate: _readBirthDate(prefs.getString('profile.birthDate')),
      morphology:
          prefs.getString('profile.morphology') ?? 'Silhouette non definie',
      preferredStyles:
          prefs.getStringList('profile.preferredStyles') ?? ['Casual'],
    );

    final normalizedLocal = _normalizeDerivedFields(state);
    if (normalizedLocal.age != state.age) {
      state = normalizedLocal;
      await _saveProfile();
    }

    // Si un profil cloud existe pour l'utilisateur authentifie, il devient la source de verite.
    try {
      final authUserId = await _syncService.resolveUserId();
      if (authUserId != null && authUserId.isNotEmpty) {
        if (authUserId != state.userId) {
          state = state.copyWith(userId: authUserId);
        }
        final remote = await _syncService.fetchProfile(authUserId);
        if (remote != null) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile.userId', state.userId);
    await prefs.setString('profile.displayName', state.displayName);
    await prefs.setString('profile.avatarUrl', state.avatarUrl);
    await prefs.setString('profile.gender', state.gender);
    await prefs.setInt('profile.age', state.age);
    await prefs.setString(
      'profile.birthDate',
      state.birthDate?.toIso8601String() ?? '',
    );
    await prefs.setString('profile.morphology', state.morphology);
    await prefs.setStringList('profile.preferredStyles', state.preferredStyles);
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
      final remote = await _syncService.fetchProfile(normalized);
      if (remote != null) {
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
    final resolvedUserId = await _syncService.resolveUserId(
      fallback: state.userId,
    );
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return null;
    }

    final uploadedUrl = await _syncService.uploadAvatarBytes(
      bytes: bytes,
      userId: resolvedUserId,
      fileExtension: fileExtension,
    );

    if (uploadedUrl == null || uploadedUrl.isEmpty) {
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
      birthDate: normalizedBirthDate,
      morphology: morphology,
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

  Future<void> setMorphology(String morphology) async {
    state = state.copyWith(morphology: morphology);
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
      final authUserId = await _syncService.resolveUserId();
      if (authUserId == null || authUserId.isEmpty) {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Connectez-vous pour synchroniser votre profil.';
        return;
      }
      if (authUserId != state.userId) {
        state = state.copyWith(userId: authUserId);
      }

      await _syncService.pushProfile(state);
      await _saveProfile();
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.success;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Profil synchronise avec Supabase.';
      _ref.read(profileLastSyncAtProvider.notifier).state = DateTime.now();
    } catch (_) {
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.failure;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Echec de synchronisation Supabase.';
    }
  }

  Future<void> pullFromCloud() async {
    _ref.read(profileSyncStatusProvider.notifier).state =
        ProfileSyncStatus.syncing;
    _ref.read(profileSyncMessageProvider.notifier).state =
        'Recuperation du profil cloud...';

    try {
      final authUserId = await _syncService.resolveUserId();
      if (authUserId == null || authUserId.isEmpty) {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Connectez-vous pour recuperer votre profil cloud.';
        return;
      }
      if (authUserId != state.userId) {
        state = state.copyWith(userId: authUserId);
      }
      final remote = await _syncService.fetchProfile(authUserId);
      if (remote != null) {
        state = _normalizeDerivedFields(remote);
        await _saveProfile();
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.success;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Profil recupere depuis Supabase.';
        _ref.read(profileLastSyncAtProvider.notifier).state = DateTime.now();
      } else {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Profil introuvable sur Supabase.';
      }
    } catch (_) {
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.failure;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Echec de recuperation depuis Supabase.';
    }
  }
}
