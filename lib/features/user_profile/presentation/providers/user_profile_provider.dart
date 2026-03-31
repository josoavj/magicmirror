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

    if (state.birthDate != null) {
      final normalizedAge = _ageFromBirthDate(state.birthDate!);
      if (normalizedAge != state.age) {
        state = state.copyWith(age: normalizedAge);
        await _saveProfile();
      }
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
  }

  Future<void> setDisplayName(String displayName) async {
    final normalized = displayName.trim();
    state = state.copyWith(
      displayName: normalized.isEmpty ? 'Utilisateur' : normalized,
    );
    await _saveProfile();
  }

  Future<void> setAvatarUrl(String avatarUrl) async {
    state = state.copyWith(avatarUrl: avatarUrl.trim());
    await _saveProfile();
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
  }

  Future<void> setAge(int age) async {
    state = state.copyWith(age: age.clamp(12, 100));
    await _saveProfile();
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
  }

  Future<void> setMorphology(String morphology) async {
    state = state.copyWith(morphology: morphology);
    await _saveProfile();
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
  }

  Future<void> syncToCloud() async {
    _ref.read(profileSyncStatusProvider.notifier).state =
        ProfileSyncStatus.syncing;
    _ref.read(profileSyncMessageProvider.notifier).state =
        'Synchronisation en cours...';

    try {
      final resolvedUserId = await _syncService.resolveUserId(
        fallback: state.userId,
      );
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Connectez-vous pour synchroniser votre profil.';
        return;
      }
      if (resolvedUserId != state.userId) {
        state = state.copyWith(userId: resolvedUserId);
      }

      await _syncService.pushProfile(state);
      await _saveProfile();
      _ref.read(profileSyncStatusProvider.notifier).state =
          ProfileSyncStatus.success;
      _ref.read(profileSyncMessageProvider.notifier).state =
          'Profil synchronise avec Supabase.';
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
      final resolvedUserId = await _syncService.resolveUserId(
        fallback: state.userId,
      );
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.failure;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Connectez-vous pour recuperer votre profil cloud.';
        return;
      }
      final remote = await _syncService.fetchProfile(resolvedUserId);
      if (remote != null) {
        state = remote;
        await _saveProfile();
        _ref.read(profileSyncStatusProvider.notifier).state =
            ProfileSyncStatus.success;
        _ref.read(profileSyncMessageProvider.notifier).state =
            'Profil recupere depuis Supabase.';
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
