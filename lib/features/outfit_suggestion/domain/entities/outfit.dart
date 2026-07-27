import 'package:flutter/material.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';

class Outfit {
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

  const Outfit({
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

  String get quickSummary => '$topPiece + $bottomPiece';

  Outfit copyWith({
    String? topPiece,
    String? bottomPiece,
    String? shoesPiece,
    String? layerPiece,
    List<String>? accessoryPieces,
    String? outfitType,
    String? description,
  }) {
    return Outfit(
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

class OutfitLlmDetails {
  final String? top;
  final String? bottom;
  final String? shoes;
  final String? outerwear;
  final List<String> accessories;
  final String? typeLabel;
  final String? summary;

  const OutfitLlmDetails({
    this.top,
    this.bottom,
    this.shoes,
    this.outerwear,
    required this.accessories,
    this.typeLabel,
    this.summary,
  });

  bool get hasAnyDetail =>
      top != null ||
      bottom != null ||
      shoes != null ||
      outerwear != null ||
      accessories.isNotEmpty ||
      typeLabel != null ||
      summary != null;
}

class RankedOutfit {
  final Outfit outfit;
  final int score;
  final List<String> reasons;

  const RankedOutfit({
    required this.outfit,
    required this.score,
    required this.reasons,
  });
}

class PlanningSignals {
  final bool hasWorkEvent;
  final bool hasSportEvent;
  final bool hasEveningEvent;
  final bool hasCasualEvent;
  final bool hasOutdoorEvent;

  const PlanningSignals({
    required this.hasWorkEvent,
    required this.hasSportEvent,
    required this.hasEveningEvent,
    required this.hasCasualEvent,
    required this.hasOutdoorEvent,
  });
}

enum DayTimeSlot { morning, afternoon, evening }

enum PlanningContext { work, sport, evening, casual, mixed, none }

class OutfitWeatherBundle {
  final WeatherResponse? currentWeather;
  final ForecastItem? tomorrowForecast;

  const OutfitWeatherBundle({this.currentWeather, this.tomorrowForecast});
}

class OutfitWeatherContext {
  final String label;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String main;

  const OutfitWeatherContext({
    required this.label,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.main,
  });
}

class ForecastCoordinates {
  final double lat;
  final double lon;

  const ForecastCoordinates({required this.lat, required this.lon});
}

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

class RankingParams {
  final UserProfile profile;
  final List<AgendaEvent> events;
  final Set<String> favoriteIds;
  final OutfitPersonalizationState personalization;
  final Map<String, double> mlScoreMap;
  final Map<String, OutfitLlmDetails> llmDetailsByOutfitId;
  final bool secondaryLlmEnabled;
  final DateTime targetDay;
  final OutfitWeatherContext? weatherContext;
  final bool strictWeatherMode;
  final bool creativeMixEnabled;
  final double creativeExplorationShare;
  final int creativeBoost;
  final Set<String> excludedOutfitIds;
  final DateTime referenceNow;

  const RankingParams({
    required this.profile,
    required this.events,
    required this.favoriteIds,
    required this.personalization,
    required this.mlScoreMap,
    required this.llmDetailsByOutfitId,
    required this.secondaryLlmEnabled,
    required this.targetDay,
    required this.weatherContext,
    required this.strictWeatherMode,
    required this.creativeMixEnabled,
    required this.creativeExplorationShare,
    required this.creativeBoost,
    required this.excludedOutfitIds,
    required this.referenceNow,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RankingParams &&
          profile == other.profile &&
          favoriteIds == other.favoriteIds &&
          personalization == other.personalization &&
          mlScoreMap == other.mlScoreMap &&
          llmDetailsByOutfitId == other.llmDetailsByOutfitId &&
          secondaryLlmEnabled == other.secondaryLlmEnabled &&
          targetDay == other.targetDay &&
          weatherContext == other.weatherContext &&
          strictWeatherMode == other.strictWeatherMode &&
          creativeMixEnabled == other.creativeMixEnabled &&
          creativeExplorationShare == other.creativeExplorationShare &&
          creativeBoost == other.creativeBoost &&
          excludedOutfitIds == other.excludedOutfitIds &&
          referenceNow == other.referenceNow);

  @override
  int get hashCode => Object.hashAll([
    profile,
    favoriteIds,
    personalization,
    mlScoreMap,
    llmDetailsByOutfitId,
    secondaryLlmEnabled,
    targetDay,
    weatherContext,
    strictWeatherMode,
    creativeMixEnabled,
    creativeExplorationShare,
    creativeBoost,
    excludedOutfitIds,
    referenceNow,
  ]);
}
