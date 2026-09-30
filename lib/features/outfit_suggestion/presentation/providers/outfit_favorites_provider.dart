import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/core/services/storage_service.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/services/outfit_favorites_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final outfitFavoritesSyncServiceProvider = Provider<OutfitFavoritesSyncService>(
  (ref) {
    return OutfitFavoritesSyncService();
  },
);

final outfitFavoritesProvider =
    StateNotifierProvider<OutfitFavoritesNotifier, Set<String>>((ref) {
      return OutfitFavoritesNotifier(
        ref.watch(storageServiceProvider),
        ref.watch(outfitFavoritesSyncServiceProvider),
      );
    });

class OutfitFavoritesNotifier extends StateNotifier<Set<String>> {
  OutfitFavoritesNotifier(this._storageService, this._syncService)
    : super(<String>{}) {
    _activeUserId = _syncService.currentUserId;
    _localLoad = _loadLocal();
    _listenForSignIn();
    unawaited(_loadCloudForCurrentUser());
  }

  static const _prefsKey = 'outfit.favorites.v1';

  final StorageService _storageService;
  final OutfitFavoritesSyncService _syncService;
  late final Future<void> _localLoad;
  StreamSubscription<AuthState>? _authSubscription;
  Future<void> _cloudWriteQueue = Future<void>.value();
  String? _activeUserId;
  int _changeVersion = 0;

  Future<void> _loadLocal() async {
    final list = await _storageService.getList(_prefsKey);
    if (list != null) state = list.toSet();
  }

  void _listenForSignIn() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((authState) {
            final userId = authState.session?.user.id;
            if (userId != null) unawaited(_loadCloud(userId));
          });
    } catch (_) {
      // Favoris restent disponibles localement si Supabase n'est pas configuré.
    }
  }

  Future<void> _loadCloudForCurrentUser() async {
    await _localLoad;
    final userId = _syncService.currentUserId;
    if (userId != null) await _loadCloud(userId);
  }

  Future<void> _loadCloud(String userId) async {
    await _localLoad;
    final isFirstSignIn = _activeUserId == null;
    if (_activeUserId != null && _activeUserId != userId) {
      state = <String>{};
      _changeVersion++;
      await _saveLocal();
    }
    _activeUserId = userId;
    final versionBeforeFetch = _changeVersion;
    try {
      final cloudFavorites = await _syncService.fetchFavorites(userId);
      if (versionBeforeFetch != _changeVersion) {
        await _queueCloudSave(userId, state);
      } else if (cloudFavorites == null) {
        await _queueCloudSave(userId, state);
      } else if (isFirstSignIn) {
        state = {...state, ...cloudFavorites};
        await _saveLocal();
        await _queueCloudSave(userId, state);
      } else {
        state = cloudFavorites;
        await _saveLocal();
      }
    } catch (_) {
      // Conserver les favoris locaux si le cloud est temporairement indisponible.
    }
  }

  Future<void> toggleFavorite(String outfitId) async {
    await _localLoad;
    final next = Set<String>.from(state);
    if (!next.add(outfitId)) next.remove(outfitId);

    _changeVersion++;
    state = next;
    await _saveLocal();

    final userId = _syncService.currentUserId;
    if (userId == null) return;
    try {
      await _queueCloudSave(userId, next);
    } catch (_) {
      // L'enregistrement local est conservé et sera retenté au prochain accès.
    }
  }

  Future<void> _saveLocal() =>
      _storageService.saveList(_prefsKey, state.toList());

  Future<void> _queueCloudSave(String userId, Set<String> favoriteIds) {
    final snapshot = Set<String>.from(favoriteIds);
    _cloudWriteQueue = _cloudWriteQueue
        .catchError((_) {})
        .then((_) => _syncService.saveFavorites(userId, snapshot));
    return _cloudWriteQueue;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
