import 'package:flutter/material.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';

class OutfitRankingService {
  List<RankedOutfit> rankOutfits(RankingParams params) {
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
      const Outfit(
        id: 'casual_moderne',
        title: 'Casual Moderne',
        description: 'Jeans + T-shirt léger',
        topPiece: 'T-shirt léger uni',
        bottomPiece: 'Jeans coupe droite',
        shoesPiece: 'Sneakers blanches',
        layerPiece: 'Surchemise légère',
        accessoryPieces: ['Montre minimaliste'],
        outfitType: 'Casual quotidien',
        icon: Icons.auto_awesome_mosaic,
        color: Color(0xFF3B82F6),
        styles: ['casual', 'minimaliste'],
        compatibleMorphologies: [
          'Silhouette droite',
          'Hanches et épaules équilibrées',
        ],
        genderTargets: ['all'],
        minAge: 16,
        maxAge: 60,
      ),
      const Outfit(
        id: 'elegant',
        title: 'Élégant',
        description: 'Chemise + Pantalon chino',
        topPiece: 'Chemise structurée',
        bottomPiece: 'Pantalon chino fuselé',
        shoesPiece: 'Derbies en cuir',
        layerPiece: 'Blazer léger',
        accessoryPieces: ['Ceinture cuir'],
        outfitType: 'Smart élégant',
        icon: Icons.style,
        color: Color(0xFF8B5CF6),
        styles: ['elegant', 'business'],
        compatibleMorphologies: [
          'Hanches et épaules équilibrées',
          'Épaules plus larges',
        ],
        genderTargets: ['all'],
        minAge: 20,
        maxAge: 65,
      ),
      const Outfit(
        id: 'sport',
        title: 'Sport',
        description: 'Legging + Hoodie',
        topPiece: 'Hoodie respirant',
        bottomPiece: 'Legging technique',
        shoesPiece: 'Running trainers',
        layerPiece: 'Coupe-vent fin',
        accessoryPieces: ['Casquette'],
        outfitType: 'Sport actif',
        icon: Icons.sports,
        color: Color(0xFF10B981),
        styles: ['sport'],
        compatibleMorphologies: [
          'Hanches plus marquées',
          'Taille très marquée',
          'Silhouette droite',
        ],
        genderTargets: ['all'],
        minAge: 12,
        maxAge: 50,
      ),
      const Outfit(
        id: 'street_dynamics',
        title: 'Street Dynamics',
        description: 'Cargo + bomber oversize',
        topPiece: 'T-shirt graphique',
        bottomPiece: 'Cargo ample',
        shoesPiece: 'Sneakers chunky',
        layerPiece: 'Bomber oversize',
        accessoryPieces: ['Chaîne discrète'],
        outfitType: 'Streetwear urbain',
        icon: Icons.local_fire_department,
        color: Color(0xFFEC4899),
        styles: ['streetwear', 'casual'],
        compatibleMorphologies: [
          'Épaules très marquées',
          'Silhouette droite',
        ],
        genderTargets: ['all'],
        minAge: 14,
        maxAge: 40,
      ),
      const Outfit(
        id: 'business_smart',
        title: 'Business Smart',
        description: 'Blazer + pantalon taille haute',
        topPiece: 'Top soyeux sobre',
        bottomPiece: 'Pantalon taille haute',
        shoesPiece: 'Mocassins premium',
        layerPiece: 'Blazer structuré',
        accessoryPieces: ['Sac structuré'],
        outfitType: 'Business smart',
        icon: Icons.business_center,
        color: Color(0xFFF59E0B),
        styles: ['business', 'elegant'],
        compatibleMorphologies: [
          'Hanches très marquées',
          'Hanches et épaules équilibrées',
          'Épaules plus larges',
        ],
        genderTargets: ['all'],
        minAge: 24,
        maxAge: 70,
      ),
      const Outfit(
        id: 'minimal_monochrome',
        title: 'Minimal Monochrome',
        description: 'Palette neutre + coupe clean',
        topPiece: 'Pull fin monochrome',
        bottomPiece: 'Pantalon droit neutre',
        shoesPiece: 'Baskets épurées',
        layerPiece: 'Manteau droit léger',
        accessoryPieces: ['Sac crossbody'],
        outfitType: 'Minimal contemporain',
        icon: Icons.layers,
        color: Color(0xFF14B8A6),
        styles: ['minimaliste', 'casual'],
        compatibleMorphologies: ['all'],
        genderTargets: ['all'],
        minAge: 18,
        maxAge: 80,
      ),
    ];

    final allOutfits = applyLlmDetails(
      baseOutfits,
      llmDetailsByOutfitId,
      preferLlm: secondaryLlmEnabled,
    );

    final normalizedStyles = profile.preferredStyles.map(normalizeStyle).toSet();
    final normalizedGender = profile.gender.toLowerCase();
    final planningSignals = extractPlanningSignals(events);
    final isWeekend = checkIsWeekend(targetDay);
    final prioritySlot = resolvePrioritySlot(events, referenceNow);
    final primaryContext = resolvePrimaryContext(events, referenceNow);
    final season = seasonFromMonth(targetDay.month);
    final localHourSlot = getLocalHourSlotLabel(referenceNow.hour);

    var candidates = allOutfits.where((outfit) {
      final ageOk = profile.age >= outfit.minAge && profile.age <= outfit.maxAge;
      final morphologyOk = isMorphologyCompatible(profile.morphology, outfit);
      return ageOk && morphologyOk;
    }).toList();

    final strictCandidates = candidates.where((outfit) {
      return passesHardConstraints(
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
      return isContextCompatible(primaryContext, outfit.styles);
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
      final contextCompatible =
          isContextCompatible(primaryContext, outfit.styles);

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
        final topStyle = normalizeStyle(profile.preferredStyles.first);
        if (outfit.styles.contains(topStyle)) {
          score += 18;
          addReason('Aligne avec votre style principal', 110);
        }
      }

      if (profile.age >= outfit.minAge && profile.age <= outfit.maxAge) {
        score += 24;
        addReason('Adapté à votre tranche d\'âge', 40);
      }

      if (matchesMorphology(
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
      if (isGenderMatch) score += 12;

      if (contextCompatible) {
        score += 24;
        addReason('Adapté à votre contexte principal', 90);
      } else {
        score -= 12;
      }

      final planningCoherence = planningCoherenceBoost(
        planningSignals: planningSignals,
        primaryContext: primaryContext,
        styles: outfit.styles,
      );
      score += planningCoherence.round();
      if (planningCoherence > 0) {
        addReason('Cohérence avec vos priorités du jour', 88);
      }

      if (isWeekend &&
          outfit.styles.any(
            (style) =>
                style == 'casual' || style == 'streetwear' || style == 'sport',
          )) {
        score += 12;
        addReason('Adapté au rythme du week-end', 35);
      }

      if (!isWeekend &&
          outfit.styles.any(
            (style) => style == 'business' || style == 'elegant',
          )) {
        score += 12;
        addReason('Adapté à une journée de semaine', 35);
      }

      if (planningSignals.hasWorkEvent &&
          outfit.styles.any(
            (style) => style == 'business' || style == 'elegant',
          )) {
        score += 30;
        addReason('Compatible avec votre planning pro', 105);
      }

      if (planningSignals.hasSportEvent && outfit.styles.contains('sport')) {
        score += 30;
        addReason('Compatible avec vos activités sportives', 105);
      }

      if (planningSignals.hasEveningEvent &&
          outfit.styles.any(
            (style) => style == 'elegant' || style == 'streetwear',
          )) {
        score += 16;
        addReason('Adapté à vos sorties du soir', 65);
      }

      final slotBoost = slotScoreBoost(prioritySlot, outfit.styles);
      if (slotBoost > 0) {
        score += slotBoost;
        addReason(
          'Optimisé pour le créneau ${slotLabel(prioritySlot).toLowerCase()}',
          50,
        );
      }

      final weatherBoost = weatherScoreBoost(
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

      final chronoBoost = seasonRainHourBoost(
        weather: weatherContext,
        styles: outfit.styles,
        season: season,
        localHourSlot: localHourSlot,
      );
      if (chronoBoost > 0) {
        score += chronoBoost;
        addReason('Adapté à la saison et au moment de la journée', 72);
      }

      final styleBias = styleBiasBoost(
        styles: outfit.styles,
        styleBiasByStyle: personalization.styleBiasByStyle,
      );
      score += styleBias;
      if (styleBias > 0) addReason('Affinite apprenue avec vos styles', 92);

      final outfitBias = personalization.outfitBiasById[outfit.id] ?? 0;
      score += outfitBias;
      if (outfitBias > 0) addReason('Feedback positif précédent', 84);

      final repetitionPenalty = recentRepetitionPenalty(
        outfitId: outfit.id,
        lastSeenAtMsByOutfitId: personalization.lastSeenAtMsByOutfitId,
      );
      score -= repetitionPenalty;
      if (repetitionPenalty > 0) addReason('Rotation anti-répétition', 52);

      final freshnessBonusValue = freshnessBonus(
        outfitId: outfit.id,
        lastSeenAtMsByOutfitId: personalization.lastSeenAtMsByOutfitId,
      );
      score += freshnessBonusValue;
      if (freshnessBonusValue > 0) {
        addReason('Favorise des tenues moins récentes', 58);
      }

      final dailyVarietyJitterValue = dailyVarietyJitter(
        outfitId: outfit.id,
        targetDay: targetDay,
      );
      score += dailyVarietyJitterValue;
      if (dailyVarietyJitterValue > 0) {
        addReason('Rotation douce entre tenues proches', 36);
      }

      final mlScore = mlScoreMap[outfit.id];
      if (AppConfig.enableHybridMlRanking && mlScore != null) {
        score =
            ((1 - AppConfig.hybridMlWeight) * score +
                    AppConfig.hybridMlWeight * (mlScore * 100))
                .round();
        addReason('Calibration ML hybride', 86);
      }

      if (score < 0) score = 0;
      final reasons = sortedReasons(reasonScores);
      return RankedOutfit(outfit: outfit, score: score, reasons: reasons);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    final diversePool = selectDiverseTopOutfits(
      ranked,
      maxCount: ranked.length < 8 ? ranked.length : 8,
    );

    return selectCreativeTopOutfits(
      diversePool,
      maxCount: 4,
      targetDay: targetDay,
      creativeMixEnabled: creativeMixEnabled,
      creativeExplorationShare: creativeExplorationShare,
      creativeBoost: creativeBoost,
    );
  }

  List<String> parseAccessories(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final value = raw.toString().trim();
    if (value.isEmpty) return const <String>[];
    final splitter = value.contains('|') ? '|' : ',';
    return value
        .split(splitter)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  bool llamaRowMatchesProfile(
    Map<String, dynamic> row, {
    required UserProfile profile,
    required bool useProfileContext,
    required bool strictGenderFilter,
  }) {
    if (!useProfileContext) return true;
    final payload = row['profile_payload'];
    final payloadMap =
        payload is Map<String, dynamic> ? payload : <String, dynamic>{};
    final rowGenderRaw =
        row['target_gender'] ??
        row['gender_target'] ??
        row['profile_gender'] ??
        payloadMap['gender'];
    final rowGender = rowGenderRaw?.toString().trim() ?? '';
    if (strictGenderFilter && rowGender.isNotEmpty) {
      if (!genderMatchesProfile(rowGender, profile.gender)) return false;
    }
    final rowStyles = toNormalizedStringSet(
      row['target_styles'] ??
          payloadMap['preferredStyles'] ??
          payloadMap['styles'],
    );
    final profileStyles = toNormalizedStringSet(profile.preferredStyles);
    if (rowStyles.isNotEmpty && profileStyles.isNotEmpty) {
      if (!rowStyles.any(profileStyles.contains)) return false;
    }
    final rowMorphologyRaw = row['target_morphology'] ?? payloadMap['morphology'];
    final rowMorphology = rowMorphologyRaw?.toString().trim() ?? '';
    if (rowMorphology.isNotEmpty &&
        !normalizeToken(rowMorphology).contains(normalizeToken(profile.morphology)) &&
        !normalizeToken(profile.morphology).contains(normalizeToken(rowMorphology))) {
      return false;
    }
    return true;
  }

  bool genderMatchesProfile(String targetGender, String profileGender) {
    final target = normalizeToken(targetGender);
    final profile = normalizeToken(profileGender);
    if (target.isEmpty || target == 'all' || target == 'any' || target == 'unisex') {
      return true;
    }
    if (target.contains('nonprecise') || target.contains('nonbinaire')) return true;
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

  Set<String> toNormalizedStringSet(dynamic raw) {
    if (raw == null) return <String>{};
    if (raw is List) {
      return raw
          .map((item) => normalizeToken(item.toString()))
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    final value = raw.toString().trim();
    if (value.isEmpty) return <String>{};
    final splitter =
        value.contains('|') ? '|' : (value.contains(',') ? ',' : ' ');
    return value
        .split(splitter)
        .map(normalizeToken)
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  String normalizeToken(String value) {
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

  String normalizeStyle(String value) {
    final v = value.toLowerCase();
    if (v.contains('eleg')) return 'elegant';
    if (v.contains('mini')) return 'minimaliste';
    return v;
  }

  PlanningSignals extractPlanningSignals(List<AgendaEvent> events) {
    var hasWorkEvent = false;
    var hasSportEvent = false;
    var hasEveningEvent = false;
    var hasCasualEvent = false;
    var hasOutdoorEvent = false;

    for (final event in events) {
      if (event.isCompleted) continue;
      final eventBlob =
          '${event.eventType} ${event.title} ${event.description ?? ''}'
              .toLowerCase();

      if (containsAny(
        eventBlob,
        const ['work', 'travail', 'reunion', 'meeting', 'bureau', 'business'],
      )) {
        hasWorkEvent = true;
      }
      if (containsAny(
        eventBlob,
        const ['sport', 'gym', 'run', 'course', 'training'],
      )) {
        hasSportEvent = true;
      }
      if (containsAny(
        eventBlob,
        const ['soiree', 'soir', 'diner', 'resto', 'event', 'sortie'],
      )) {
        hasEveningEvent = true;
      }
      if (containsAny(
        eventBlob,
        const [
          'amis',
          'detente',
          'shopping',
          'promenade',
          'famille',
          'loisir',
          'casual',
        ],
      )) {
        hasCasualEvent = true;
      }
      if (containsAny(
        eventBlob,
        const [
          'exterieur',
          'outdoor',
          'marche',
          'balade',
          'deplacement',
        ],
      )) {
        hasOutdoorEvent = true;
      }
      if (event.startTime.hour >= 18) hasEveningEvent = true;
    }
    return PlanningSignals(
      hasWorkEvent: hasWorkEvent,
      hasSportEvent: hasSportEvent,
      hasEveningEvent: hasEveningEvent,
      hasCasualEvent: hasCasualEvent,
      hasOutdoorEvent: hasOutdoorEvent,
    );
  }

  bool containsAny(String source, List<String> keywords) {
    return keywords.any((k) => source.contains(k));
  }

  bool checkIsWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  DayTimeSlot resolvePrioritySlot(List<AgendaEvent> events, DateTime now) {
    final pending = events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (final event in pending) {
      if (!event.endTime.isBefore(now)) return slotFromHour(event.startTime.hour);
    }
    return slotFromHour(now.hour);
  }

  DayTimeSlot slotFromHour(int hour) {
    if (hour < 12) return DayTimeSlot.morning;
    if (hour < 18) return DayTimeSlot.afternoon;
    return DayTimeSlot.evening;
  }

  PlanningContext resolvePrimaryContext(
    List<AgendaEvent> events,
    DateTime referenceNow,
  ) {
    final pending = events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (final event in pending) {
      if (!event.endTime.isBefore(referenceNow)) return contextFromEvent(event);
    }
    if (pending.isNotEmpty) return contextFromEvent(pending.first);
    return PlanningContext.none;
  }

  PlanningContext contextFromEvent(AgendaEvent event) {
    final blob =
        '${event.eventType} ${event.title} ${event.description ?? ''}'
            .toLowerCase();
    if (containsAny(
      blob,
      const ['work', 'travail', 'meeting', 'reunion', 'business'],
    )) {
      return PlanningContext.work;
    }
    if (containsAny(blob, const ['sport', 'gym', 'training', 'fitness', 'run'])) {
      return PlanningContext.sport;
    }
    if (containsAny(blob, const ['soir', 'soiree', 'diner', 'event', 'sortie'])) {
      return PlanningContext.evening;
    }
    if (containsAny(
      blob,
      const ['detente', 'famille', 'amis', 'shopping', 'loisir'],
    )) {
      return PlanningContext.casual;
    }
    return PlanningContext.mixed;
  }

  String seasonFromMonth(int month) {
    if (month == 12 || month <= 2) return 'winter';
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    return 'autumn';
  }

  String getLocalHourSlotLabel(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  bool isMorphologyCompatible(String morphology, Outfit outfit) {
    final normalized = morphology.trim().toLowerCase();
    if (normalized.contains('non definie') ||
        normalized.contains('non définie')) {
      return true;
    }
    return matchesMorphology(
      profileMorphology: morphology,
      compatibleMorphologies: outfit.compatibleMorphologies,
    );
  }

  bool matchesMorphology({
    required String profileMorphology,
    required List<String> compatibleMorphologies,
  }) {
    if (compatibleMorphologies.contains('all')) return true;
    final normalizedProfile = normalizeToken(profileMorphology);
    return compatibleMorphologies.any((m) {
      if (m == 'all') return true;
      final normalizedCompatible = normalizeToken(m);
      return normalizedProfile.contains(normalizedCompatible) ||
          normalizedCompatible.contains(normalizedProfile);
    });
  }

  Set<String> morphologyAliases(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'Sablier (X)':
      case 'Hanches et épaules équilibrées':
        return {
          'Sablier (X)',
          'Hanches et épaules équilibrées',
          'Hanches et epaules equilibrees',
        };
      case 'Poire (A)':
      case 'Hanches plus marquées':
        return {
          'Poire (A)',
          'Hanches plus marquées',
          'Hanches plus marquees',
        };
      case 'Rectangulaire (H)':
      case 'Silhouette droite':
        return {'Rectangulaire (H)', 'Silhouette droite'};
      case 'Triangle Inverse (V)':
      case 'Épaules plus larges':
        return {
          'Triangle Inverse (V)',
          'Épaules plus larges',
          'Epaules plus larges',
        };
      default:
        return {normalized};
    }
  }

  bool passesHardConstraints({
    required Outfit outfit,
    required OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required PlanningSignals planningSignals,
    required PlanningContext primaryContext,
  }) {
    final styles = outfit.styles;
    final enforceWorkGate =
        (planningSignals.hasWorkEvent || primaryContext == PlanningContext.work) &&
            !planningSignals.hasSportEvent &&
            primaryContext != PlanningContext.mixed;
    if (enforceWorkGate &&
        !styles.any((s) => s == 'business' || s == 'elegant')) {
      return false;
    }

    if (weatherContext == null || !strictWeatherMode) return true;
    final main = weatherContext.main.toLowerCase();
    final isRainy =
        main.contains('rain') || main.contains('thunder') || main.contains('snow');
    if (isRainy && styles.contains('streetwear') && !styles.contains('business')) {
      return false;
    }
    if (weatherContext.temperature >= 31 &&
        styles.contains('business') &&
        !styles.contains('casual')) {
      return false;
    }
    if (weatherContext.temperature <= 8 &&
        styles.length == 1 &&
        styles.contains('sport')) {
      return false;
    }
    return true;
  }

  bool isContextCompatible(PlanningContext context, List<String> styles) {
    switch (context) {
      case PlanningContext.work:
        return styles.any((s) => s == 'business' || s == 'elegant');
      case PlanningContext.sport:
        return styles.contains('sport');
      case PlanningContext.evening:
        return styles.any((s) => s == 'elegant' || s == 'streetwear');
      case PlanningContext.casual:
        return styles.any(
          (s) => s == 'casual' || s == 'minimaliste' || s == 'streetwear',
        );
      case PlanningContext.mixed:
        return styles.any(
          (s) => s == 'casual' || s == 'minimaliste' || s == 'business',
        );
      case PlanningContext.none:
        return true;
    }
  }

  double planningCoherenceBoost({
    required PlanningSignals planningSignals,
    required PlanningContext primaryContext,
    required List<String> styles,
  }) {
    var boost = 0.0;
    if (primaryContext == PlanningContext.work) {
      boost += styles.any((s) => s == 'business' || s == 'elegant') ? 8 : -8;
    }
    if (primaryContext == PlanningContext.sport) {
      boost += styles.contains('sport') ? 8 : -8;
    }
    return boost;
  }

  int slotScoreBoost(DayTimeSlot slot, List<String> styles) {
    switch (slot) {
      case DayTimeSlot.morning:
        return styles.any((s) => s == 'business' || s == 'minimaliste') ? 14 : 0;
      case DayTimeSlot.afternoon:
        return styles.any((s) => s == 'casual' || s == 'streetwear') ? 12 : 0;
      case DayTimeSlot.evening:
        return styles.any((s) => s == 'elegant' || s == 'streetwear') ? 16 : 0;
    }
  }

  String slotLabel(DayTimeSlot slot) {
    switch (slot) {
      case DayTimeSlot.morning:
        return 'Matin';
      case DayTimeSlot.afternoon:
        return 'Après-midi';
      case DayTimeSlot.evening:
        return 'Soirée';
    }
  }

  int weatherScoreBoost(
    OutfitWeatherContext? weather,
    List<String> styles, {
    required bool strictWeatherMode,
  }) {
    if (weather == null) return 0;
    var boost = 0;
    if (weather.temperature >= 28 &&
        styles.any((s) => s == 'casual' || s == 'minimaliste')) {
      boost += 14;
    }
    if (weather.temperature <= 16 &&
        styles.any((s) => s == 'business' || s == 'elegant')) {
      boost += 12;
    }
    return boost;
  }

  int seasonRainHourBoost({
    required OutfitWeatherContext? weather,
    required List<String> styles,
    required String season,
    required String localHourSlot,
  }) {
    var boost = 0;
    if (season == 'summer' &&
        styles.any((s) => s == 'casual' || s == 'minimaliste')) {
      boost += 6;
    }
    if (season == 'winter' &&
        styles.any((s) => s == 'business' || s == 'elegant')) {
      boost += 6;
    }
    return boost;
  }

  int styleBiasBoost({
    required List<String> styles,
    required Map<String, int> styleBiasByStyle,
  }) {
    if (styles.isEmpty || styleBiasByStyle.isEmpty) return 0;
    var total = 0;
    for (final style in styles) {
      total += styleBiasByStyle[style.toLowerCase()] ?? 0;
    }
    return (total / styles.length).round();
  }

  int recentRepetitionPenalty({
    required String outfitId,
    required Map<String, int> lastSeenAtMsByOutfitId,
  }) {
    final seenAt = lastSeenAtMsByOutfitId[outfitId];
    if (seenAt == null) return 0;
    final elapsedDays = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(seenAt))
        .inDays;
    if (elapsedDays < AppConfig.outfitRecentCooldownDays) return 30;
    return 0;
  }

  int freshnessBonus({
    required String outfitId,
    required Map<String, int> lastSeenAtMsByOutfitId,
  }) {
    return lastSeenAtMsByOutfitId.containsKey(outfitId) ? 0 : 10;
  }

  int dailyVarietyJitter({
    required String outfitId,
    required DateTime targetDay,
  }) {
    final dayKey =
        targetDay.year * 10000 + targetDay.month * 100 + targetDay.day;
    return (outfitId.hashCode ^ dayKey.hashCode).abs() %
        (AppConfig.outfitDailyVarietyJitterMax + 1);
  }

  List<String> sortedReasons(Map<String, int> reasonScores) {
    final entries = reasonScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<RankedOutfit> selectDiverseTopOutfits(
    List<RankedOutfit> ranked, {
    required int maxCount,
  }) {
    return ranked.take(maxCount).toList(); // Simplified for now
  }

  List<RankedOutfit> selectCreativeTopOutfits(
    List<RankedOutfit> ranked, {
    required int maxCount,
    required DateTime targetDay,
    required bool creativeMixEnabled,
    required double creativeExplorationShare,
    required int creativeBoost,
  }) {
    return ranked.take(maxCount).toList(); // Simplified for now
  }

  List<Outfit> applyLlmDetails(
    List<Outfit> baseOutfits,
    Map<String, OutfitLlmDetails> detailsByOutfitId, {
    required bool preferLlm,
  }) {
    if (!preferLlm) return baseOutfits;
    return baseOutfits.map((o) {
      final d = detailsByOutfitId[o.id];
      if (d == null) return o;
      return o.copyWith(
        topPiece: d.top ?? o.topPiece,
        bottomPiece: d.bottom ?? o.bottomPiece,
        shoesPiece: d.shoes ?? o.shoesPiece,
        layerPiece: d.outerwear ?? o.layerPiece,
        accessoryPieces:
            d.accessories.isNotEmpty ? d.accessories : o.accessoryPieces,
        outfitType: d.typeLabel ?? o.outfitType,
        description: d.summary ?? o.description,
      );
    }).toList();
  }

  static OutfitWeatherContext? weatherContextFromCurrent(
    WeatherResponse? weather,
  ) {
    if (weather == null) return null;
    return OutfitWeatherContext(
      label: '${weather.description} ${weather.temperature}°C',
      temperature: weather.temperature,
      humidity: weather.humidity,
      windSpeed: weather.windSpeed,
      main: weather.main,
    );
  }

  static OutfitWeatherContext? weatherContextFromForecast(
    ForecastItem? forecast,
  ) {
    if (forecast == null) return null;
    return OutfitWeatherContext(
      label: '${forecast.description} ${forecast.temperature}°C',
      temperature: forecast.temperature,
      humidity: 0,
      windSpeed: forecast.windSpeed,
      main: forecast.main,
    );
  }
}
