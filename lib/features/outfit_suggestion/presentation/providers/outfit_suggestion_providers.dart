import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/core/services/storage_service.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/services/outfit_ranking_service.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_shared_providers.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';
import 'package:magicmirror/features/weather/data/services/weather_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agendaEventsForDayProvider =
    FutureProvider.family<List<AgendaEvent>, DateTime>((ref, day) async {
  final service = ref.watch(agendaSupabaseServiceProvider);
  final normalizedDay = DateTime(day.year, day.month, day.day);
  try {
    return await service.fetchEventsForDay(normalizedDay);
  } catch (_) {
    return const <AgendaEvent>[];
  }
});

final outfitWeatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final outfitWeatherBundleProvider =
    FutureProvider<OutfitWeatherBundle>((ref) async {
  final weatherService = ref.watch(outfitWeatherServiceProvider);
  final currentWeather = await weatherService.getCurrentWeather();

  ForecastItem? tomorrowForecast;
  final rankingService = ref.watch(outfitRankingServiceProvider);
  final coords = await rankingService.resolveForecastCoordinates();
  final forecast = await weatherService.getForecast(coords.lat, coords.lon);
  if (forecast != null) {
    tomorrowForecast = rankingService.pickTomorrowForecast(forecast.forecasts);
  }

  return OutfitWeatherBundle(
    currentWeather: currentWeather,
    tomorrowForecast: tomorrowForecast,
  );
});

final outfitSecondaryLlmDetailsProvider =
    FutureProvider<Map<String, OutfitLlmDetails>>((ref) async {
  if (!AppConfig.enableSecondaryLlmRanking) {
    return const <String, OutfitLlmDetails>{};
  }

  SupabaseClient client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    return const <String, OutfitLlmDetails>{};
  }

  final userId = client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return const <String, OutfitLlmDetails>{};
  }
  final profile = ref.watch(userProfileProvider);
  final useProfileContext = ref.watch(outfitLlamaUseProfileContextProvider);
  final strictGenderFilter = ref.watch(outfitLlamaStrictGenderFilterProvider);
  final rankingService = ref.watch(outfitRankingServiceProvider);

  try {
    final rows = await client
        .from('outfit_llm_details')
        .select(
          'outfit_id,top_item,bottom_item,shoes_item,outerwear_item,accessories,type_label,summary,model_tag,target_gender,target_styles,target_morphology,profile_payload',
        )
        .eq('user_id', userId)
        .eq('model_tag', AppConfig.secondaryLlmModelTag);

    final detailsByOutfitId = <String, OutfitLlmDetails>{};
    for (final row in rows) {
      final outfitId = row['outfit_id']?.toString();
      if (outfitId == null || outfitId.isEmpty) continue;

      if (!rankingService.llamaRowMatchesProfile(
        row,
        profile: profile,
        useProfileContext: useProfileContext,
        strictGenderFilter: strictGenderFilter,
      )) {
        continue;
      }

      final details = OutfitLlmDetails(
        top: row['top_item']?.toString(),
        bottom: row['bottom_item']?.toString(),
        shoes: row['shoes_item']?.toString(),
        outerwear: row['outerwear_item']?.toString(),
        accessories: rankingService.parseAccessories(row['accessories']),
        typeLabel: row['type_label']?.toString(),
        summary: row['summary']?.toString(),
      );

      if (details.hasAnyDetail) {
        detailsByOutfitId[outfitId] = details;
      }
    }
    return detailsByOutfitId;
  } catch (_) {
    return const <String, OutfitLlmDetails>{};
  }
});

final outfitRankingServiceProvider = Provider<OutfitRankingService>((ref) {
  return OutfitRankingService();
});

final rankedOutfitsProvider =
    Provider.family<List<RankedOutfit>, RankingParams>((ref, params) {
  final service = ref.watch(outfitRankingServiceProvider);
  return service.rankOutfits(params);
});

final outfitPersonalizationProvider =
    StateNotifierProvider<OutfitPersonalizationNotifier, OutfitPersonalizationState>((
  ref,
) {
  final storageService = ref.watch(storageServiceProvider);
  return OutfitPersonalizationNotifier(storageService);
});

class OutfitPersonalizationNotifier
    extends StateNotifier<OutfitPersonalizationState> {
  final StorageService _storageService;

  OutfitPersonalizationNotifier(this._storageService)
    : super(const OutfitPersonalizationState.initial()) {
    Future.microtask(_load);
  }

  static const _prefsKey = 'outfit.personalization.v1';

  Future<void> _load() async {
    final raw = await _storageService.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      Map<String, int> parseIntMap(dynamic input) {
        if (input is! Map) return {};
        return input.map(
          (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
        );
      }

      state = OutfitPersonalizationState(
        styleBiasByStyle: parseIntMap(decoded['styleBiasByStyle']),
        outfitBiasById: parseIntMap(decoded['outfitBiasById']),
        lastSeenAtMsByOutfitId: parseIntMap(decoded['lastSeenAtMsByOutfitId']),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    await _storageService.saveString(
      _prefsKey,
      jsonEncode({
        'styleBiasByStyle': state.styleBiasByStyle,
        'outfitBiasById': state.outfitBiasById,
        'lastSeenAtMsByOutfitId': state.lastSeenAtMsByOutfitId,
      }),
    );
  }

  Future<void> recordFeedback({
    required String outfitId,
    required List<String> styles,
    required bool positive,
  }) async {
    final nextOutfitBias = Map<String, int>.from(state.outfitBiasById);
    nextOutfitBias[outfitId] =
        ((nextOutfitBias[outfitId] ?? 0) + (positive ? 10 : -10)).clamp(
          -40,
          40,
        );
    final nextStyleBias = Map<String, int>.from(state.styleBiasByStyle);
    for (final s in styles) {
      final key = s.toLowerCase();
      nextStyleBias[key] =
          ((nextStyleBias[key] ?? 0) + (positive ? 6 : -6)).clamp(-30, 30);
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
    state = state.copyWith(lastSeenAtMsByOutfitId: nextSeen);
    await _save();
  }
}

final outfitFavoritesProvider =
    StateNotifierProvider<OutfitFavoritesNotifier, Set<String>>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return OutfitFavoritesNotifier(storageService);
    });

class OutfitFavoritesNotifier extends StateNotifier<Set<String>> {
  final StorageService _storageService;

  OutfitFavoritesNotifier(this._storageService) : super(<String>{}) {
    _load();
  }

  static const _prefsKey = 'outfit.favorites.v1';

  Future<void> _load() async {
    final list = await _storageService.getList(_prefsKey);
    if (list != null) state = list.toSet();
  }

  Future<void> toggleFavorite(String outfitId) async {
    final next = Set<String>.from(state);
    if (next.contains(outfitId)) {
      next.remove(outfitId);
    } else {
      next.add(outfitId);
    }
    state = next;
    await _storageService.saveList(_prefsKey, state.toList());
  }
}

// Extension to bridge ranking service helpers
extension OutfitRankingServiceHelpers on OutfitRankingService {
  Future<ForecastCoordinates> resolveForecastCoordinates() async {
    return const ForecastCoordinates(lat: -18.8792, lon: 47.5079);
  }

  ForecastItem? pickTomorrowForecast(List<ForecastItem> forecasts) {
    if (forecasts.isEmpty) return null;
    return forecasts.first;
  }
}
