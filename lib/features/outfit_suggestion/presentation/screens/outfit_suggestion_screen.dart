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

// --- Providers ---

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
    FutureProvider<_OutfitWeatherBundle>((ref) async {
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
  final strictGenderFilter = ref.watch(outfitLlamaStrictGenderFilterProvider);

  try {
    final rows = await client
        .from('outfit_llm_details')
        .select(
            'outfit_id,top_item,bottom_item,shoes_item,outerwear_item,accessories,type_label,summary,model_tag,target_gender,target_styles,target_morphology,profile_payload')
        .eq('user_id', userId)
        .eq('model_tag', AppConfig.secondaryLlmModelTag);

    final detailsByOutfitId = <String, _OutfitLlmDetails>{};
    for (final row in rows) {
      final outfitId = row['outfit_id']?.toString();
      if (outfitId == null || outfitId.isEmpty) continue;

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
  } catch (_) {
    return const <String, _OutfitLlmDetails>{};
  }
});

final rankedOutfitsProvider =
    Provider.family<List<_RankedOutfit>, _RankingParams>((ref, params) {
  final profile = params.profile;
  final events = params.events;
  final favoriteIds = params.favoriteIds;
  final personalization = params.personalization;
  final mlScoreMap = params.mlScoreMap;
  final llmDetailsByOutfitId = params.llmDetailsByOutfitId;
  final secondaryLlmEnabled = params.secondaryLlmEnabled;
  final targetDay = params.targetDay;
  final weatherContext = params.weatherContext;
  final strictWeatherMode = params.strictWeatherMode;
  final creativeMixEnabled = params.creativeMixEnabled;
  final creativeExplorationShare = params.creativeExplorationShare;
  final creativeBoost = params.creativeBoost;
  final excludedOutfitIds = params.excludedOutfitIds;
  final referenceNow = params.referenceNow;

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

  final normalizedStyles = profile.preferredStyles.map(_normalizeStyle).toSet();
  final normalizedGender = profile.gender.toLowerCase();
  final planningSignals = _extractPlanningSignals(events);
  final isWeekend = _isWeekend(targetDay);
  final prioritySlot = _resolvePrioritySlot(events, referenceNow);
  final primaryContext = _resolvePrimaryContext(events, referenceNow);
  final season = _seasonFromMonth(targetDay.month);
  final localHourSlot = _localHourSlotLabel(referenceNow.hour);

  var candidates = allOutfits.where((outfit) {
    final ageOk = profile.age >= outfit.minAge && profile.age <= outfit.maxAge;
    final morphologyOk = _isMorphologyCompatible(profile.morphology, outfit);
    return ageOk && morphologyOk;
  }).toList();

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
    }
  }

  if (candidates.isEmpty) candidates = allOutfits;

  final ranked = candidates.map((outfit) {
    var score = 10;
    final reasonScores = <String, int>{};
    final contextCompatible = _isContextCompatible(primaryContext, outfit.styles);

    void addReason(String reason, int weight) {
      final current = reasonScores[reason] ?? 0;
      if (weight > current) reasonScores[reason] = weight;
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
        outfit.genderTargets.any((gender) => normalizedGender.contains(gender));
    if (isGenderMatch) score += 12;

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
    score += planningCoherence.round();
    if (planningCoherence > 0) addReason('Cohérence avec vos priorités du jour', 88);

    if (isWeekend &&
        outfit.styles.any((style) =>
            style == 'casual' || style == 'streetwear' || style == 'sport')) {
      score += 12;
      addReason('Adapté au rythme du week-end', 35);
    }

    if (!isWeekend &&
        outfit.styles.any((style) => style == 'business' || style == 'elegant')) {
      score += 12;
      addReason('Adapté à une journée de semaine', 35);
    }

    if (planningSignals.hasWorkEvent &&
        outfit.styles.any((style) => style == 'business' || style == 'elegant')) {
      score += 30;
      addReason('Compatible avec votre planning pro', 105);
    }

    if (planningSignals.hasSportEvent && outfit.styles.contains('sport')) {
      score += 30;
      addReason('Compatible avec vos activités sportives', 105);
    }

    if (planningSignals.hasEveningEvent &&
        outfit.styles.any((style) => style == 'elegant' || style == 'streetwear')) {
      score += 16;
      addReason('Adapté à vos sorties du soir', 65);
    }

    final slotBoost = _slotScoreBoost(prioritySlot, outfit.styles);
    if (slotBoost > 0) {
      score += slotBoost;
      addReason('Optimisé pour le créneau ${_slotLabel(prioritySlot).toLowerCase()}', 50);
    }

    final weatherBoost = _weatherScoreBoost(weatherContext, outfit.styles,
        strictWeatherMode: strictWeatherMode);
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
    }

    final styleBias = _styleBiasBoost(
      styles: outfit.styles,
      styleBiasByStyle: personalization.styleBiasByStyle,
    );
    score += styleBias;
    if (styleBias > 0) addReason('Affinite apprenue avec vos styles', 92);

    final outfitBias = personalization.outfitBiasById[outfit.id] ?? 0;
    score += outfitBias;
    if (outfitBias > 0) addReason('Feedback positif précédent', 84);

    final repetitionPenalty = _recentRepetitionPenalty(
      outfitId: outfit.id,
      lastSeenAtMsByOutfitId: personalization.lastSeenAtMsByOutfitId,
    );
    score -= repetitionPenalty;
    if (repetitionPenalty > 0) addReason('Rotation anti-répétition', 52);

    final freshnessBonus = _freshnessBonus(
      outfitId: outfit.id,
      lastSeenAtMsByOutfitId: personalization.lastSeenAtMsByOutfitId,
    );
    score += freshnessBonus;
    if (freshnessBonus > 0) addReason('Favorise des tenues moins récentes', 58);

    final dailyVarietyJitter = _dailyVarietyJitter(
      outfitId: outfit.id,
      targetDay: targetDay,
    );
    score += dailyVarietyJitter;
    if (dailyVarietyJitter > 0) addReason('Rotation douce entre tenues proches', 36);

    final mlScore = mlScoreMap[outfit.id];
    if (AppConfig.enableHybridMlRanking && mlScore != null) {
      score = ((1 - AppConfig.hybridMlWeight) * score +
              AppConfig.hybridMlWeight * (mlScore * 100))
          .round();
      addReason('Calibration ML hybride', 86);
    }

    if (score < 0) score = 0;
    final reasons = _sortedReasons(reasonScores);
    return _RankedOutfit(outfit: outfit, score: score, reasons: reasons);
  }).toList()..sort((a, b) => b.score.compareTo(a.score));

  final diversePool = _selectDiverseTopOutfits(ranked,
      maxCount: ranked.length < 8 ? ranked.length : 8);

  return _selectCreativeTopOutfits(
    diversePool,
    maxCount: 4,
    targetDay: targetDay,
    creativeMixEnabled: creativeMixEnabled,
    creativeExplorationShare: creativeExplorationShare,
    creativeBoost: creativeBoost,
  );
});

// --- Logic Helpers (Top-Level) ---

List<String> _parseAccessories(dynamic raw) {
  if (raw == null) return const <String>[];
  if (raw is List) {
    return raw.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
  }
  final value = raw.toString().trim();
  if (value.isEmpty) return const <String>[];
  final splitter = value.contains('|') ? '|' : ',';
  return value.split(splitter).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
}

bool _llamaRowMatchesProfile(Map<String, dynamic> row, {required UserProfile profile, required bool useProfileContext, required bool strictGenderFilter}) {
  if (!useProfileContext) return true;
  final payload = row['profile_payload'];
  final payloadMap = payload is Map<String, dynamic> ? payload : <String, dynamic>{};
  final rowGenderRaw = row['target_gender'] ?? row['gender_target'] ?? row['profile_gender'] ?? payloadMap['gender'];
  final rowGender = rowGenderRaw?.toString().trim() ?? '';
  if (strictGenderFilter && rowGender.isNotEmpty) {
    if (!_genderMatchesProfile(rowGender, profile.gender)) return false;
  }
  final rowStyles = _toNormalizedStringSet(row['target_styles'] ?? payloadMap['preferredStyles'] ?? payloadMap['styles']);
  final profileStyles = _toNormalizedStringSet(profile.preferredStyles);
  if (rowStyles.isNotEmpty && profileStyles.isNotEmpty) {
    if (!rowStyles.any(profileStyles.contains)) return false;
  }
  final rowMorphologyRaw = row['target_morphology'] ?? payloadMap['morphology'];
  final rowMorphology = rowMorphologyRaw?.toString().trim() ?? '';
  if (rowMorphology.isNotEmpty && !_normalizeToken(rowMorphology).contains(_normalizeToken(profile.morphology)) && !_normalizeToken(profile.morphology).contains(_normalizeToken(rowMorphology))) return false;
  return true;
}

bool _genderMatchesProfile(String targetGender, String profileGender) {
  final target = _normalizeToken(targetGender);
  final profile = _normalizeToken(profileGender);
  if (target.isEmpty || target == 'all' || target == 'any' || target == 'unisex') return true;
  if (target.contains('nonprecise') || target.contains('nonbinaire')) return true;
  if (target.contains('femme') || target.contains('female') || target == 'f') {
    return profile.contains('femme') || profile.contains('female') || profile == 'f';
  }
  if (target.contains('homme') || target.contains('male') || target == 'm') {
    return profile.contains('homme') || profile.contains('male') || profile == 'm';
  }
  return true;
}

Set<String> _toNormalizedStringSet(dynamic raw) {
  if (raw == null) return <String>{};
  if (raw is List) return raw.map((item) => _normalizeToken(item.toString())).where((item) => item.isNotEmpty).toSet();
  final value = raw.toString().trim();
  if (value.isEmpty) return <String>{};
  final splitter = value.contains('|') ? '|' : (value.contains(',') ? ',' : ' ');
  return value.split(splitter).map(_normalizeToken).where((item) => item.isNotEmpty).toSet();
}

String _normalizeToken(String value) {
  final lowered = value.toLowerCase();
  const diacriticsMap = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae', 'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'œ': 'oe', 'ù': 'u',
    'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
  };
  final folded = StringBuffer();
  for (final rune in lowered.runes) {
    final char = String.fromCharCode(rune);
    folded.write(diacriticsMap[char] ?? char);
  }
  return folded.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _normalizeStyle(String value) {
  final v = value.toLowerCase();
  if (v.contains('eleg')) return 'elegant';
  if (v.contains('mini')) return 'minimaliste';
  return v;
}

_PlanningSignals _extractPlanningSignals(List<AgendaEvent> events) {
  var hasWorkEvent = false;
  var hasSportEvent = false;
  var hasEveningEvent = false;
  var hasCasualEvent = false;
  var hasOutdoorEvent = false;

  for (final event in events) {
    if (event.isCompleted) continue;
    final eventBlob = '${event.eventType} ${event.title} ${event.description ?? ''}'.toLowerCase();

    if (_containsAny(eventBlob, const ['work', 'travail', 'reunion', 'meeting', 'bureau', 'business'])) hasWorkEvent = true;
    if (_containsAny(eventBlob, const ['sport', 'gym', 'run', 'course', 'training'])) hasSportEvent = true;
    if (_containsAny(eventBlob, const ['soiree', 'soir', 'diner', 'resto', 'event', 'sortie'])) hasEveningEvent = true;
    if (_containsAny(eventBlob, const ['amis', 'detente', 'shopping', 'promenade', 'famille', 'loisir', 'casual'])) hasCasualEvent = true;
    if (_containsAny(eventBlob, const ['exterieur', 'outdoor', 'marche', 'balade', 'deplacement'])) hasOutdoorEvent = true;
    if (event.startTime.hour >= 18) hasEveningEvent = true;
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
  return keywords.any((k) => source.contains(k));
}

bool _isWeekend(DateTime date) {
  return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
}

_DayTimeSlot _resolvePrioritySlot(List<AgendaEvent> events, DateTime now) {
  final pending = events.where((event) => !event.isCompleted).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  for (final event in pending) {
    if (!event.endTime.isBefore(now)) return _slotFromHour(event.startTime.hour);
  }
  return _slotFromHour(now.hour);
}

_DayTimeSlot _slotFromHour(int hour) {
  if (hour < 12) return _DayTimeSlot.morning;
  if (hour < 18) return _DayTimeSlot.afternoon;
  return _DayTimeSlot.evening;
}

_PlanningContext _resolvePrimaryContext(List<AgendaEvent> events, DateTime referenceNow) {
  final pending = events.where((event) => !event.isCompleted).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  for (final event in pending) {
    if (!event.endTime.isBefore(referenceNow)) return _contextFromEvent(event);
  }
  if (pending.isNotEmpty) return _contextFromEvent(pending.first);
  return _PlanningContext.none;
}

_PlanningContext _contextFromEvent(AgendaEvent event) {
  final blob = '${event.eventType} ${event.title} ${event.description ?? ''}'.toLowerCase();
  if (_containsAny(blob, const ['work', 'travail', 'meeting', 'reunion', 'business'])) return _PlanningContext.work;
  if (_containsAny(blob, const ['sport', 'gym', 'training', 'fitness', 'run'])) return _PlanningContext.sport;
  if (_containsAny(blob, const ['soir', 'soiree', 'diner', 'event', 'sortie'])) return _PlanningContext.evening;
  if (_containsAny(blob, const ['detente', 'famille', 'amis', 'shopping', 'loisir'])) return _PlanningContext.casual;
  return _PlanningContext.mixed;
}

String _seasonFromMonth(int month) {
  if (month == 12 || month <= 2) return 'winter';
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  return 'autumn';
}

String _localHourSlotLabel(int hour) {
  if (hour < 12) return 'morning';
  if (hour < 18) return 'afternoon';
  return 'evening';
}

bool _isMorphologyCompatible(String morphology, _Outfit outfit) {
  final normalized = morphology.trim().toLowerCase();
  if (normalized.contains('non definie') || normalized.contains('non définie')) return true;
  return _matchesMorphology(profileMorphology: morphology, compatibleMorphologies: outfit.compatibleMorphologies);
}

bool _matchesMorphology({required String profileMorphology, required List<String> compatibleMorphologies}) {
  if (compatibleMorphologies.contains('all')) return true;
  final aliases = _morphologyAliases(profileMorphology);
  return compatibleMorphologies.any((m) => aliases.contains(m));
}

Set<String> _morphologyAliases(String value) {
  final normalized = value.trim();
  switch (normalized) {
    case 'Sablier (X)':
    case 'Hanches et épaules équilibrées':
      return {'Sablier (X)', 'Hanches et épaules équilibrées', 'Hanches et epaules equilibrees'};
    case 'Poire (A)':
    case 'Hanches plus marquées':
      return {'Poire (A)', 'Hanches plus marquées', 'Hanches plus marquees'};
    case 'Rectangulaire (H)':
    case 'Silhouette droite':
      return {'Rectangulaire (H)', 'Silhouette droite'};
    case 'Triangle Inverse (V)':
    case 'Épaules plus larges':
      return {'Triangle Inverse (V)', 'Épaules plus larges', 'Epaules plus larges'};
    default:
      return {normalized};
  }
}

bool _passesHardConstraints({
  required _Outfit outfit,
  required _OutfitWeatherContext? weatherContext,
  required bool strictWeatherMode,
  required _PlanningSignals planningSignals,
  required _PlanningContext primaryContext,
}) {
  final styles = outfit.styles;
  final enforceWorkGate = (planningSignals.hasWorkEvent || primaryContext == _PlanningContext.work) &&
      !planningSignals.hasSportEvent &&
      primaryContext != _PlanningContext.mixed;
  if (enforceWorkGate && !styles.any((s) => s == 'business' || s == 'elegant')) return false;

  if (weatherContext == null || !strictWeatherMode) return true;
  final main = weatherContext.main.toLowerCase();
  final isRainy = main.contains('rain') || main.contains('thunder') || main.contains('snow');
  if (isRainy && styles.contains('streetwear') && !styles.contains('business')) return false;
  if (weatherContext.temperature >= 31 && styles.contains('business') && !styles.contains('casual')) return false;
  if (weatherContext.temperature <= 8 && styles.length == 1 && styles.contains('sport')) return false;
  return true;
}

bool _isContextCompatible(_PlanningContext context, List<String> styles) {
  switch (context) {
    case _PlanningContext.work: return styles.any((s) => s == 'business' || s == 'elegant');
    case _PlanningContext.sport: return styles.contains('sport');
    case _PlanningContext.evening: return styles.any((s) => s == 'elegant' || s == 'streetwear');
    case _PlanningContext.casual: return styles.any((s) => s == 'casual' || s == 'minimaliste' || s == 'streetwear');
    case _PlanningContext.mixed: return styles.any((s) => s == 'casual' || s == 'minimaliste' || s == 'business');
    case _PlanningContext.none: return true;
  }
}

double _planningCoherenceBoost({
  required _PlanningSignals planningSignals,
  required _PlanningContext primaryContext,
  required List<String> styles,
}) {
  var boost = 0.0;
  if (primaryContext == _PlanningContext.work) {
    boost += styles.any((s) => s == 'business' || s == 'elegant') ? 8 : -8;
  }
  if (primaryContext == _PlanningContext.sport) {
    boost += styles.contains('sport') ? 8 : -8;
  }
  return boost;
}

int _slotScoreBoost(_DayTimeSlot slot, List<String> styles) {
  switch (slot) {
    case _DayTimeSlot.morning: return styles.any((s) => s == 'business' || s == 'minimaliste') ? 14 : 0;
    case _DayTimeSlot.afternoon: return styles.any((s) => s == 'casual' || s == 'streetwear') ? 12 : 0;
    case _DayTimeSlot.evening: return styles.any((s) => s == 'elegant' || s == 'streetwear') ? 16 : 0;
  }
}

String _slotLabel(_DayTimeSlot slot) {
  switch (slot) {
    case _DayTimeSlot.morning: return 'Matin';
    case _DayTimeSlot.afternoon: return 'Après-midi';
    case _DayTimeSlot.evening: return 'Soirée';
  }
}

int _weatherScoreBoost(_OutfitWeatherContext? weather, List<String> styles, {required bool strictWeatherMode}) {
  if (weather == null) return 0;
  var boost = 0;
  if (weather.temperature >= 28 && styles.any((s) => s == 'casual' || s == 'minimaliste')) boost += 14;
  if (weather.temperature <= 16 && styles.any((s) => s == 'business' || s == 'elegant')) boost += 12;
  return boost;
}

int _seasonRainHourBoost({required _OutfitWeatherContext? weather, required List<String> styles, required String season, required String localHourSlot}) {
  var boost = 0;
  if (season == 'summer' && styles.any((s) => s == 'casual' || s == 'minimaliste')) boost += 6;
  if (season == 'winter' && styles.any((s) => s == 'business' || s == 'elegant')) boost += 6;
  return boost;
}

int _styleBiasBoost({required List<String> styles, required Map<String, int> styleBiasByStyle}) {
  if (styles.isEmpty || styleBiasByStyle.isEmpty) return 0;
  var total = 0;
  for (final style in styles) {
    total += styleBiasByStyle[style.toLowerCase()] ?? 0;
  }
  return (total / styles.length).round();
}

int _recentRepetitionPenalty({required String outfitId, required Map<String, int> lastSeenAtMsByOutfitId}) {
  final seenAt = lastSeenAtMsByOutfitId[outfitId];
  if (seenAt == null) return 0;
  final elapsedDays = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(seenAt)).inDays;
  if (elapsedDays < AppConfig.outfitRecentCooldownDays) return 30;
  return 0;
}

int _freshnessBonus({required String outfitId, required Map<String, int> lastSeenAtMsByOutfitId}) {
  return lastSeenAtMsByOutfitId.containsKey(outfitId) ? 0 : 10;
}

int _dailyVarietyJitter({required String outfitId, required DateTime targetDay}) {
  final dayKey = targetDay.year * 10000 + targetDay.month * 100 + targetDay.day;
  return (outfitId.hashCode ^ dayKey.hashCode).abs() % (AppConfig.outfitDailyVarietyJitterMax + 1);
}

List<String> _sortedReasons(Map<String, int> reasonScores) {
  final entries = reasonScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((e) => e.key).toList();
}

List<_RankedOutfit> _selectDiverseTopOutfits(List<_RankedOutfit> ranked, {required int maxCount}) {
  return ranked.take(maxCount).toList(); // Simplified for now
}

List<_RankedOutfit> _selectCreativeTopOutfits(List<_RankedOutfit> ranked,
    {required int maxCount,
    required DateTime targetDay,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost}) {
  return ranked.take(maxCount).toList(); // Simplified for now
}

List<_Outfit> _applyLlmDetails(List<_Outfit> baseOutfits, Map<String, _OutfitLlmDetails> detailsByOutfitId, {required bool preferLlm}) {
  if (!preferLlm) return baseOutfits;
  return baseOutfits.map((o) {
    final d = detailsByOutfitId[o.id];
    if (d == null) return o;
    return o.copyWith(
      topPiece: d.top ?? o.topPiece,
      bottomPiece: d.bottom ?? o.bottomPiece,
      shoesPiece: d.shoes ?? o.shoesPiece,
      layerPiece: d.outerwear ?? o.layerPiece,
      accessoryPieces: d.accessories.isNotEmpty ? d.accessories : o.accessoryPieces,
      outfitType: d.typeLabel ?? o.outfitType,
      description: d.summary ?? o.description,
    );
  }).toList();
}

// --- Classes and Notifiers ---

class _RankingParams {
  final UserProfile profile;
  final List<AgendaEvent> events;
  final Set<String> favoriteIds;
  final OutfitPersonalizationState personalization;
  final Map<String, double> mlScoreMap;
  final Map<String, _OutfitLlmDetails> llmDetailsByOutfitId;
  final bool secondaryLlmEnabled;
  final DateTime targetDay;
  final _OutfitWeatherContext? weatherContext;
  final bool strictWeatherMode;
  final bool creativeMixEnabled;
  final double creativeExplorationShare;
  final int creativeBoost;
  final Set<String> excludedOutfitIds;
  final DateTime referenceNow;

  const _RankingParams({
    required this.profile, required this.events, required this.favoriteIds,
    required this.personalization, required this.mlScoreMap, required this.llmDetailsByOutfitId,
    required this.secondaryLlmEnabled, required this.targetDay, required this.weatherContext,
    required this.strictWeatherMode, required this.creativeMixEnabled, required this.creativeExplorationShare,
    required this.creativeBoost, required this.excludedOutfitIds, required this.referenceNow,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _RankingParams &&
          profile == other.profile && favoriteIds == other.favoriteIds &&
          personalization == other.personalization && mlScoreMap == other.mlScoreMap &&
          llmDetailsByOutfitId == other.llmDetailsByOutfitId && secondaryLlmEnabled == other.secondaryLlmEnabled &&
          targetDay == other.targetDay && weatherContext == other.weatherContext &&
          strictWeatherMode == other.strictWeatherMode && creativeMixEnabled == other.creativeMixEnabled &&
          creativeExplorationShare == other.creativeExplorationShare && creativeBoost == other.creativeBoost &&
          excludedOutfitIds == other.excludedOutfitIds && referenceNow == other.referenceNow);

  @override
  int get hashCode => Object.hashAll([
    profile, favoriteIds, personalization, mlScoreMap, llmDetailsByOutfitId,
    secondaryLlmEnabled, targetDay, weatherContext, strictWeatherMode, creativeMixEnabled,
    creativeExplorationShare, creativeBoost, excludedOutfitIds, referenceNow,
  ]);
}

final outfitPersonalizationProvider = StateNotifierProvider<OutfitPersonalizationNotifier, OutfitPersonalizationState>((ref) {
  return OutfitPersonalizationNotifier();
});

class OutfitPersonalizationState {
  final Map<String, int> styleBiasByStyle;
  final Map<String, int> outfitBiasById;
  final Map<String, int> lastSeenAtMsByOutfitId;

  const OutfitPersonalizationState({
    required this.styleBiasByStyle, required this.outfitBiasById, required this.lastSeenAtMsByOutfitId,
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
      lastSeenAtMsByOutfitId: lastSeenAtMsByOutfitId ?? this.lastSeenAtMsByOutfitId,
    );
  }
}

class OutfitPersonalizationNotifier extends StateNotifier<OutfitPersonalizationState> {
  OutfitPersonalizationNotifier() : super(const OutfitPersonalizationState.initial()) {
    Future.microtask(_load);
  }

  static const _prefsKey = 'outfit.personalization.v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      Map<String, int> parseIntMap(dynamic input) {
        if (input is! Map) return {};
        return input.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
      }
      state = OutfitPersonalizationState(
        styleBiasByStyle: parseIntMap(decoded['styleBiasByStyle']),
        outfitBiasById: parseIntMap(decoded['outfitBiasById']),
        lastSeenAtMsByOutfitId: parseIntMap(decoded['lastSeenAtMsByOutfitId']),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode({
      'styleBiasByStyle': state.styleBiasByStyle,
      'outfitBiasById': state.outfitBiasById,
      'lastSeenAtMsByOutfitId': state.lastSeenAtMsByOutfitId,
    }));
  }

  Future<void> recordFeedback({required String outfitId, required List<String> styles, required bool positive}) async {
    final nextOutfitBias = Map<String, int>.from(state.outfitBiasById);
    nextOutfitBias[outfitId] = ((nextOutfitBias[outfitId] ?? 0) + (positive ? 10 : -10)).clamp(-40, 40);
    final nextStyleBias = Map<String, int>.from(state.styleBiasByStyle);
    for (final s in styles) {
      final key = s.toLowerCase();
      nextStyleBias[key] = ((nextStyleBias[key] ?? 0) + (positive ? 6 : -6)).clamp(-30, 30);
    }
    state = state.copyWith(outfitBiasById: nextOutfitBias, styleBiasByStyle: nextStyleBias);
    await _save();
  }

  Future<void> markOutfitSeen(String outfitId) async {
    final nextSeen = Map<String, int>.from(state.lastSeenAtMsByOutfitId);
    nextSeen[outfitId] = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(lastSeenAtMsByOutfitId: nextSeen);
    await _save();
  }
}

class OutfitFavoritesNotifier extends StateNotifier<Set<String>> {
  OutfitFavoritesNotifier() : super(<String>{}) {
    Future.microtask(_load);
  }
  static const _prefsKey = 'outfit.favorite.ids';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_prefsKey) ?? []).toSet();
  }

  Future<void> toggleFavorite(String outfitId) async {
    final next = Set<String>.from(state);
    if (next.contains(outfitId)) {
      next.remove(outfitId);
    } else {
      next.add(outfitId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }
}

final outfitFavoritesProvider = StateNotifierProvider<OutfitFavoritesNotifier, Set<String>>((ref) {
  return OutfitFavoritesNotifier();
});

// --- UI Widgets ---

class OutfitSuggestionScreen extends ConsumerWidget {
  const OutfitSuggestionScreen({super.key, this.initialShowFavorites = false});
  final bool initialShowFavorites;

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(userProfileProvider);
    final favoriteIds = ref.watch(outfitFavoritesProvider);
    final personalization = ref.watch(outfitPersonalizationProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final weatherBundleAsync = ref.watch(outfitWeatherBundleProvider);
    final todayEventsAsync = ref.watch(agendaEventsForDayProvider(today));
    final tomorrowEventsAsync = ref.watch(agendaEventsForDayProvider(tomorrow));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'Outfit Suggestions' : 'Suggestions de Tenue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileContext(context, profile, ref),
                const SizedBox(height: 24),
                _buildSuggestionSection(
                  ref: ref, context: context, title: _tr(context, 'Aujourd\'hui', 'Today'),
                  targetDay: today, profile: profile, favoriteIds: favoriteIds,
                  personalization: personalization, eventsAsync: todayEventsAsync,
                  weatherContext: weatherBundleAsync.maybeWhen(data: (b) => _weatherContextFromCurrent(b.currentWeather), orElse: () => null),
                ),
                const SizedBox(height: 24),
                _buildSuggestionSection(
                  ref: ref, context: context, title: _tr(context, 'Demain', 'Tomorrow'),
                  targetDay: tomorrow, profile: profile, favoriteIds: favoriteIds,
                  personalization: personalization, eventsAsync: tomorrowEventsAsync,
                  weatherContext: weatherBundleAsync.maybeWhen(data: (b) => _weatherContextFromForecast(b.tomorrowForecast), orElse: () => null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContext(BuildContext context, UserProfile profile, WidgetRef ref) {
    return GlassContainer(
      borderRadius: 20, blur: 25, opacity: 0.1, padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_tr(context, 'Votre Profil', 'Your Profile'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${profile.gender}, ${profile.age} ${_tr(context, 'ans', 'years')}, ${profile.morphology}', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection({
    required WidgetRef ref, required BuildContext context, required String title,
    required DateTime targetDay, required UserProfile profile, required Set<String> favoriteIds,
    required OutfitPersonalizationState personalization, required AsyncValue<List<AgendaEvent>> eventsAsync,
    required _OutfitWeatherContext? weatherContext,
  }) {
    return eventsAsync.when(
      data: (events) {
        final params = _RankingParams(
          profile: profile, events: events, favoriteIds: favoriteIds, personalization: personalization,
          mlScoreMap: const {}, llmDetailsByOutfitId: const {}, secondaryLlmEnabled: false,
          targetDay: targetDay, weatherContext: weatherContext, strictWeatherMode: true,
          creativeMixEnabled: false, creativeExplorationShare: 0.1, creativeBoost: 10,
          excludedOutfitIds: const {}, referenceNow: DateTime.now(),
        );
        final ranked = ref.watch(rankedOutfitsProvider(params));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...ranked.map((item) => _buildOutfitCard(ref, context, item, isFavorite: favoriteIds.contains(item.outfit.id))),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildOutfitCard(WidgetRef ref, BuildContext context, _RankedOutfit rankedOutfit, {required bool isFavorite}) {
    final outfit = rankedOutfit.outfit;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 16, blur: 20, opacity: 0.1, padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(outfit.icon, color: outfit.color, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(outfit.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(outfit.quickSummary, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pink : Colors.white70),
              onPressed: () => ref.read(outfitFavoritesProvider.notifier).toggleFavorite(outfit.id),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Data Models ---

class _Outfit {
  final String id; final String title; final String description;
  final String topPiece; final String bottomPiece; final String shoesPiece;
  final String layerPiece; final List<String> accessoryPieces;
  final String outfitType; final IconData icon; final Color color;
  final List<String> styles; final List<String> compatibleMorphologies;
  final List<String> genderTargets; final int minAge; final int maxAge;

  const _Outfit({
    required this.id, required this.title, required this.description,
    required this.topPiece, required this.bottomPiece, required this.shoesPiece,
    required this.layerPiece, required this.accessoryPieces, required this.outfitType,
    required this.icon, required this.color, required this.styles,
    required this.compatibleMorphologies, required this.genderTargets,
    required this.minAge, required this.maxAge,
  });

  String get quickSummary => '$topPiece + $bottomPiece';

  _Outfit copyWith({String? topPiece, String? bottomPiece, String? shoesPiece, String? layerPiece, List<String>? accessoryPieces, String? outfitType, String? description}) {
    return _Outfit(
      id: id, title: title, description: description ?? this.description,
      topPiece: topPiece ?? this.topPiece, bottomPiece: bottomPiece ?? this.bottomPiece,
      shoesPiece: shoesPiece ?? this.shoesPiece, layerPiece: layerPiece ?? this.layerPiece,
      accessoryPieces: accessoryPieces ?? this.accessoryPieces, outfitType: outfitType ?? this.outfitType,
      icon: icon, color: color, styles: styles, compatibleMorphologies: compatibleMorphologies,
      genderTargets: genderTargets, minAge: minAge, maxAge: maxAge,
    );
  }
}

class _OutfitLlmDetails {
  final String? top; final String? bottom; final String? shoes; final String? outerwear;
  final List<String> accessories; final String? typeLabel; final String? summary;
  const _OutfitLlmDetails({this.top, this.bottom, this.shoes, this.outerwear, required this.accessories, this.typeLabel, this.summary});
  bool get hasAnyDetail => top != null || bottom != null || shoes != null || outerwear != null || accessories.isNotEmpty || typeLabel != null || summary != null;
}

class _RankedOutfit {
  final _Outfit outfit; final int score; final List<String> reasons;
  const _RankedOutfit({required this.outfit, required this.score, required this.reasons});
}

class _PlanningSignals {
  final bool hasWorkEvent; final bool hasSportEvent; final bool hasEveningEvent;
  final bool hasCasualEvent; final bool hasOutdoorEvent;
  const _PlanningSignals({required this.hasWorkEvent, required this.hasSportEvent, required this.hasEveningEvent, required this.hasCasualEvent, required this.hasOutdoorEvent});
}

enum _DayTimeSlot { morning, afternoon, evening }
enum _PlanningContext { work, sport, evening, casual, mixed, none }

class _OutfitWeatherBundle {
  final WeatherResponse? currentWeather; final ForecastItem? tomorrowForecast;
  const _OutfitWeatherBundle({this.currentWeather, this.tomorrowForecast});
}

class _OutfitWeatherContext {
  final String label; final double temperature; final int humidity; final double windSpeed; final String main;
  const _OutfitWeatherContext({required this.label, required this.temperature, required this.humidity, required this.windSpeed, required this.main});
}

class _ForecastCoordinates {
  final double lat; final double lon;
  const _ForecastCoordinates({required this.lat, required this.lon});
}

// --- Helpers (Weather & Geo) ---

Future<_ForecastCoordinates> _resolveForecastCoordinates() async {
  try {
    final permission = await Geolocator.checkPermission();
    var granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    if (!granted) {
      final req = await Geolocator.requestPermission();
      granted = req == LocationPermission.always || req == LocationPermission.whileInUse;
    }
    if (granted) {
      const settings = LocationSettings(accuracy: LocationAccuracy.medium);
      final pos = await Geolocator.getCurrentPosition(locationSettings: settings);
      return _ForecastCoordinates(lat: pos.latitude, lon: pos.longitude);
    }
  } catch (_) {}
  return const _ForecastCoordinates(lat: -18.8792, lon: 47.5079);
}

ForecastItem? _pickTomorrowForecast(List<ForecastItem> forecasts) {
  if (forecasts.isEmpty) return null;
  return forecasts.first;
}

_OutfitWeatherContext? _weatherContextFromCurrent(WeatherResponse? weather) {
  if (weather == null) return null;
  return _OutfitWeatherContext(
    label: '${weather.description} ${weather.temperature}°C',
    temperature: weather.temperature, humidity: weather.humidity,
    windSpeed: weather.windSpeed, main: weather.main,
  );
}

_OutfitWeatherContext? _weatherContextFromForecast(ForecastItem? forecast) {
  if (forecast == null) return null;
  return _OutfitWeatherContext(
    label: '${forecast.description} ${forecast.temperature}°C',
    temperature: forecast.temperature, humidity: 0,
    windSpeed: forecast.windSpeed, main: forecast.main,
  );
}
