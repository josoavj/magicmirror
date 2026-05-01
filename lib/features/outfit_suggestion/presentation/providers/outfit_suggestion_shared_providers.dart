import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, double> _defaultOutfitMlPriors = <String, double>{
  // Priors cold-start: permettent un ranking ML non vide avant feedback user.
  'business_smart': 0.62,
  'elegant': 0.6,
  'minimal_monochrome': 0.58,
  'casual_moderne': 0.57,
  'street_dynamics': 0.55,
  'sport': 0.52,
};

final outfitMlScoreMapProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  if (!AppConfig.enableHybridMlRanking) {
    return _defaultOutfitMlPriors;
  }

  SupabaseClient client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    return _defaultOutfitMlPriors;
  }

  final userId = client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return _defaultOutfitMlPriors;
  }

  try {
    final rows = await client
        .from('outfit_ml_scores')
        .select('outfit_id,score')
        .eq('user_id', userId);

    final map = <String, double>{};
    if (rows is List) {
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final outfitId = row['outfit_id']?.toString();
        final scoreRaw = row['score'];
        final score = scoreRaw is num
            ? scoreRaw.toDouble()
            : double.tryParse(scoreRaw?.toString() ?? '');
        if (outfitId != null && outfitId.isNotEmpty && score != null) {
          map[outfitId] = score.clamp(0, 1);
        }
      }
    }
    if (map.isEmpty) {
      return _defaultOutfitMlPriors;
    }

    return <String, double>{..._defaultOutfitMlPriors, ...map};
  } on PostgrestException catch (error) {
    // Table optionnelle: absence de schema ne doit pas casser l'UI.
    if (error.code == '42P01') {
      return _defaultOutfitMlPriors;
    }
    rethrow;
  } catch (_) {
    return _defaultOutfitMlPriors;
  }
});

final outfitSecondaryLlmScoreMapProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  if (!AppConfig.enableSecondaryLlmRanking) {
    return const <String, double>{};
  }

  SupabaseClient client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    return const <String, double>{};
  }

  final userId = client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return const <String, double>{};
  }
  final profile = ref.watch(userProfileProvider);
  final useProfileContext = ref.watch(outfitLlamaUseProfileContextProvider);
  final strictGenderFilter = ref.watch(outfitLlamaStrictGenderFilterProvider);

  Future<List<dynamic>> fetchRowsWithModel() {
    return client
        .from('outfit_llm_scores')
        .select(
          'outfit_id,score,model_tag,target_gender,target_styles,target_morphology,profile_payload',
        )
        .eq('user_id', userId)
        .eq('model_tag', AppConfig.secondaryLlmModelTag);
  }

  Future<List<dynamic>> fetchRowsWithoutModel() {
    return client
        .from('outfit_llm_scores')
        .select('outfit_id,score')
        .eq('user_id', userId);
  }

  try {
    List<dynamic> rows;
    try {
      rows = await fetchRowsWithModel();
    } on PostgrestException catch (error) {
      // Colonne model_tag optionnelle.
      if (error.code == '42703') {
        rows = await fetchRowsWithoutModel();
      } else {
        rethrow;
      }
    }

    final map = <String, double>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final outfitId = row['outfit_id']?.toString();
      final scoreRaw = row['score'];
      final score = scoreRaw is num
          ? scoreRaw.toDouble()
          : double.tryParse(scoreRaw?.toString() ?? '');
      if (!_llamaRowMatchesProfile(
        row,
        profile: profile,
        useProfileContext: useProfileContext,
        strictGenderFilter: strictGenderFilter,
      )) {
        continue;
      }
      if (outfitId != null && outfitId.isNotEmpty && score != null) {
        map[outfitId] = score.clamp(0, 1);
      }
    }

    return map;
  } on PostgrestException catch (error) {
    // Table optionnelle: absence de schema ne doit pas casser l'UI.
    if (error.code == '42P01') {
      return const <String, double>{};
    }
    rethrow;
  } catch (_) {
    return const <String, double>{};
  }
});

final outfitCloudTelemetryProvider = FutureProvider<OutfitTelemetryState>((
  ref,
) async {
  SupabaseClient client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    return const OutfitTelemetryState.initial();
  }

  final userId = client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return const OutfitTelemetryState.initial();
  }

  try {
    final rows = await client
        .from('outfit_feedback_events')
        .select('event_type')
        .eq('user_id', userId)
        .limit(5000);

    var likes = 0;
    var dislikes = 0;
    var seen = 0;
    var favoriteAdds = 0;
    var favoriteRemoves = 0;

    if (rows is List) {
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final type = row['event_type']?.toString() ?? '';
        switch (type) {
          case 'like':
            likes++;
            break;
          case 'dislike':
            dislikes++;
            break;
          case 'seen':
            seen++;
            break;
          case 'favorite_add':
            favoriteAdds++;
            break;
          case 'favorite_remove':
            favoriteRemoves++;
            break;
        }
      }
    }

    return OutfitTelemetryState(
      likes: likes,
      dislikes: dislikes,
      seen: seen,
      favoriteAdds: favoriteAdds,
      favoriteRemoves: favoriteRemoves,
    );
  } on PostgrestException catch (error) {
    if (error.code == '42P01') {
      return const OutfitTelemetryState.initial();
    }
    rethrow;
  }
});

enum OutfitFavoritesSyncStatus { idle, syncing, synced, localOnly, error }

final outfitFavoritesSyncStatusProvider =
    StateProvider<OutfitFavoritesSyncStatus>((ref) {
      return OutfitFavoritesSyncStatus.idle;
    });

final outfitFavoritesSyncMessageProvider = StateProvider<String>((ref) {
  return 'Aucune synchronisation';
});

final outfitStrictWeatherModeProvider = StateProvider<bool>((ref) {
  return true;
});

final outfitCreativeMixEnabledProvider = StateProvider<bool>((ref) {
  return AppConfig.enableCreativeOutfitMix;
});

final outfitCreativeExplorationShareProvider = StateProvider<double>((ref) {
  return AppConfig.outfitCreativeExplorationShare;
});

final outfitCreativeBoostProvider = StateProvider<int>((ref) {
  return AppConfig.outfitCreativeBoost;
});

final outfitSecondaryLlmEnabledProvider = StateProvider<bool>((ref) {
  return AppConfig.enableSecondaryLlmRanking;
});

final outfitSecondaryLlmWeightProvider = StateProvider<double>((ref) {
  return AppConfig.secondaryLlmWeight;
});

final outfitLlamaUseProfileContextProvider = StateProvider<bool>((ref) {
  return AppConfig.enableLlamaProfileContext;
});

final outfitLlamaStrictGenderFilterProvider = StateProvider<bool>((ref) {
  return AppConfig.enableLlamaStrictGenderFilter;
});

final outfitFeedbackSubmittingProvider = StateProvider<bool>((ref) {
  return false;
});

final outfitTelemetryProvider =
    StateNotifierProvider<OutfitTelemetryNotifier, OutfitTelemetryState>((ref) {
      return OutfitTelemetryNotifier();
    });

class OutfitTelemetryState {
  final int likes;
  final int dislikes;
  final int seen;
  final int favoriteAdds;
  final int favoriteRemoves;

  const OutfitTelemetryState({
    required this.likes,
    required this.dislikes,
    required this.seen,
    required this.favoriteAdds,
    required this.favoriteRemoves,
  });

  const OutfitTelemetryState.initial()
    : likes = 0,
      dislikes = 0,
      seen = 0,
      favoriteAdds = 0,
      favoriteRemoves = 0;

  OutfitTelemetryState copyWith({
    int? likes,
    int? dislikes,
    int? seen,
    int? favoriteAdds,
    int? favoriteRemoves,
  }) {
    return OutfitTelemetryState(
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      seen: seen ?? this.seen,
      favoriteAdds: favoriteAdds ?? this.favoriteAdds,
      favoriteRemoves: favoriteRemoves ?? this.favoriteRemoves,
    );
  }

  int get feedbackTotal => likes + dislikes;

  double get acceptanceRate {
    if (feedbackTotal == 0) {
      return 0;
    }
    return likes / feedbackTotal;
  }

  double get rejectionRate {
    if (feedbackTotal == 0) {
      return 0;
    }
    return dislikes / feedbackTotal;
  }
}

class OutfitTelemetryNotifier extends StateNotifier<OutfitTelemetryState> {
  OutfitTelemetryNotifier() : super(const OutfitTelemetryState.initial()) {
    Future.microtask(_load);
  }

  static const _prefsKey = 'outfit.telemetry.v1';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

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

      int readInt(String key) {
        final value = decoded[key];
        return int.tryParse(value?.toString() ?? '') ?? 0;
      }

      state = OutfitTelemetryState(
        likes: readInt('likes'),
        dislikes: readInt('dislikes'),
        seen: readInt('seen'),
        favoriteAdds: readInt('favoriteAdds'),
        favoriteRemoves: readInt('favoriteRemoves'),
      );
    } catch (_) {
      // Ignore malformed telemetry cache.
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'likes': state.likes,
        'dislikes': state.dislikes,
        'seen': state.seen,
        'favoriteAdds': state.favoriteAdds,
        'favoriteRemoves': state.favoriteRemoves,
      }),
    );
  }

  Future<void> recordFeedback({
    required bool positive,
    String? outfitId,
    String? eventType,
    Map<String, dynamic>? metadata,
  }) async {
    state = positive
        ? state.copyWith(likes: state.likes + 1)
        : state.copyWith(dislikes: state.dislikes + 1);
    await _save();
    await _exportCloudEvent(
      eventType: eventType ?? (positive ? 'like' : 'dislike'),
      outfitId: outfitId,
      metadata: metadata,
    );
  }

  Future<void> recordSeen({
    String? outfitId,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(seen: state.seen + 1);
    await _save();
    await _exportCloudEvent(
      eventType: 'seen',
      outfitId: outfitId,
      metadata: metadata,
    );
  }

  Future<void> recordFavoriteToggle({
    required bool added,
    String? outfitId,
    Map<String, dynamic>? metadata,
  }) async {
    state = added
        ? state.copyWith(favoriteAdds: state.favoriteAdds + 1)
        : state.copyWith(favoriteRemoves: state.favoriteRemoves + 1);
    await _save();
    await _exportCloudEvent(
      eventType: added ? 'favorite_add' : 'favorite_remove',
      outfitId: outfitId,
      metadata: metadata,
    );
  }

  Future<void> reset() async {
    state = const OutfitTelemetryState.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _exportCloudEvent({
    required String eventType,
    String? outfitId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!AppConfig.enableCloudFeedbackExport) {
      return;
    }

    final client = _client;
    if (client == null) {
      return;
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      await client.from('outfit_feedback_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'outfit_id': outfitId,
        'payload': {
          'likes': state.likes,
          'dislikes': state.dislikes,
          'seen': state.seen,
          'favorite_adds': state.favoriteAdds,
          'favorite_removes': state.favoriteRemoves,
          ...?metadata,
        },
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Best-effort only: no UX impact if cloud telemetry is unavailable.
    }
  }
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
