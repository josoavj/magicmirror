import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';
import 'package:magicmirror/features/weather/data/services/weather_service.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../presentation/widgets/glass_container.dart';

final agendaEventsForDayProvider =
    FutureProvider.family<List<AgendaEvent>, DateTime>((ref, day) async {
      final service = ref.watch(agendaSupabaseServiceProvider);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      try {
        return await service.fetchEventsForDay(normalizedDay);
      } catch (_) {
        // Ne bloque pas les suggestions si le planning cloud est indisponible.
        return const <AgendaEvent>[];
      }
    });

final outfitWeatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final outfitWeatherBundleProvider = FutureProvider<_OutfitWeatherBundle>((
  ref,
) async {
  final weatherService = ref.watch(outfitWeatherServiceProvider);

  final currentWeather = await weatherService.getCurrentWeather();

  ForecastItem? tomorrowForecast;
  final coords = await _resolveForecastCoordinates();
  final forecast = await weatherService.getForecast(coords.lat, coords.lon);
  if (forecast != null) {
    tomorrowForecast = _pickTomorrowForecast(forecast.forecasts);
  }

  return _OutfitWeatherBundle(
    currentWeather: currentWeather,
    tomorrowForecast: tomorrowForecast,
  );
});

final outfitSecondaryLlmDetailsProvider =
    FutureProvider<Map<String, _OutfitLlmDetails>>((ref) async {
      if (!AppConfig.enableSecondaryLlmRanking) {
        return const <String, _OutfitLlmDetails>{};
      }

      SupabaseClient client;
      try {
        client = Supabase.instance.client;
      } catch (_) {
        return const <String, _OutfitLlmDetails>{};
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        return const <String, _OutfitLlmDetails>{};
      }
      final profile = ref.watch(userProfileProvider);
      final useProfileContext = ref.watch(outfitLlamaUseProfileContextProvider);
      final strictGenderFilter = ref.watch(
        outfitLlamaStrictGenderFilterProvider,
      );

      Future<List<dynamic>> fetchRowsWithModel() {
        return client
            .from('outfit_llm_details')
            .select(
              'outfit_id,top_item,bottom_item,shoes_item,outerwear_item,accessories,type_label,summary,model_tag,target_gender,target_styles,target_morphology,profile_payload',
            )
            .eq('user_id', userId)
            .eq('model_tag', AppConfig.secondaryLlmModelTag);
      }

      Future<List<dynamic>> fetchRowsWithoutModel() {
        return client
            .from('outfit_llm_details')
            .select(
              'outfit_id,top_item,bottom_item,shoes_item,outerwear_item,accessories,type_label,summary',
            )
            .eq('user_id', userId);
      }

      try {
        List<dynamic> rows;
        try {
          rows = await fetchRowsWithModel();
        } on PostgrestException catch (error) {
          if (error.code == '42703') {
            rows = await fetchRowsWithoutModel();
          } else {
            rethrow;
          }
        }

        final detailsByOutfitId = <String, _OutfitLlmDetails>{};
        for (final row in rows) {
          if (row is! Map<String, dynamic>) {
            continue;
          }
          final outfitId = row['outfit_id']?.toString();
          if (outfitId == null || outfitId.isEmpty) {
            continue;
          }
          if (!_llamaRowMatchesProfile(
            row,
            profile: profile,
            useProfileContext: useProfileContext,
            strictGenderFilter: strictGenderFilter,
          )) {
            continue;
          }

          final details = _OutfitLlmDetails(
            top: row['top_item']?.toString(),
            bottom: row['bottom_item']?.toString(),
            shoes: row['shoes_item']?.toString(),
            outerwear: row['outerwear_item']?.toString(),
            accessories: _parseAccessories(row['accessories']),
            typeLabel: row['type_label']?.toString(),
            summary: row['summary']?.toString(),
          );

          if (details.hasAnyDetail) {
            detailsByOutfitId[outfitId] = details;
          }
        }

        return detailsByOutfitId;
      } on PostgrestException catch (error) {
        if (error.code == '42P01') {
          return const <String, _OutfitLlmDetails>{};
        }
        rethrow;
      } catch (_) {
        return const <String, _OutfitLlmDetails>{};
      }
    });

List<String> _parseAccessories(dynamic raw) {
  if (raw == null) {
    return const <String>[];
  }
  if (raw is List) {
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final value = raw.toString().trim();
  if (value.isEmpty) {
    return const <String>[];
  }

  final splitter = value.contains('|') ? '|' : ',';
  return value
      .split(splitter)
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

bool _llamaRowMatchesProfile(
  Map<String, dynamic> row, {
  required UserProfile profile,
  required bool useProfileContext,
  required bool strictGenderFilter,
}) {
  if (!useProfileContext) {
    return true;
  }

  final payload = row['profile_payload'];
  final payloadMap = payload is Map<String, dynamic>
      ? payload
      : <String, dynamic>{};

  final rowGenderRaw =
      row['target_gender'] ??
      row['gender_target'] ??
      row['profile_gender'] ??
      payloadMap['gender'];
  final rowGender = rowGenderRaw?.toString().trim() ?? '';
  if (strictGenderFilter && rowGender.isNotEmpty) {
    if (!_genderMatchesProfile(rowGender, profile.gender)) {
      return false;
    }
  }

  final rowStyles = _toNormalizedStringSet(
    row['target_styles'] ??
        payloadMap['preferredStyles'] ??
        payloadMap['styles'],
  );
  final profileStyles = _toNormalizedStringSet(profile.preferredStyles);
  if (rowStyles.isNotEmpty && profileStyles.isNotEmpty) {
    final overlap = rowStyles.any(profileStyles.contains);
    if (!overlap) {
      return false;
    }
  }

  final rowMorphologyRaw = row['target_morphology'] ?? payloadMap['morphology'];
  final rowMorphology = rowMorphologyRaw?.toString().trim() ?? '';
  if (rowMorphology.isNotEmpty &&
      !_normalizeToken(
        rowMorphology,
      ).contains(_normalizeToken(profile.morphology)) &&
      !_normalizeToken(
        profile.morphology,
      ).contains(_normalizeToken(rowMorphology))) {
    return false;
  }

  return true;
}

bool _genderMatchesProfile(String targetGender, String profileGender) {
  final target = _normalizeToken(targetGender);
  final profile = _normalizeToken(profileGender);

  if (target.isEmpty ||
      target == 'all' ||
      target == 'any' ||
      target == 'unisex') {
    return true;
  }
  if (target.contains('nonprecise') || target.contains('nonbinaire')) {
    return true;
  }
  if (target.contains('femme') || target.contains('female') || target == 'f') {
    return profile.contains('femme') ||
        profile.contains('female') ||
        profile == 'f';
  }
  if (target.contains('homme') || target.contains('male') || target == 'm') {
    return profile.contains('homme') ||
        profile.contains('male') ||
        profile == 'm';
  }
  return true;
}

Set<String> _toNormalizedStringSet(dynamic raw) {
  if (raw == null) {
    return <String>{};
  }

  if (raw is List) {
    return raw
        .map((item) => _normalizeToken(item.toString()))
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  final value = raw.toString().trim();
  if (value.isEmpty) {
    return <String>{};
  }

  final splitter = value.contains('|')
      ? '|'
      : (value.contains(',') ? ',' : ' ');
  return value
      .split(splitter)
      .map(_normalizeToken)
      .where((item) => item.isNotEmpty)
      .toSet();
}

String _normalizeToken(String value) {
  final lowered = value.toLowerCase();
  const diacriticsMap = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'æ': 'ae',
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
    'œ': 'oe',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ß': 'ss',
  };

  final folded = StringBuffer();
  for (final rune in lowered.runes) {
    final char = String.fromCharCode(rune);
    folded.write(diacriticsMap[char] ?? char);
  }

  return folded.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

final outfitFavoritesProvider =
    StateNotifierProvider<OutfitFavoritesNotifier, Set<String>>((ref) {
      return OutfitFavoritesNotifier(ref);
    });

final outfitPersonalizationProvider =
    StateNotifierProvider<
      OutfitPersonalizationNotifier,
      OutfitPersonalizationState
    >((ref) {
      return OutfitPersonalizationNotifier();
    });

class OutfitPersonalizationState {
  final Map<String, int> styleBiasByStyle;
  final Map<String, int> outfitBiasById;
  final Map<String, int> lastSeenAtMsByOutfitId;

  const OutfitPersonalizationState({
    required this.styleBiasByStyle,
    required this.outfitBiasById,
    required this.lastSeenAtMsByOutfitId,
  });

  const OutfitPersonalizationState.initial()
    : styleBiasByStyle = const <String, int>{},
      outfitBiasById = const <String, int>{},
      lastSeenAtMsByOutfitId = const <String, int>{};

  OutfitPersonalizationState copyWith({
    Map<String, int>? styleBiasByStyle,
    Map<String, int>? outfitBiasById,
    Map<String, int>? lastSeenAtMsByOutfitId,
  }) {
    return OutfitPersonalizationState(
      styleBiasByStyle: styleBiasByStyle ?? this.styleBiasByStyle,
      outfitBiasById: outfitBiasById ?? this.outfitBiasById,
      lastSeenAtMsByOutfitId:
          lastSeenAtMsByOutfitId ?? this.lastSeenAtMsByOutfitId,
    );
  }
}

class OutfitPersonalizationNotifier
    extends StateNotifier<OutfitPersonalizationState> {
  OutfitPersonalizationNotifier()
    : super(const OutfitPersonalizationState.initial()) {
    Future.microtask(_load);
  }

  static const _prefsKey = 'outfit.personalization.v1';
  Future<void> _saveChain = Future<void>.value();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      Map<String, int> parseIntMap(Object? input) {
        if (input is! Map) {
          return <String, int>{};
        }
        final parsed = <String, int>{};
        input.forEach((key, value) {
          final k = key.toString();
          final v = int.tryParse(value.toString());
          if (v != null) {
            parsed[k] = v;
          }
        });
        return parsed;
      }

      state = OutfitPersonalizationState(
        styleBiasByStyle: parseIntMap(decoded['styleBiasByStyle']),
        outfitBiasById: parseIntMap(decoded['outfitBiasById']),
        lastSeenAtMsByOutfitId: parseIntMap(decoded['lastSeenAtMsByOutfitId']),
      );
    } catch (_) {
      // Ignore corrupted local personalization cache.
    }
  }

  Future<void> _persistSnapshot(OutfitPersonalizationState snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode({
      'styleBiasByStyle': snapshot.styleBiasByStyle,
      'outfitBiasById': snapshot.outfitBiasById,
      'lastSeenAtMsByOutfitId': snapshot.lastSeenAtMsByOutfitId,
    });
    await prefs.setString(_prefsKey, raw);
  }

  Future<void> _save() {
    final snapshot = state;
    _saveChain = _saveChain
        .catchError((_) {
          // Keep chain alive even if a previous save failed.
        })
        .then((_) => _persistSnapshot(snapshot));
    return _saveChain;
  }

  Future<void> recordFeedback({
    required String outfitId,
    required List<String> styles,
    required bool positive,
  }) async {
    final deltaOutfit = positive ? 10 : -10;
    final deltaStyle = positive ? 6 : -6;

    final nextOutfitBias = Map<String, int>.from(state.outfitBiasById);
    final currentOutfit = nextOutfitBias[outfitId] ?? 0;
    nextOutfitBias[outfitId] = (currentOutfit + deltaOutfit).clamp(-40, 40);

    final nextStyleBias = Map<String, int>.from(state.styleBiasByStyle);
    for (final style in styles) {
      final key = style.toLowerCase();
      final current = nextStyleBias[key] ?? 0;
      nextStyleBias[key] = (current + deltaStyle).clamp(-30, 30);
    }

    state = state.copyWith(
      outfitBiasById: nextOutfitBias,
      styleBiasByStyle: nextStyleBias,
    );
    await _save();
  }

  Future<void> markOutfitSeen(String outfitId) async {
    final nextSeen = Map<String, int>.from(state.lastSeenAtMsByOutfitId);
    nextSeen[outfitId] = DateTime.now().millisecondsSinceEpoch;

    final cutoff = DateTime.now()
        .subtract(const Duration(days: 14))
        .millisecondsSinceEpoch;
    nextSeen.removeWhere((_, timestamp) => timestamp < cutoff);

    state = state.copyWith(lastSeenAtMsByOutfitId: nextSeen);
    await _save();
  }
}

class OutfitFavoritesNotifier extends StateNotifier<Set<String>> {
  OutfitFavoritesNotifier(this._ref) : super(<String>{}) {
    _attachAuthListener();
    // Defer initial load to avoid mutating other providers during build.
    Future.microtask(_load);
  }

  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;

  static const _prefsKey = 'outfit.favorite.ids';

  bool _isUndefinedColumnError(Object error) {
    if (error is PostgrestException && error.code == '42703') {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('42703') && message.contains('column');
  }

  String _syncErrorMessage(String operation, Object error) {
    if (_isUndefinedColumnError(error)) {
      return 'Schema Supabase incomplet (42703): ajoutez favorite_outfit_ids dans profiles.';
    }
    return '$operation: ${error.toString()}';
  }

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocal(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }

  void _attachAuthListener() {
    final client = _client;
    if (client == null) {
      return;
    }
    _authSubscription = client.auth.onAuthStateChange.listen((event) {
      final userId = event.session?.user.id;
      if (userId != null && userId.isNotEmpty) {
        unawaited(_retryCloudSync());
      }
    });
  }

  Future<Set<String>?> _loadFromSupabase() async {
    final client = _client;
    if (client == null) {
      return null;
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    try {
      final data = await client
          .from('profiles')
          .select('favorite_outfit_ids')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null || data['favorite_outfit_ids'] == null) {
        return <String>{};
      }

      final raw = data['favorite_outfit_ids'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toSet();
      }
      return <String>{};
    } catch (error) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          _syncErrorMessage('Lecture cloud impossible', error);
      return null;
    }
  }

  Future<bool> _saveToSupabase(Set<String> ids) async {
    final client = _client;
    if (client == null) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Supabase indisponible sur cet écran';
      return false;
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Connexion requise pour synchroniser les favoris';
      return false;
    }

    try {
      await client
          .from('profiles')
          .upsert({
            'user_id': userId,
            'favorite_outfit_ids': ids.toList(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id')
          .select('user_id')
          .maybeSingle();
      return true;
    } catch (error) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          _syncErrorMessage('Sync cloud échouée', error);
      return false;
    }
  }

  Future<void> _retryCloudSync() async {
    final localIds = Set<String>.from(state);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
        OutfitFavoritesSyncStatus.syncing;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
        'Nouvelle tentative de synchronisation cloud...';

    final remoteIds = await _loadFromSupabase();
    if (remoteIds == null) {
      _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
          OutfitFavoritesSyncStatus.localOnly;
      return;
    }

    final merged = <String>{...localIds, ...remoteIds};
    state = merged;
    await _saveLocal(merged);

    final pushed = await _saveToSupabase(merged);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state = pushed
        ? OutfitFavoritesSyncStatus.synced
        : OutfitFavoritesSyncStatus.localOnly;
    if (pushed) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Favoris synchronisés avec le cloud';
    }
  }

  Future<void> _load() async {
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
        OutfitFavoritesSyncStatus.syncing;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
        'Synchronisation des favoris...';

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? const <String>[];
    final localIds = ids.toSet();
    state = localIds;

    final remoteIds = await _loadFromSupabase();
    if (remoteIds == null) {
      _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
          OutfitFavoritesSyncStatus.localOnly;
      if (_ref.read(outfitFavoritesSyncMessageProvider) ==
          'Synchronisation des favoris...') {
        _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
            'Mode local (cloud indisponible)';
      }
      return;
    }

    if (remoteIds.isNotEmpty || localIds.isEmpty) {
      state = remoteIds;
      await _saveLocal(remoteIds);
      _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
          OutfitFavoritesSyncStatus.synced;
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Favoris synchronisés avec le cloud';
      return;
    }

    // Si le cloud est vide mais local non vide, on pousse local vers Supabase.
    final pushed = await _saveToSupabase(localIds);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state = pushed
        ? OutfitFavoritesSyncStatus.synced
        : OutfitFavoritesSyncStatus.localOnly;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state = pushed
        ? 'Favoris synchronisés avec le cloud'
        : 'Mode local (sync cloud échouée)';
  }

  Future<void> toggleFavorite(String outfitId) async {
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
        OutfitFavoritesSyncStatus.syncing;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
        'Mise à jour des favoris...';

    final next = Set<String>.from(state);
    if (next.contains(outfitId)) {
      next.remove(outfitId);
    } else {
      next.add(outfitId);
    }
    state = next;
    await _saveLocal(next);
    final synced = await _saveToSupabase(next);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state = synced
        ? OutfitFavoritesSyncStatus.synced
        : OutfitFavoritesSyncStatus.localOnly;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state = synced
        ? 'Favoris synchronisés avec le cloud'
        : 'Mode local (sync cloud échouée)';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class OutfitSuggestionScreen extends ConsumerWidget {
  const OutfitSuggestionScreen({super.key, this.initialShowFavorites = false});

  final bool initialShowFavorites;

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  Set<String> _computeDisplayedOutfitIds({
    required UserProfile profile,
    required List<AgendaEvent> events,
    required Set<String> favoriteIds,
    required bool showOnlyFavorites,
    required bool secondaryLlmEnabled,
    required OutfitPersonalizationState personalization,
    required Map<String, double> mlScoreMap,
    required Map<String, _OutfitLlmDetails> llmDetailsByOutfitId,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost,
    required DateTime referenceNow,
  }) {
    final targetDay = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );
    final ranked = _rankOutfits(
      profile,
      events,
      favoriteIds: favoriteIds,
      personalization: personalization,
      mlScoreMap: mlScoreMap,
      llmDetailsByOutfitId: llmDetailsByOutfitId,
      secondaryLlmEnabled: secondaryLlmEnabled,
      targetDay: targetDay,
      weatherContext: weatherContext,
      strictWeatherMode: strictWeatherMode,
      creativeMixEnabled: creativeMixEnabled,
      creativeExplorationShare: creativeExplorationShare,
      creativeBoost: creativeBoost,
      excludedOutfitIds: const <String>{},
      referenceNow: referenceNow,
    );

    final visible = showOnlyFavorites
        ? ranked.where((item) => favoriteIds.contains(item.outfit.id)).toList()
        : ranked;

    return visible.map((item) => item.outfit.id).toSet();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final isFavoritesMode = initialShowFavorites;
    final profile = ref.watch(userProfileProvider);
    final favoriteIds = ref.watch(outfitFavoritesProvider);
    final personalization = ref.watch(outfitPersonalizationProvider);
    final strictWeatherMode = ref.watch(outfitStrictWeatherModeProvider);
    final creativeMixEnabled = ref.watch(outfitCreativeMixEnabledProvider);
    final creativeExplorationShare = ref.watch(
      outfitCreativeExplorationShareProvider,
    );
    final creativeBoost = ref.watch(outfitCreativeBoostProvider);
    final secondaryLlmEnabled = ref.watch(outfitSecondaryLlmEnabledProvider);
    final secondaryLlmWeight = ref.watch(outfitSecondaryLlmWeightProvider);
    final mlScoreMapAsync = ref.watch(outfitMlScoreMapProvider);
    final secondaryLlmScoreMapAsync = ref.watch(
      outfitSecondaryLlmScoreMapProvider,
    );
    final secondaryLlmDetailsAsync = ref.watch(
      outfitSecondaryLlmDetailsProvider,
    );
    final mlScoreMap = mlScoreMapAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String, double>{},
    );
    final secondaryLlmScoreMap = secondaryLlmScoreMapAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String, double>{},
    );
    final effectiveMlScoreMap = _mergeModelScores(
      primaryScores: mlScoreMap,
      secondaryScores: secondaryLlmScoreMap,
      enableSecondary: secondaryLlmEnabled,
      secondaryWeight: secondaryLlmWeight,
    );
    final secondaryLlmDetailsByOutfitId = secondaryLlmDetailsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String, _OutfitLlmDetails>{},
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayEventsAsync = ref.watch(agendaEventsForDayProvider(today));
    final tomorrowEventsAsync = ref.watch(agendaEventsForDayProvider(tomorrow));
    final weatherBundleAsync = ref.watch(outfitWeatherBundleProvider);

    final todayEvents = todayEventsAsync.maybeWhen(
      data: (events) => events,
      orElse: () => const <AgendaEvent>[],
    );
    final tomorrowEvents = tomorrowEventsAsync.maybeWhen(
      data: (events) => events,
      orElse: () => const <AgendaEvent>[],
    );
    final todayWeatherContext = weatherBundleAsync.maybeWhen(
      data: (bundle) => _weatherContextFromCurrent(bundle.currentWeather),
      orElse: () => null,
    );
    final todayDisplayedOutfitIds = _computeDisplayedOutfitIds(
      profile: profile,
      events: todayEvents,
      favoriteIds: favoriteIds,
      showOnlyFavorites: initialShowFavorites,
      secondaryLlmEnabled: secondaryLlmEnabled,
      personalization: personalization,
      mlScoreMap: effectiveMlScoreMap,
      llmDetailsByOutfitId: secondaryLlmDetailsByOutfitId,
      weatherContext: todayWeatherContext,
      strictWeatherMode: strictWeatherMode,
      creativeMixEnabled: creativeMixEnabled,
      creativeExplorationShare: creativeExplorationShare,
      creativeBoost: creativeBoost,
      referenceNow: now,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'Outfit Suggestions' : 'Suggestions de Tenue'),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        isFavoritesMode
                            ? (isEnglish ? 'My Favorites' : 'Mes Favoris')
                            : (isEnglish
                                  ? 'Recommendations'
                                  : 'Recommandations'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFavoritesMode
                            ? (isEnglish
                                  ? 'Cloud collection of your saved outfits'
                                  : 'Collection cloud de vos tenues enregistrées')
                            : (isEnglish
                                  ? 'Personalized suggestions based on your preferences'
                                  : 'Suggestions personnalisées basées sur vos préférences'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (isFavoritesMode) ...[
                        _buildFavoritesModeHeader(favoriteIds.length),
                        const SizedBox(height: 16),
                      ],

                      if (!isFavoritesMode) ...[
                        _buildProfileContext(
                          context,
                          profile,
                          todayEvents: todayEvents,
                          tomorrowEvents: tomorrowEvents,
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildSuggestionSection(
                        ref: ref,
                        context: context,
                        title: isFavoritesMode
                            ? _tr(
                                context,
                                'Favoris disponibles aujourd\'hui',
                                'Available favorites today',
                              )
                            : _tr(
                                context,
                                'Suggestion pour aujourd\'hui',
                                'Suggestion for today',
                              ),
                        targetDay: today,
                        profile: profile,
                        favoriteIds: favoriteIds,
                        showOnlyFavorites: initialShowFavorites,
                        secondaryLlmEnabled: secondaryLlmEnabled,
                        personalization: personalization,
                        mlScoreMap: effectiveMlScoreMap,
                        llmDetailsByOutfitId: secondaryLlmDetailsByOutfitId,
                        eventsAsync: todayEventsAsync,
                        weatherContext: weatherBundleAsync.maybeWhen(
                          data: (bundle) =>
                              _weatherContextFromCurrent(bundle.currentWeather),
                          orElse: () => null,
                        ),
                        strictWeatherMode: strictWeatherMode,
                        creativeMixEnabled: creativeMixEnabled,
                        creativeExplorationShare: creativeExplorationShare,
                        creativeBoost: creativeBoost,
                        excludedOutfitIds: const <String>{},
                        referenceNow: now,
                      ),

                      const SizedBox(height: 16),

                      _buildSuggestionSection(
                        ref: ref,
                        context: context,
                        title: isFavoritesMode
                            ? _tr(
                                context,
                                'Favoris disponibles demain',
                                'Available favorites tomorrow',
                              )
                            : _tr(
                                context,
                                'Suggestion pour demain',
                                'Suggestion for tomorrow',
                              ),
                        targetDay: tomorrow,
                        profile: profile,
                        favoriteIds: favoriteIds,
                        showOnlyFavorites: initialShowFavorites,
                        secondaryLlmEnabled: secondaryLlmEnabled,
                        personalization: personalization,
                        mlScoreMap: effectiveMlScoreMap,
                        llmDetailsByOutfitId: secondaryLlmDetailsByOutfitId,
                        eventsAsync: tomorrowEventsAsync,
                        weatherContext: weatherBundleAsync.maybeWhen(
                          data: (bundle) => _weatherContextFromForecast(
                            bundle.tomorrowForecast,
                          ),
                          orElse: () => null,
                        ),
                        strictWeatherMode: strictWeatherMode,
                        creativeMixEnabled: creativeMixEnabled,
                        creativeExplorationShare: creativeExplorationShare,
                        creativeBoost: creativeBoost,
                        excludedOutfitIds: todayDisplayedOutfitIds,
                        referenceNow: DateTime(
                          tomorrow.year,
                          tomorrow.month,
                          tomorrow.day,
                          8,
                        ),
                      ),

                      if (!isFavoritesMode) ...[
                        const SizedBox(height: 24),
                        _buildWeatherSection(weatherBundleAsync),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContext(
    BuildContext context,
    UserProfile profile, {
    required List<AgendaEvent> todayEvents,
    required List<AgendaEvent> tomorrowEvents,
  }) {
    final now = DateTime.now();
    final dayLabel = _weekdayLabelLocalized(now.weekday, context);
    final tomorrow = now.add(const Duration(days: 1));
    final prioritySlotToday = _resolvePrioritySlot(todayEvents, now);
    final prioritySlotTomorrow = _resolvePrioritySlot(
      tomorrowEvents,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8),
    );

    return SizedBox(
      width: double.infinity,
      child: GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(context, 'Profil appliqué', 'Applied profile'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${profile.gender}, ${profile.age} ${_tr(context, 'ans', 'years')}, ${profile.heightCm} cm, ${profile.morphology}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr(context, 'Styles preferes', 'Preferred styles')}: ${profile.preferredStyles.join(', ')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr(context, 'Jour', 'Day')}: $dayLabel - ${_tr(context, 'Planning du jour', 'Today agenda')}: ${todayEvents.length} ${_tr(context, 'evenement(s)', 'event(s)')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr(context, 'Aujourd\'hui', 'Today')}: ${_slotLabelLocalized(prioritySlotToday, context)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_tr(context, 'Demain', 'Tomorrow')}: ${tomorrowEvents.length} ${_tr(context, 'evenement(s)', 'event(s)')} - ${_slotLabelLocalized(prioritySlotTomorrow, context)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection({
    required WidgetRef ref,
    required BuildContext context,
    required String title,
    required DateTime targetDay,
    required UserProfile profile,
    required Set<String> favoriteIds,
    required bool showOnlyFavorites,
    required bool secondaryLlmEnabled,
    required OutfitPersonalizationState personalization,
    required Map<String, double> mlScoreMap,
    required Map<String, _OutfitLlmDetails> llmDetailsByOutfitId,
    required AsyncValue<List<AgendaEvent>> eventsAsync,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost,
    required Set<String> excludedOutfitIds,
    required DateTime referenceNow,
  }) {
    return eventsAsync.when(
      data: (events) {
        final cards = _buildOutfitCards(
          ref,
          context,
          profile,
          events,
          targetDay: targetDay,
          favoriteIds: favoriteIds,
          showOnlyFavorites: showOnlyFavorites,
          secondaryLlmEnabled: secondaryLlmEnabled,
          personalization: personalization,
          mlScoreMap: mlScoreMap,
          llmDetailsByOutfitId: llmDetailsByOutfitId,
          weatherContext: weatherContext,
          strictWeatherMode: strictWeatherMode,
          creativeMixEnabled: creativeMixEnabled,
          creativeExplorationShare: creativeExplorationShare,
          creativeBoost: creativeBoost,
          excludedOutfitIds: excludedOutfitIds,
          referenceNow: referenceNow,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (weatherContext != null) ...[
              Text(
                '${_tr(context, 'Météo', 'Weather')}: ${weatherContext.label}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...cards,
          ],
        );
      },
      loading: () => GlassContainer(
        borderRadius: 16,
        blur: 20,
        opacity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tr(
                  context,
                  'Chargement des suggestions...',
                  'Loading suggestions...',
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => GlassContainer(
        borderRadius: 16,
        blur: 20,
        opacity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Text(
          _tr(
            context,
            'Impossible de charger le planning pour cette suggestion.',
            'Unable to load schedule for this suggestion.',
          ),
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  List<Widget> _buildOutfitCards(
    WidgetRef ref,
    BuildContext context,
    UserProfile profile,
    List<AgendaEvent> events, {
    required DateTime targetDay,
    required Set<String> favoriteIds,
    required bool showOnlyFavorites,
    required bool secondaryLlmEnabled,
    required OutfitPersonalizationState personalization,
    required Map<String, double> mlScoreMap,
    required Map<String, _OutfitLlmDetails> llmDetailsByOutfitId,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost,
    required Set<String> excludedOutfitIds,
    required DateTime referenceNow,
  }) {
    final ranked = _rankOutfits(
      profile,
      events,
      favoriteIds: favoriteIds,
      personalization: personalization,
      mlScoreMap: mlScoreMap,
      llmDetailsByOutfitId: llmDetailsByOutfitId,
      secondaryLlmEnabled: secondaryLlmEnabled,
      targetDay: targetDay,
      weatherContext: weatherContext,
      strictWeatherMode: strictWeatherMode,
      creativeMixEnabled: creativeMixEnabled,
      creativeExplorationShare: creativeExplorationShare,
      creativeBoost: creativeBoost,
      excludedOutfitIds: excludedOutfitIds,
      referenceNow: referenceNow,
    );
    final visible = showOnlyFavorites
        ? ranked.where((item) => favoriteIds.contains(item.outfit.id)).toList()
        : ranked;

    if (visible.isEmpty) {
      return [
        GlassContainer(
          borderRadius: 16,
          blur: 20,
          opacity: 0.1,
          padding: const EdgeInsets.all(14),
          child: Text(
            showOnlyFavorites
                ? _tr(
                    context,
                    'Aucune tenue en favoris pour cette section.',
                    'No favorite outfit available for this section.',
                  )
                : _tr(
                    context,
                    'Aucune suggestion disponible.',
                    'No suggestion available.',
                  ),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ];
    }

    return visible
        .map(
          (item) => _buildOutfitCard(
            ref,
            context,
            item,
            isFavorite: favoriteIds.contains(item.outfit.id),
          ),
        )
        .toList();
  }

  List<_RankedOutfit> _rankOutfits(
    UserProfile profile,
    List<AgendaEvent> events, {
    required Set<String> favoriteIds,
    required OutfitPersonalizationState personalization,
    required Map<String, double> mlScoreMap,
    required Map<String, _OutfitLlmDetails> llmDetailsByOutfitId,
    required bool secondaryLlmEnabled,
    required DateTime targetDay,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost,
    required Set<String> excludedOutfitIds,
    required DateTime referenceNow,
  }) {
    final baseOutfits = [
      _Outfit(
        id: 'casual_moderne',
        title: 'Casual Moderne',
        description: 'Jeans + T-shirt léger',
        topPiece: 'T-shirt léger uni',
        bottomPiece: 'Jeans coupe droite',
        shoesPiece: 'Sneakers blanches',
        layerPiece: 'Surchemise légère',
        accessoryPieces: const ['Montre minimaliste'],
        outfitType: 'Casual quotidien',
        icon: Icons.checkroom,
        color: const Color(0xFF3B82F6),
        styles: const ['casual', 'minimaliste'],
        compatibleMorphologies: const [
          'Silhouette droite',
          'Hanches et épaules équilibrées',
        ],
        genderTargets: const ['all'],
        minAge: 16,
        maxAge: 60,
      ),
      _Outfit(
        id: 'elegant',
        title: 'Élégant',
        description: 'Chemise + Pantalon chino',
        topPiece: 'Chemise structurée',
        bottomPiece: 'Pantalon chino fuselé',
        shoesPiece: 'Derbies en cuir',
        layerPiece: 'Blazer léger',
        accessoryPieces: const ['Ceinture cuir'],
        outfitType: 'Smart élégant',
        icon: Icons.style,
        color: const Color(0xFF8B5CF6),
        styles: const ['elegant', 'business'],
        compatibleMorphologies: const [
          'Hanches et épaules équilibrées',
          'Épaules plus larges',
        ],
        genderTargets: const ['all'],
        minAge: 20,
        maxAge: 65,
      ),
      _Outfit(
        id: 'sport',
        title: 'Sport',
        description: 'Legging + Hoodie',
        topPiece: 'Hoodie respirant',
        bottomPiece: 'Legging technique',
        shoesPiece: 'Running trainers',
        layerPiece: 'Coupe-vent fin',
        accessoryPieces: const ['Casquette'],
        outfitType: 'Sport actif',
        icon: Icons.sports,
        color: const Color(0xFF10B981),
        styles: const ['sport'],
        compatibleMorphologies: const [
          'Hanches plus marquées',
          'Taille très marquée',
          'Silhouette droite',
        ],
        genderTargets: const ['all'],
        minAge: 12,
        maxAge: 50,
      ),
      _Outfit(
        id: 'street_dynamics',
        title: 'Street Dynamics',
        description: 'Cargo + bomber oversize',
        topPiece: 'T-shirt graphique',
        bottomPiece: 'Cargo ample',
        shoesPiece: 'Sneakers chunky',
        layerPiece: 'Bomber oversize',
        accessoryPieces: const ['Chaîne discrète'],
        outfitType: 'Streetwear urbain',
        icon: Icons.local_fire_department,
        color: const Color(0xFFEC4899),
        styles: const ['streetwear', 'casual'],
        compatibleMorphologies: const [
          'Épaules très marquées',
          'Silhouette droite',
        ],
        genderTargets: const ['all'],
        minAge: 14,
        maxAge: 40,
      ),
      _Outfit(
        id: 'business_smart',
        title: 'Business Smart',
        description: 'Blazer + pantalon taille haute',
        topPiece: 'Top soyeux sobre',
        bottomPiece: 'Pantalon taille haute',
        shoesPiece: 'Mocassins premium',
        layerPiece: 'Blazer structuré',
        accessoryPieces: const ['Sac structuré'],
        outfitType: 'Business smart',
        icon: Icons.business_center,
        color: const Color(0xFFF59E0B),
        styles: const ['business', 'elegant'],
        compatibleMorphologies: const [
          'Hanches très marquées',
          'Hanches et épaules équilibrées',
          'Épaules plus larges',
        ],
        genderTargets: const ['all'],
        minAge: 24,
        maxAge: 70,
      ),
      _Outfit(
        id: 'minimal_monochrome',
        title: 'Minimal Monochrome',
        description: 'Palette neutre + coupe clean',
        topPiece: 'Pull fin monochrome',
        bottomPiece: 'Pantalon droit neutre',
        shoesPiece: 'Baskets épurées',
        layerPiece: 'Manteau droit léger',
        accessoryPieces: const ['Sac crossbody'],
        outfitType: 'Minimal contemporain',
        icon: Icons.layers,
        color: const Color(0xFF14B8A6),
        styles: const ['minimaliste', 'casual'],
        compatibleMorphologies: const ['all'],
        genderTargets: const ['all'],
        minAge: 18,
        maxAge: 80,
      ),
    ];

    final allOutfits = _applyLlmDetails(
      baseOutfits,
      llmDetailsByOutfitId,
      preferLlm: secondaryLlmEnabled,
    );

    final normalizedStyles = profile.preferredStyles
        .map(_normalizeStyle)
        .toSet();
    final normalizedGender = profile.gender.toLowerCase();
    final planningSignals = _extractPlanningSignals(events);
    final isWeekend = _isWeekend(targetDay);
    final prioritySlot = _resolvePrioritySlot(events, referenceNow);
    final primaryContext = _resolvePrimaryContext(events, referenceNow);
    final season = _seasonFromMonth(targetDay.month);
    final localHourSlot = _localHourSlotLabel(referenceNow.hour);

    var candidates = allOutfits.where((outfit) {
      final ageOk =
          profile.age >= outfit.minAge && profile.age <= outfit.maxAge;
      final morphologyOk = _isMorphologyCompatible(profile.morphology, outfit);
      return ageOk && morphologyOk;
    }).toList();

    // Hard constraints first: remove clearly unsuitable outfits for the
    // immediate context to avoid noisy recommendations.
    final strictCandidates = candidates.where((outfit) {
      return _passesHardConstraints(
        outfit: outfit,
        weatherContext: weatherContext,
        strictWeatherMode: strictWeatherMode,
        planningSignals: planningSignals,
        primaryContext: primaryContext,
      );
    }).toList();
    if (strictCandidates.isNotEmpty) {
      candidates = strictCandidates;
    }

    final contextFiltered = candidates.where((outfit) {
      return _isContextCompatible(primaryContext, outfit.styles);
    }).toList();
    if (contextFiltered.isNotEmpty) {
      candidates = contextFiltered;
    }

    if (excludedOutfitIds.isNotEmpty) {
      final noRepeatCandidates = candidates
          .where((outfit) => !excludedOutfitIds.contains(outfit.id))
          .toList();
      if (noRepeatCandidates.isNotEmpty) {
        candidates = noRepeatCandidates;
      } else {
        final noRepeatFallback = allOutfits
            .where((outfit) => !excludedOutfitIds.contains(outfit.id))
            .toList();
        if (noRepeatFallback.isNotEmpty) {
          candidates = noRepeatFallback;
        }
      }
    }

    if (candidates.isEmpty) {
      candidates = allOutfits;
    }

    final ranked = candidates.map((outfit) {
      var score = 10;
      final reasonScores = <String, int>{};
      final contextCompatible = _isContextCompatible(
        primaryContext,
        outfit.styles,
      );

      void addReason(String reason, int weight) {
        final current = reasonScores[reason] ?? 0;
        if (weight > current) {
          reasonScores[reason] = weight;
        }
      }

      if (favoriteIds.contains(outfit.id)) {
        if (contextCompatible) {
          score += 22;
          addReason('Historique favori', 80);
        } else {
          score += 8;
          addReason('Favori avec compromis contexte', 30);
        }
      }

      if (outfit.styles.any(normalizedStyles.contains)) {
        score += 44;
        addReason('Correspond a vos styles', 100);
      }

      // Bonus additionnel si le style principal utilisateur est couvert.
      if (profile.preferredStyles.isNotEmpty) {
        final topStyle = _normalizeStyle(profile.preferredStyles.first);
        if (outfit.styles.contains(topStyle)) {
          score += 18;
          addReason('Aligne avec votre style principal', 110);
        }
      }

      if (profile.age >= outfit.minAge && profile.age <= outfit.maxAge) {
        score += 24;
        addReason('Adapté à votre tranche d\'âge', 40);
      }

      if (_matchesMorphology(
        profileMorphology: profile.morphology,
        compatibleMorphologies: outfit.compatibleMorphologies,
      )) {
        score += 36;
        addReason('Compatible avec votre morphologie', 95);
      }

      final isGenderMatch =
          outfit.genderTargets.contains('all') ||
          outfit.genderTargets.any(
            (gender) => normalizedGender.contains(gender),
          );
      if (isGenderMatch) {
        score += 12;
      }

      if (contextCompatible) {
        score += 24;
        addReason('Adapté à votre contexte principal', 90);
      } else {
        score -= 12;
      }

      final planningCoherence = _planningCoherenceBoost(
        planningSignals: planningSignals,
        primaryContext: primaryContext,
        styles: outfit.styles,
      );
      if (planningCoherence > 0) {
        score += planningCoherence;
        addReason('Cohérence avec vos priorités du jour', 88);
      } else if (planningCoherence < 0) {
        score += planningCoherence;
      }

      if (isWeekend &&
          outfit.styles.any((style) {
            return style == 'casual' ||
                style == 'streetwear' ||
                style == 'sport';
          })) {
        score += 12;
        addReason('Adapté au rythme du week-end', 35);
      }

      if (!isWeekend &&
          outfit.styles.any((style) {
            return style == 'business' || style == 'elegant';
          })) {
        score += 12;
        addReason('Adapté à une journée de semaine', 35);
      }

      if (planningSignals.hasWorkEvent &&
          outfit.styles.any(
            (style) => style == 'business' || style == 'elegant',
          )) {
        score += 30;
        addReason('Compatible avec votre planning pro', 105);
      } else if (planningSignals.hasWorkEvent) {
        score -= 8;
      }

      if (planningSignals.hasSportEvent && outfit.styles.contains('sport')) {
        score += 30;
        addReason('Compatible avec vos activités sportives', 105);
      } else if (planningSignals.hasSportEvent) {
        score -= 8;
      }

      if (planningSignals.hasEveningEvent &&
          outfit.styles.any(
            (style) => style == 'elegant' || style == 'streetwear',
          )) {
        score += 16;
        addReason('Adapté à vos sorties du soir', 65);
      }

      if (planningSignals.hasCasualEvent &&
          outfit.styles.any((style) {
            return style == 'casual' ||
                style == 'streetwear' ||
                style == 'minimaliste';
          })) {
        score += 14;
        addReason('Adapté à un planning détendu', 60);
      }

      if (events.isNotEmpty &&
          planningSignals.hasOutdoorEvent &&
          outfit.styles.any((style) => style == 'sport' || style == 'casual')) {
        score += 10;
        addReason('Confortable pour des déplacements extérieurs', 55);
      }

      final slotBoost = _slotScoreBoost(prioritySlot, outfit.styles);
      if (slotBoost > 0) {
        score += slotBoost;
        addReason(
          'Optimisé pour le créneau ${_slotLabel(prioritySlot).toLowerCase()}',
          50,
        );
      }

      final weatherBoost = _weatherScoreBoost(
        weatherContext,
        outfit.styles,
        strictWeatherMode: strictWeatherMode,
      );
      if (weatherBoost > 0) {
        score += weatherBoost;
        addReason('Adapté aux conditions météo', 100);
      } else if (weatherBoost < 0) {
        score += weatherBoost;
        addReason('Compromis météo détecté', 45);
      }

      final chronoBoost = _seasonRainHourBoost(
        weather: weatherContext,
        styles: outfit.styles,
        season: season,
        localHourSlot: localHourSlot,
      );
      if (chronoBoost > 0) {
        score += chronoBoost;
        addReason('Adapté à la saison et au moment de la journée', 72);
      } else if (chronoBoost < 0) {
        score += chronoBoost;
      }

      final styleBias = _styleBiasBoost(
        styles: outfit.styles,
        styleBiasByStyle: personalization.styleBiasByStyle,
      );
      if (styleBias > 0) {
        score += styleBias;
        addReason('Affinite learnée avec vos styles', 92);
      } else if (styleBias < 0) {
        score += styleBias;
      }

      final outfitBias = personalization.outfitBiasById[outfit.id] ?? 0;
      if (outfitBias > 0) {
        score += outfitBias;
        addReason('Feedback positif precedent', 84);
      } else if (outfitBias < 0) {
        score += outfitBias;
      }

      final repetitionPenalty = _recentRepetitionPenalty(
        outfitId: outfit.id,
        lastSeenAtMsByOutfitId: personalization.lastSeenAtMsByOutfitId,
      );
      if (repetitionPenalty > 0) {
        score -= repetitionPenalty;
        addReason('Rotation anti-répétition', 52);
      }

      final freshnessBonus = _freshnessBonus(
        outfitId: outfit.id,
        lastSeenAtMsByOutfitId: personalization.lastSeenAtMsByOutfitId,
      );
      if (freshnessBonus > 0) {
        score += freshnessBonus;
        addReason('Favorise des tenues moins récentes', 58);
      }

      final dailyVarietyJitter = _dailyVarietyJitter(
        outfitId: outfit.id,
        targetDay: targetDay,
      );
      if (dailyVarietyJitter > 0) {
        score += dailyVarietyJitter;
        addReason('Rotation douce entre tenues proches', 36);
      }

      final mlScore = mlScoreMap[outfit.id];
      if (AppConfig.enableHybridMlRanking && mlScore != null) {
        final hybrid =
            ((1 - AppConfig.hybridMlWeight) * score +
                    AppConfig.hybridMlWeight * (mlScore * 100))
                .round();
        score = hybrid;
        addReason('Calibration ML hybride', 86);
      }

      if (score < 0) {
        score = 0;
      }

      final reasons = _sortedReasons(reasonScores);

      return _RankedOutfit(outfit: outfit, score: score, reasons: reasons);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    final diversePool = _selectDiverseTopOutfits(
      ranked,
      maxCount: ranked.length < 8 ? ranked.length : 8,
    );

    return _selectCreativeTopOutfits(
      diversePool,
      maxCount: 4,
      targetDay: targetDay,
      creativeMixEnabled: creativeMixEnabled,
      creativeExplorationShare: creativeExplorationShare,
      creativeBoost: creativeBoost,
    );
  }

  int _styleBiasBoost({
    required List<String> styles,
    required Map<String, int> styleBiasByStyle,
  }) {
    if (styles.isEmpty || styleBiasByStyle.isEmpty) {
      return 0;
    }
    var total = 0;
    for (final style in styles) {
      total += styleBiasByStyle[style.toLowerCase()] ?? 0;
    }
    return (total / styles.length).round();
  }

  int _recentRepetitionPenalty({
    required String outfitId,
    required Map<String, int> lastSeenAtMsByOutfitId,
  }) {
    final seenAt = lastSeenAtMsByOutfitId[outfitId];
    if (seenAt == null) {
      return 0;
    }
    final seenDate = DateTime.fromMillisecondsSinceEpoch(seenAt);
    final elapsedDays = DateTime.now().difference(seenDate).inDays;
    final cooldownDays = AppConfig.outfitRecentCooldownDays;
    final windowDays = AppConfig.outfitRecentWindowDays;

    if (elapsedDays < cooldownDays) {
      final urgency = cooldownDays - elapsedDays;
      return 22 + urgency * 8;
    }

    if (elapsedDays >= windowDays) {
      return 0;
    }

    final decay = windowDays - elapsedDays;
    return 8 + decay * 3;
  }

  int _freshnessBonus({
    required String outfitId,
    required Map<String, int> lastSeenAtMsByOutfitId,
  }) {
    final seenAt = lastSeenAtMsByOutfitId[outfitId];
    if (seenAt == null) {
      return 10;
    }

    final seenDate = DateTime.fromMillisecondsSinceEpoch(seenAt);
    final elapsedDays = DateTime.now().difference(seenDate).inDays;
    if (elapsedDays >= AppConfig.outfitRecentWindowDays) {
      return 8;
    }
    if (elapsedDays >= AppConfig.outfitRecentCooldownDays) {
      return 4;
    }
    return 0;
  }

  int _dailyVarietyJitter({
    required String outfitId,
    required DateTime targetDay,
  }) {
    final dayKey =
        targetDay.year * 10000 + targetDay.month * 100 + targetDay.day;
    final raw = _stableHash('$outfitId-$dayKey').abs();
    final max = AppConfig.outfitDailyVarietyJitterMax;
    if (max <= 0) {
      return 0;
    }
    return raw % (max + 1);
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }

  Map<String, double> _mergeModelScores({
    required Map<String, double> primaryScores,
    required Map<String, double> secondaryScores,
    required bool enableSecondary,
    required double secondaryWeight,
  }) {
    if (!enableSecondary || secondaryScores.isEmpty) {
      return primaryScores;
    }

    final safeSecondaryWeight = secondaryWeight.clamp(0.0, 0.7);
    final primaryWeight = 1 - safeSecondaryWeight;

    final merged = <String, double>{...primaryScores};
    for (final entry in secondaryScores.entries) {
      final primary = primaryScores[entry.key];
      final secondary = entry.value;
      final blended = primary == null
          ? secondary
          : (primary * primaryWeight) + (secondary * safeSecondaryWeight);
      merged[entry.key] = blended.clamp(0, 1);
    }

    return merged;
  }

  List<_RankedOutfit> _selectCreativeTopOutfits(
    List<_RankedOutfit> ranked, {
    required int maxCount,
    required DateTime targetDay,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost,
  }) {
    if (ranked.isEmpty) {
      return const <_RankedOutfit>[];
    }

    if (!creativeMixEnabled || ranked.length <= maxCount) {
      return ranked.take(maxCount).toList();
    }

    final creativeAvailable = ranked
        .where((item) => _creativePotential(item.outfit.styles) > 0)
        .length;

    var explorationTarget = 0;
    if (creativeAvailable > 0) {
      final safeShare = creativeExplorationShare.clamp(0.0, 1.0);
      final rawTarget = (maxCount * safeShare).round();
      explorationTarget = _clampInt(rawTarget, 1, maxCount - 1);
      if (explorationTarget > creativeAvailable) {
        explorationTarget = creativeAvailable;
      }
    }

    final remaining = List<_RankedOutfit>.from(ranked);
    final selected = <_RankedOutfit>[];

    while (selected.length < maxCount && remaining.isNotEmpty) {
      final selectedCreative = selected
          .where((item) => _creativePotential(item.outfit.styles) > 0)
          .length;
      final needCreative = selectedCreative < explorationTarget;

      var bestIndex = 0;
      var bestAdjustedScore = double.negativeInfinity;
      var bestCreativePotential = 0;
      var bestDiversityPenalty = 0;

      for (var i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        final creativePotential = _creativePotential(candidate.outfit.styles);
        final diversityPenalty = _diversityPenalty(
          candidate: candidate.outfit,
          selected: selected,
        );

        var adjusted = candidate.score.toDouble() - diversityPenalty;

        // Petit signal journalier pour casser les egalites de scores proches.
        adjusted +=
            _dailyVarietyJitter(
              outfitId: candidate.outfit.id,
              targetDay: targetDay,
            ) *
            0.2;

        if (needCreative) {
          adjusted += creativePotential * creativeBoost;
        } else if (creativePotential > 0 &&
            selectedCreative >= explorationTarget) {
          adjusted -= creativeBoost * 0.5;
        }

        if (adjusted > bestAdjustedScore) {
          bestAdjustedScore = adjusted;
          bestIndex = i;
          bestCreativePotential = creativePotential;
          bestDiversityPenalty = diversityPenalty;
        }
      }

      final chosen = remaining.removeAt(bestIndex);
      final adjustedReasons = <String>[...chosen.reasons];
      if (bestCreativePotential > 0 &&
          selected
                  .where((item) => _creativePotential(item.outfit.styles) > 0)
                  .length <
              explorationTarget) {
        adjustedReasons.add('Ajoute une option plus audacieuse');
      }
      if (bestDiversityPenalty > 0) {
        adjustedReasons.add('Preserve la variete globale');
      }

      final adjustedScore = bestAdjustedScore < 0
          ? 0
          : bestAdjustedScore.round();
      selected.add(
        _RankedOutfit(
          outfit: chosen.outfit,
          score: adjustedScore,
          reasons: adjustedReasons,
        ),
      );
    }

    return selected;
  }

  int _creativePotential(List<String> styles) {
    if (styles.isEmpty) {
      return 0;
    }

    var score = 0;
    for (final rawStyle in styles) {
      final style = rawStyle.toLowerCase();
      if (style == 'streetwear' || style == 'elegant') {
        score += 2;
      } else if (style == 'business' || style == 'sport') {
        score += 1;
      } else if (style == 'minimaliste' || style == 'casual') {
        score -= 1;
      }
    }

    return _clampInt(score, 0, 4);
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  List<_RankedOutfit> _selectDiverseTopOutfits(
    List<_RankedOutfit> ranked, {
    required int maxCount,
  }) {
    if (ranked.length <= maxCount) {
      return ranked;
    }

    final remaining = List<_RankedOutfit>.from(ranked);
    final selected = <_RankedOutfit>[];

    while (selected.length < maxCount && remaining.isNotEmpty) {
      var bestIndex = 0;
      var bestScore = -1;
      var bestPenalty = 0;

      for (var i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        final penalty = _diversityPenalty(
          candidate: candidate.outfit,
          selected: selected,
        );
        final adjusted = candidate.score - penalty;
        if (adjusted > bestScore) {
          bestScore = adjusted;
          bestPenalty = penalty;
          bestIndex = i;
        }
      }

      final chosen = remaining.removeAt(bestIndex);
      final adjustedScore = bestScore < 0 ? 0 : bestScore;
      final adjustedReasons = <String>[...chosen.reasons];
      if (bestPenalty > 0) {
        adjustedReasons.add('Ajoute de la variete a la selection');
      }

      selected.add(
        _RankedOutfit(
          outfit: chosen.outfit,
          score: adjustedScore,
          reasons: adjustedReasons,
        ),
      );
    }

    return selected;
  }

  int _diversityPenalty({
    required _Outfit candidate,
    required List<_RankedOutfit> selected,
  }) {
    if (selected.isEmpty) {
      return 0;
    }

    var penalty = 0;
    for (final picked in selected) {
      final sim = _styleSimilarity(candidate.styles, picked.outfit.styles);
      penalty += (sim * AppConfig.outfitDiversityPenaltyScale).round();

      final samePrimaryStyle =
          candidate.styles.isNotEmpty &&
          picked.outfit.styles.isNotEmpty &&
          candidate.styles.first == picked.outfit.styles.first;
      if (samePrimaryStyle) {
        penalty += 9;
      }
    }
    return penalty;
  }

  double _styleSimilarity(List<String> left, List<String> right) {
    final a = left.toSet();
    final b = right.toSet();
    final union = <String>{...a, ...b};
    if (union.isEmpty) {
      return 0;
    }
    final intersection = a.intersection(b);
    return intersection.length / union.length;
  }

  String _normalizeStyle(String value) {
    final v = value.toLowerCase();
    if (v.contains('eleg')) {
      return 'elegant';
    }
    if (v.contains('mini')) {
      return 'minimaliste';
    }
    return v;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lundi';
      case DateTime.tuesday:
        return 'Mardi';
      case DateTime.wednesday:
        return 'Mercredi';
      case DateTime.thursday:
        return 'Jeudi';
      case DateTime.friday:
        return 'Vendredi';
      case DateTime.saturday:
        return 'Samedi';
      case DateTime.sunday:
        return 'Dimanche';
      default:
        return 'Jour inconnu';
    }
  }

  _PlanningSignals _extractPlanningSignals(List<AgendaEvent> events) {
    var hasWorkEvent = false;
    var hasSportEvent = false;
    var hasEveningEvent = false;
    var hasCasualEvent = false;
    var hasOutdoorEvent = false;

    for (final event in events) {
      if (event.isCompleted) {
        continue;
      }

      final eventBlob =
          '${event.eventType} ${event.title} ${event.description ?? ''}'
              .toLowerCase();

      if (_containsAny(eventBlob, const [
        'work',
        'travail',
        'reunion',
        'meeting',
        'bureau',
        'rdv pro',
        'professionnel',
        'business',
      ])) {
        hasWorkEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'sport',
        'gym',
        'run',
        'course',
        'training',
        'fitness',
      ])) {
        hasSportEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'soiree',
        'soir',
        'diner',
        'resto',
        'event',
        'sortie',
      ])) {
        hasEveningEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'amis',
        'detente',
        'shopping',
        'promenade',
        'famille',
        'loisir',
        'casual',
      ])) {
        hasCasualEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'exterieur',
        'outdoor',
        'marche',
        'balade',
        'deplacement',
      ])) {
        hasOutdoorEvent = true;
      }

      if (event.startTime.hour >= 18) {
        hasEveningEvent = true;
      }
    }

    return _PlanningSignals(
      hasWorkEvent: hasWorkEvent,
      hasSportEvent: hasSportEvent,
      hasEveningEvent: hasEveningEvent,
      hasCasualEvent: hasCasualEvent,
      hasOutdoorEvent: hasOutdoorEvent,
    );
  }

  bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  _DayTimeSlot _resolvePrioritySlot(List<AgendaEvent> events, DateTime now) {
    final pending = events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final event in pending) {
      if (!event.endTime.isBefore(now)) {
        return _slotFromHour(event.startTime.hour);
      }
    }

    return _slotFromHour(now.hour);
  }

  _DayTimeSlot _slotFromHour(int hour) {
    if (hour < 12) {
      return _DayTimeSlot.morning;
    }
    if (hour < 18) {
      return _DayTimeSlot.afternoon;
    }
    return _DayTimeSlot.evening;
  }

  String _slotLabel(_DayTimeSlot slot) {
    switch (slot) {
      case _DayTimeSlot.morning:
        return 'Matin';
      case _DayTimeSlot.afternoon:
        return 'Après-midi';
      case _DayTimeSlot.evening:
        return 'Soirée';
    }
  }

  String _slotLabelLocalized(_DayTimeSlot slot, BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    switch (slot) {
      case _DayTimeSlot.morning:
        return isEnglish ? 'Morning' : 'Matin';
      case _DayTimeSlot.afternoon:
        return isEnglish ? 'Afternoon' : 'Après-midi';
      case _DayTimeSlot.evening:
        return isEnglish ? 'Evening' : 'Soirée';
    }
  }

  String _weekdayLabelLocalized(int weekday, BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (!isEnglish) {
      return _weekdayLabel(weekday);
    }
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown day';
    }
  }

  int _slotScoreBoost(_DayTimeSlot slot, List<String> styles) {
    switch (slot) {
      case _DayTimeSlot.morning:
        if (styles.any((s) => s == 'business' || s == 'minimaliste')) {
          return 14;
        }
        if (styles.any((s) => s == 'casual')) {
          return 8;
        }
        return 0;
      case _DayTimeSlot.afternoon:
        if (styles.any((s) => s == 'casual' || s == 'streetwear')) {
          return 12;
        }
        if (styles.any((s) => s == 'business' || s == 'sport')) {
          return 8;
        }
        return 0;
      case _DayTimeSlot.evening:
        if (styles.any((s) => s == 'elegant' || s == 'streetwear')) {
          return 16;
        }
        if (styles.any((s) => s == 'minimaliste')) {
          return 8;
        }
        return 0;
    }
  }

  int _planningCoherenceBoost({
    required _PlanningSignals planningSignals,
    required _PlanningContext primaryContext,
    required List<String> styles,
  }) {
    var boost = 0;

    if (primaryContext == _PlanningContext.work) {
      if (styles.any((s) => s == 'business' || s == 'elegant')) {
        boost += 8;
      } else {
        boost -= 8;
      }
    }

    if (primaryContext == _PlanningContext.sport) {
      if (styles.contains('sport')) {
        boost += 8;
      } else {
        boost -= 8;
      }
    }

    if (planningSignals.hasWorkEvent && planningSignals.hasEveningEvent) {
      // Favor versatile outfits that can transition from work to evening.
      if (styles.any((s) => s == 'elegant' || s == 'minimaliste')) {
        boost += 6;
      }
      if (styles.length == 1 && styles.contains('sport')) {
        boost -= 6;
      }
    }

    if (planningSignals.hasWorkEvent && planningSignals.hasSportEvent) {
      // Mixed day: avoid ultra-specialized outfits.
      if (styles.length == 1 &&
          (styles.contains('business') || styles.contains('sport'))) {
        boost -= 6;
      }
      if (styles.any((s) => s == 'casual' || s == 'minimaliste')) {
        boost += 4;
      }
    }

    return boost;
  }

  List<String> _sortedReasons(Map<String, int> reasonScores) {
    final entries = reasonScores.entries.toList()
      ..sort((a, b) {
        final byWeight = b.value.compareTo(a.value);
        if (byWeight != 0) {
          return byWeight;
        }
        return a.key.compareTo(b.key);
      });
    return entries.map((e) => e.key).toList();
  }

  int _weatherScoreBoost(
    _OutfitWeatherContext? weather,
    List<String> styles, {
    required bool strictWeatherMode,
  }) {
    if (weather == null) {
      return 0;
    }

    var boost = 0;
    final main = weather.main.toLowerCase();

    if (weather.temperature >= 28) {
      if (styles.any(
        (s) => s == 'casual' || s == 'minimaliste' || s == 'sport',
      )) {
        boost += 14;
      }
    }

    if (weather.temperature <= 16) {
      if (styles.any(
        (s) => s == 'business' || s == 'elegant' || s == 'minimaliste',
      )) {
        boost += 12;
      }
    }

    if (main.contains('rain') ||
        main.contains('thunder') ||
        main.contains('snow')) {
      if (styles.any(
        (s) => s == 'business' || s == 'minimaliste' || s == 'casual',
      )) {
        boost += 10;
      }
    }

    if (weather.windSpeed >= 10) {
      if (styles.any((s) => s == 'sport' || s == 'casual')) {
        boost += 6;
      }
    }

    if (strictWeatherMode) {
      if (weather.temperature >= 31 &&
          styles.contains('business') &&
          !styles.contains('casual')) {
        boost -= 14;
      }

      if (weather.temperature <= 8 &&
          styles.length == 1 &&
          styles.contains('sport')) {
        boost -= 12;
      }

      final main = weather.main.toLowerCase();
      final isRainy =
          main.contains('rain') ||
          main.contains('thunder') ||
          main.contains('snow');
      if (isRainy &&
          styles.contains('streetwear') &&
          !styles.contains('business')) {
        boost -= 12;
      }
    }

    return boost;
  }

  int _seasonRainHourBoost({
    required _OutfitWeatherContext? weather,
    required List<String> styles,
    required String season,
    required String localHourSlot,
  }) {
    var boost = 0;

    if (season == 'summer' &&
        styles.any(
          (s) => s == 'casual' || s == 'sport' || s == 'minimaliste',
        )) {
      boost += 6;
    }
    if (season == 'winter' &&
        styles.any(
          (s) => s == 'business' || s == 'elegant' || s == 'minimaliste',
        )) {
      boost += 6;
    }

    if (localHourSlot == 'morning' &&
        styles.any((s) => s == 'business' || s == 'minimaliste')) {
      boost += 4;
    }
    if (localHourSlot == 'evening' &&
        styles.any((s) => s == 'elegant' || s == 'streetwear')) {
      boost += 4;
    }

    final rainLevel = _rainLevelFromMain(weather?.main);
    if (rainLevel == 'rainy') {
      if (styles.any(
        (s) => s == 'business' || s == 'minimaliste' || s == 'casual',
      )) {
        boost += 5;
      }
      if (styles.contains('streetwear') && !styles.contains('business')) {
        boost -= 4;
      }
    }

    return boost;
  }

  String _seasonFromMonth(int month) {
    if (month == 12 || month <= 2) {
      return 'winter';
    }
    if (month >= 3 && month <= 5) {
      return 'spring';
    }
    if (month >= 6 && month <= 8) {
      return 'summer';
    }
    return 'autumn';
  }

  String _localHourSlotLabel(int hour) {
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 18) {
      return 'afternoon';
    }
    return 'evening';
  }

  String _rainLevelFromMain(String? main) {
    final normalized = (main ?? '').toLowerCase();
    if (normalized.contains('rain') ||
        normalized.contains('thunder') ||
        normalized.contains('snow')) {
      return 'rainy';
    }
    if (normalized.contains('cloud')) {
      return 'cloudy';
    }
    return 'clear';
  }

  bool _passesHardConstraints({
    required _Outfit outfit,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required _PlanningSignals planningSignals,
    required _PlanningContext primaryContext,
  }) {
    final styles = outfit.styles;

    // Work-first hard gate: if user has work context, keep at least one
    // business/elegant direction in the candidate set.
    final enforceWorkGate =
        (planningSignals.hasWorkEvent ||
            primaryContext == _PlanningContext.work) &&
        !planningSignals.hasSportEvent &&
        primaryContext != _PlanningContext.mixed;
    if (enforceWorkGate &&
        !styles.any((s) => s == 'business' || s == 'elegant')) {
      return false;
    }

    if (weatherContext == null) {
      return true;
    }

    if (!strictWeatherMode) {
      return true;
    }

    final main = weatherContext.main.toLowerCase();
    final isRainy =
        main.contains('rain') ||
        main.contains('thunder') ||
        main.contains('snow');

    // In rainy/snowy conditions, avoid highly exposed styles.
    if (isRainy &&
        styles.contains('streetwear') &&
        !styles.contains('business')) {
      return false;
    }

    // Very hot weather: avoid heavy formal-only outfits.
    if (weatherContext.temperature >= 31 &&
        styles.contains('business') &&
        !styles.contains('casual')) {
      return false;
    }

    // Very cold weather: avoid sport-only lightweight outfits.
    if (weatherContext.temperature <= 8 &&
        styles.length == 1 &&
        styles.contains('sport')) {
      return false;
    }

    return true;
  }

  bool _isMorphologyCompatible(String morphology, _Outfit outfit) {
    final normalized = morphology.trim().toLowerCase();
    if (normalized == 'silhouette non definie' ||
        normalized == 'silhouette non définie' ||
        normalized == 'non definie' ||
        normalized == 'non définie') {
      return true;
    }
    return _matchesMorphology(
      profileMorphology: morphology,
      compatibleMorphologies: outfit.compatibleMorphologies,
    );
  }

  _PlanningContext _resolvePrimaryContext(
    List<AgendaEvent> events,
    DateTime referenceNow,
  ) {
    final pending = events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final event in pending) {
      if (!event.endTime.isBefore(referenceNow)) {
        return _contextFromEvent(event);
      }
    }

    if (pending.isNotEmpty) {
      return _contextFromEvent(pending.first);
    }

    return _PlanningContext.none;
  }

  _PlanningContext _contextFromEvent(AgendaEvent event) {
    final blob = '${event.eventType} ${event.title} ${event.description ?? ''}'
        .toLowerCase();

    if (_containsAny(blob, const [
      'work',
      'travail',
      'meeting',
      'reunion',
      'business',
      'bureau',
    ])) {
      return _PlanningContext.work;
    }
    if (_containsAny(blob, const [
      'sport',
      'gym',
      'training',
      'fitness',
      'run',
      'course',
    ])) {
      return _PlanningContext.sport;
    }
    if (_containsAny(blob, const [
      'soir',
      'soiree',
      'diner',
      'event',
      'sortie',
      'resto',
    ])) {
      return _PlanningContext.evening;
    }
    if (_containsAny(blob, const [
      'detente',
      'famille',
      'amis',
      'shopping',
      'loisir',
      'promenade',
    ])) {
      return _PlanningContext.casual;
    }
    return _PlanningContext.mixed;
  }

  bool _isContextCompatible(_PlanningContext context, List<String> styles) {
    switch (context) {
      case _PlanningContext.work:
        return styles.any((s) => s == 'business' || s == 'elegant');
      case _PlanningContext.sport:
        return styles.contains('sport');
      case _PlanningContext.evening:
        return styles.any((s) => s == 'elegant' || s == 'streetwear');
      case _PlanningContext.casual:
        return styles.any(
          (s) => s == 'casual' || s == 'minimaliste' || s == 'streetwear',
        );
      case _PlanningContext.mixed:
        return styles.any(
          (s) => s == 'casual' || s == 'minimaliste' || s == 'business',
        );
      case _PlanningContext.none:
        return true;
    }
  }

  bool _matchesMorphology({
    required String profileMorphology,
    required List<String> compatibleMorphologies,
  }) {
    if (compatibleMorphologies.contains('all')) {
      return true;
    }

    final aliases = _morphologyAliases(profileMorphology);
    return compatibleMorphologies.any(aliases.contains);
  }

  Set<String> _morphologyAliases(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'Sablier (X)':
      case 'Hanches et épaules équilibrées':
      case 'Hanches et epaules equilibrees':
        return {
          'Sablier (X)',
          'Hanches et épaules équilibrées',
          'Hanches et epaules equilibrees',
        };
      case 'Poire (A)':
      case 'Hanches plus marquées':
      case 'Hanches plus marquees':
        return {'Poire (A)', 'Hanches plus marquées', 'Hanches plus marquees'};
      case 'Rectangulaire (H)':
      case 'Silhouette droite':
        return {'Rectangulaire (H)', 'Silhouette droite'};
      case 'Triangle Inverse (V)':
      case 'Épaules plus larges':
      case 'Epaules plus larges':
        return {
          'Triangle Inverse (V)',
          'Épaules plus larges',
          'Epaules plus larges',
        };
      case 'Triangle Inverse+ (V+)':
      case 'Épaules très marquées':
      case 'Epaules tres marquees':
        return {
          'Triangle Inverse+ (V+)',
          'Épaules très marquées',
          'Epaules tres marquees',
        };
      case 'Sablier+ (X+)':
      case 'Taille très marquée':
      case 'Taille tres marquee':
        return {'Sablier+ (X+)', 'Taille très marquée', 'Taille tres marquee'};
      case 'Poire+ (A+)':
      case 'Hanches très marquées':
      case 'Hanches tres marquees':
        return {
          'Poire+ (A+)',
          'Hanches très marquées',
          'Hanches tres marquees',
        };
      case 'Non définie':
      case 'Silhouette non définie':
      case 'Non definie':
      case 'Silhouette non definie':
        return {
          'Non définie',
          'Silhouette non définie',
          'Non definie',
          'Silhouette non definie',
        };
      default:
        return {normalized};
    }
  }

  Widget _buildOutfitCard(
    WidgetRef ref,
    BuildContext context,
    _RankedOutfit rankedOutfit, {
    required bool isFavorite,
  }) {
    final outfit = rankedOutfit.outfit;
    final isFeedbackSubmitting = ref.watch(outfitFeedbackSubmittingProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await ref
              .read(outfitPersonalizationProvider.notifier)
              .markOutfitSeen(rankedOutfit.outfit.id);
          await ref
              .read(outfitTelemetryProvider.notifier)
              .recordSeen(
                outfitId: rankedOutfit.outfit.id,
                metadata: {'styles': rankedOutfit.outfit.styles.join('|')},
              );
          if (!context.mounted) {
            return;
          }
          await _showOutfitDetailsSheet(
            ref,
            context,
            rankedOutfit,
            isFavorite: isFavorite,
          );
        },
        child: GlassContainer(
          borderRadius: 20,
          blur: 25,
          opacity: 0.1,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [outfit.color, outfit.color.withValues(alpha: 0.6)],
                  ),
                ),
                child: Center(
                  child: Icon(outfit.icon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outfit.quickSummary,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: rankedOutfit.reasons
                          .take(3)
                          .map(
                            (reason) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Appuyez pour voir tous les details',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorite
                        ? Colors.pinkAccent
                        : Colors.white.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${rankedOutfit.score} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: isFeedbackSubmitting
                            ? null
                            : () async {
                                await _handleOutfitFeedback(
                                  ref,
                                  context,
                                  outfit,
                                  positive: true,
                                );
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: isFeedbackSubmitting
                            ? null
                            : () async {
                                await _handleOutfitFeedback(
                                  ref,
                                  context,
                                  outfit,
                                  positive: false,
                                );
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.thumb_down_alt_outlined,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOutfitDetailsSheet(
    WidgetRef ref,
    BuildContext context,
    _RankedOutfit rankedOutfit, {
    required bool isFavorite,
  }) async {
    final outfit = rankedOutfit.outfit;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: GlassContainer(
              borderRadius: 24,
              blur: 28,
              opacity: 0.14,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              outfit.color,
                              outfit.color.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Icon(outfit.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outfit.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outfit.quickSummary,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${rankedOutfit.score} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildDetailBlock(
                          title: 'Pourquoi cette tenue ?',
                          items: rankedOutfit.reasons,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Tenue complète suggérée',
                          items: _outfitCompositionItems(outfit),
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Styles associés',
                          items: outfit.styles,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Morphologies compatibles',
                          items: outfit.compatibleMorphologies,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Tranche d\'âge cible',
                          items: ['${outfit.minAge} a ${outfit.maxAge} ans'],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(outfitPersonalizationProvider.notifier)
                            .markOutfitSeen(outfit.id);
                        await ref
                            .read(outfitTelemetryProvider.notifier)
                            .recordSeen(
                              outfitId: outfit.id,
                              metadata: {'styles': outfit.styles.join('|')},
                            );
                        await ref
                            .read(outfitFavoritesProvider.notifier)
                            .toggleFavorite(outfit.id);
                        await ref
                            .read(outfitTelemetryProvider.notifier)
                            .recordFavoriteToggle(
                              added: !isFavorite,
                              outfitId: outfit.id,
                              metadata: {'styles': outfit.styles.join('|')},
                            );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(
                        isFavorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _handleOutfitFeedback(
                              ref,
                              sheetContext,
                              outfit,
                              positive: true,
                            );
                          },
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          label: const Text('Plus comme ca'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _handleOutfitFeedback(
                              ref,
                              sheetContext,
                              outfit,
                              positive: false,
                            );
                          },
                          icon: const Icon(Icons.thumb_down_alt_outlined),
                          label: const Text('Moins comme ca'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _feedbackTagChip(
                        label: 'Trop chaud',
                        icon: Icons.wb_sunny_outlined,
                        onTap: () async {
                          await _handleOutfitFeedback(
                            ref,
                            sheetContext,
                            outfit,
                            positive: false,
                            feedbackTag: 'too_hot',
                          );
                        },
                      ),
                      _feedbackTagChip(
                        label: 'Trop froid',
                        icon: Icons.ac_unit,
                        onTap: () async {
                          await _handleOutfitFeedback(
                            ref,
                            sheetContext,
                            outfit,
                            positive: false,
                            feedbackTag: 'too_cold',
                          );
                        },
                      ),
                      _feedbackTagChip(
                        label: 'Trop formel',
                        icon: Icons.work_outline,
                        onTap: () async {
                          await _handleOutfitFeedback(
                            ref,
                            sheetContext,
                            outfit,
                            positive: false,
                            feedbackTag: 'too_formal',
                          );
                        },
                      ),
                      _feedbackTagChip(
                        label: 'Trop sport',
                        icon: Icons.sports_gymnastics,
                        onTap: () async {
                          await _handleOutfitFeedback(
                            ref,
                            sheetContext,
                            outfit,
                            positive: false,
                            feedbackTag: 'too_sporty',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Fermer les details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleOutfitFeedback(
    WidgetRef ref,
    BuildContext context,
    _Outfit outfit, {
    required bool positive,
    String? feedbackTag,
  }) async {
    if (ref.read(outfitFeedbackSubmittingProvider)) {
      return;
    }
    ref.read(outfitFeedbackSubmittingProvider.notifier).state = true;

    try {
      final profile = ref.read(userProfileProvider);
      final now = DateTime.now();
      final season = _seasonFromMonth(now.month);
      final hourSlot = _localHourSlotLabel(now.hour);
      await ref
          .read(outfitPersonalizationProvider.notifier)
          .recordFeedback(
            outfitId: outfit.id,
            styles: outfit.styles,
            positive: positive,
          );
      await ref
          .read(outfitTelemetryProvider.notifier)
          .recordFeedback(
            positive: positive,
            outfitId: outfit.id,
            eventType: feedbackTag,
            metadata: {
              'styles': outfit.styles.join('|'),
              'preferred_styles': profile.preferredStyles.join('|'),
              'morphology': profile.morphology,
              'age': profile.age,
              'height_cm': profile.heightCm,
              'gender': profile.gender,
              'season': season,
              'hour_slot': hourSlot,
              'local_hour': now.hour,
              if (feedbackTag != null && feedbackTag.isNotEmpty)
                'feedback_tag': feedbackTag,
            },
          );

      if (!context.mounted) {
        return;
      }

      final msg = positive
          ? _tr(
              context,
              'Parfait, on va favoriser ce style.',
              'Great, we will prioritize this style.',
            )
          : (feedbackTag == null
                ? _tr(
                    context,
                    'Bien noté, on va réduire ce style.',
                    'Noted, we will reduce this style.',
                  )
                : _tr(
                    context,
                    'Merci, retour enregistré : ${_feedbackTagLabel(feedbackTag)}.',
                    'Thanks, feedback captured: ${_feedbackTagLabel(feedbackTag)}.',
                  ));

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      ref.read(outfitFeedbackSubmittingProvider.notifier).state = false;
    }
  }

  Widget _buildDetailBlock({
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _outfitCompositionItems(_Outfit outfit) {
    final items = <String>[
      if (outfit.outfitType.trim().isNotEmpty) 'Type: ${outfit.outfitType}',
      if (outfit.topPiece.trim().isNotEmpty) 'Haut: ${outfit.topPiece}',
      if (outfit.bottomPiece.trim().isNotEmpty) 'Bas: ${outfit.bottomPiece}',
      if (outfit.shoesPiece.trim().isNotEmpty)
        'Chaussures: ${outfit.shoesPiece}',
      if (outfit.layerPiece.trim().isNotEmpty) 'Couche: ${outfit.layerPiece}',
      if (outfit.accessoryPieces.isNotEmpty)
        'Accessoires: ${outfit.accessoryPieces.join(', ')}',
    ];
    if (items.isNotEmpty) {
      return items;
    }
    return <String>[outfit.description];
  }

  Widget _feedbackTagChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    );
  }

  String _feedbackTagLabel(String tag) {
    switch (tag) {
      case 'too_hot':
        return 'trop chaud';
      case 'too_cold':
        return 'trop froid';
      case 'too_formal':
        return 'trop formel';
      case 'too_sporty':
        return 'trop sport';
      default:
        return tag;
    }
  }

  Widget _buildFavoritesModeHeader(int favoritesCount) {
    return GlassContainer(
      borderRadius: 20,
      blur: 24,
      opacity: 0.12,
      padding: const EdgeInsets.all(16),
      tintColor: Colors.pinkAccent,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tenues favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$favoritesCount tenue(s) sauvegardée(s)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildWeatherSection(AsyncValue<_OutfitWeatherBundle> weatherAsync) {
    return weatherAsync.when(
      data: (weatherBundle) {
        final current = weatherBundle.currentWeather;
        if (current == null) {
          return GlassContainer(
            borderRadius: 20,
            blur: 25,
            opacity: 0.1,
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Conditions météo indisponibles.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return GlassContainer(
          borderRadius: 20,
          blur: 25,
          opacity: 0.1,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conditions - ${current.cityName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.cloud_queue,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                current.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWeatherStat(
                    'Temp',
                    '${current.temperature.toStringAsFixed(1)}°C',
                  ),
                  _buildWeatherStat('Humidite', '${current.humidity}%'),
                  _buildWeatherStat(
                    'Vent',
                    '${current.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Chargement météo...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      error: (error, stackTrace) => GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: const Text(
          'Erreur lors du chargement de la météo.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
  */

  Widget _buildWeatherStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Outfit {
  final String id;
  final String title;
  final String description;
  final String topPiece;
  final String bottomPiece;
  final String shoesPiece;
  final String layerPiece;
  final List<String> accessoryPieces;
  final String outfitType;
  final IconData icon;
  final Color color;
  final List<String> styles;
  final List<String> compatibleMorphologies;
  final List<String> genderTargets;
  final int minAge;
  final int maxAge;

  const _Outfit({
    required this.id,
    required this.title,
    required this.description,
    required this.topPiece,
    required this.bottomPiece,
    required this.shoesPiece,
    required this.layerPiece,
    required this.accessoryPieces,
    required this.outfitType,
    required this.icon,
    required this.color,
    required this.styles,
    required this.compatibleMorphologies,
    required this.genderTargets,
    required this.minAge,
    required this.maxAge,
  });

  String get quickSummary {
    final parts = <String>[
      topPiece,
      bottomPiece,
    ].where((item) => item.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(' + ');
    }
    return description;
  }

  _Outfit copyWith({
    String? description,
    String? topPiece,
    String? bottomPiece,
    String? shoesPiece,
    String? layerPiece,
    List<String>? accessoryPieces,
    String? outfitType,
  }) {
    return _Outfit(
      id: id,
      title: title,
      description: description ?? this.description,
      topPiece: topPiece ?? this.topPiece,
      bottomPiece: bottomPiece ?? this.bottomPiece,
      shoesPiece: shoesPiece ?? this.shoesPiece,
      layerPiece: layerPiece ?? this.layerPiece,
      accessoryPieces: accessoryPieces ?? this.accessoryPieces,
      outfitType: outfitType ?? this.outfitType,
      icon: icon,
      color: color,
      styles: styles,
      compatibleMorphologies: compatibleMorphologies,
      genderTargets: genderTargets,
      minAge: minAge,
      maxAge: maxAge,
    );
  }
}

class _OutfitLlmDetails {
  final String? top;
  final String? bottom;
  final String? shoes;
  final String? outerwear;
  final List<String> accessories;
  final String? typeLabel;
  final String? summary;

  const _OutfitLlmDetails({
    required this.top,
    required this.bottom,
    required this.shoes,
    required this.outerwear,
    required this.accessories,
    required this.typeLabel,
    required this.summary,
  });

  bool get hasAnyDetail {
    return (top?.trim().isNotEmpty ?? false) ||
        (bottom?.trim().isNotEmpty ?? false) ||
        (shoes?.trim().isNotEmpty ?? false) ||
        (outerwear?.trim().isNotEmpty ?? false) ||
        accessories.isNotEmpty ||
        (typeLabel?.trim().isNotEmpty ?? false) ||
        (summary?.trim().isNotEmpty ?? false);
  }
}

List<_Outfit> _applyLlmDetails(
  List<_Outfit> baseOutfits,
  Map<String, _OutfitLlmDetails> detailsByOutfitId, {
  required bool preferLlm,
}) {
  if (!preferLlm || detailsByOutfitId.isEmpty) {
    return baseOutfits;
  }

  return baseOutfits.map((outfit) {
    final details = detailsByOutfitId[outfit.id];
    if (details == null || !details.hasAnyDetail) {
      return outfit;
    }

    return outfit.copyWith(
      description: details.summary?.trim().isNotEmpty == true
          ? details.summary!.trim()
          : outfit.description,
      topPiece: details.top?.trim().isNotEmpty == true
          ? details.top!.trim()
          : outfit.topPiece,
      bottomPiece: details.bottom?.trim().isNotEmpty == true
          ? details.bottom!.trim()
          : outfit.bottomPiece,
      shoesPiece: details.shoes?.trim().isNotEmpty == true
          ? details.shoes!.trim()
          : outfit.shoesPiece,
      layerPiece: details.outerwear?.trim().isNotEmpty == true
          ? details.outerwear!.trim()
          : outfit.layerPiece,
      accessoryPieces: details.accessories.isNotEmpty
          ? details.accessories
          : outfit.accessoryPieces,
      outfitType: details.typeLabel?.trim().isNotEmpty == true
          ? details.typeLabel!.trim()
          : outfit.outfitType,
    );
  }).toList();
}

class _RankedOutfit {
  final _Outfit outfit;
  final int score;
  final List<String> reasons;

  const _RankedOutfit({
    required this.outfit,
    required this.score,
    required this.reasons,
  });
}

class _PlanningSignals {
  final bool hasWorkEvent;
  final bool hasSportEvent;
  final bool hasEveningEvent;
  final bool hasCasualEvent;
  final bool hasOutdoorEvent;

  const _PlanningSignals({
    required this.hasWorkEvent,
    required this.hasSportEvent,
    required this.hasEveningEvent,
    required this.hasCasualEvent,
    required this.hasOutdoorEvent,
  });
}

enum _DayTimeSlot { morning, afternoon, evening }

enum _PlanningContext { work, sport, evening, casual, mixed, none }

class _OutfitWeatherBundle {
  final WeatherResponse? currentWeather;
  final ForecastItem? tomorrowForecast;

  const _OutfitWeatherBundle({
    required this.currentWeather,
    required this.tomorrowForecast,
  });
}

class _OutfitWeatherContext {
  final String label;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String main;

  const _OutfitWeatherContext({
    required this.label,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.main,
  });
}

class _ForecastCoordinates {
  final double lat;
  final double lon;

  const _ForecastCoordinates({required this.lat, required this.lon});
}

Future<_ForecastCoordinates> _resolveForecastCoordinates() async {
  try {
    final permission = await Geolocator.checkPermission();
    var granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!granted) {
      final req = await Geolocator.requestPermission();
      granted =
          req == LocationPermission.always ||
          req == LocationPermission.whileInUse;
    }

    if (granted) {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
      );
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return _ForecastCoordinates(lat: pos.latitude, lon: pos.longitude);
    }
  } catch (_) {
    // Fallback below
  }

  return const _ForecastCoordinates(lat: -18.8792, lon: 47.5079);
}

ForecastItem? _pickTomorrowForecast(List<ForecastItem> forecasts) {
  final now = DateTime.now();
  final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
  final tomorrowItems = forecasts.where((item) {
    final d = item.dateTime;
    return d.year == tomorrowDate.year &&
        d.month == tomorrowDate.month &&
        d.day == tomorrowDate.day;
  }).toList();

  if (tomorrowItems.isEmpty) {
    return null;
  }

  tomorrowItems.sort((a, b) {
    final aDiff = (a.dateTime.hour - 12).abs();
    final bDiff = (b.dateTime.hour - 12).abs();
    return aDiff.compareTo(bDiff);
  });

  return tomorrowItems.first;
}

_OutfitWeatherContext? _weatherContextFromCurrent(WeatherResponse? weather) {
  if (weather == null) {
    return null;
  }

  return _OutfitWeatherContext(
    label:
        '${weather.description} | ${weather.temperature.toStringAsFixed(1)}°C | ${weather.humidity}% | ${weather.windSpeed.toStringAsFixed(1)} m/s',
    temperature: weather.temperature,
    humidity: weather.humidity,
    windSpeed: weather.windSpeed,
    main: weather.main,
  );
}

_OutfitWeatherContext? _weatherContextFromForecast(ForecastItem? forecast) {
  if (forecast == null) {
    return null;
  }

  return _OutfitWeatherContext(
    label:
        '${forecast.description} | ${forecast.temperature.toStringAsFixed(1)}°C | ${forecast.humidity}% | ${forecast.windSpeed.toStringAsFixed(1)} m/s',
    temperature: forecast.temperature,
    humidity: forecast.humidity,
    windSpeed: forecast.windSpeed,
    main: forecast.main,
  );
}
