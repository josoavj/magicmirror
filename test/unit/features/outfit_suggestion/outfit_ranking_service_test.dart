import 'package:flutter_test/flutter_test.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/services/outfit_ranking_service.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';

void main() {
  late OutfitRankingService rankingService;

  setUp(() {
    rankingService = OutfitRankingService();
  });

  group('OutfitRankingService', () {
    final defaultProfile = UserProfile.defaults();
    final today = DateTime(2026, 7, 28);
    final referenceNow = DateTime(2026, 7, 28, 10, 0);

    test('should rank business outfits higher if there is a work event', () {
      final events = [
        AgendaEvent(
          id: 'e1',
          userId: 'u1',
          title: 'Réunion client',
          eventType: 'Work',
          startTime: DateTime(2026, 7, 28, 14, 0),
          endTime: DateTime(2026, 7, 28, 15, 0),
        ),
      ];

      final params = RankingParams(
        profile: defaultProfile,
        events: events,
        favoriteIds: {},
        personalization: const OutfitPersonalizationState.initial(),
        mlScoreMap: {},
        llmDetailsByOutfitId: {},
        secondaryLlmEnabled: false,
        targetDay: today,
        weatherContext: null,
        strictWeatherMode: true,
        creativeMixEnabled: false,
        creativeExplorationShare: 0.1,
        creativeBoost: 10,
        excludedOutfitIds: {},
        referenceNow: referenceNow,
      );

      final results = rankingService.rankOutfits(params);

      expect(results.first.outfit.id, anyOf('business_smart', 'elegant'));
      expect(results.first.reasons, contains('Compatible avec votre planning pro'));
    });

    test('should rank sport outfits higher if there is a sport event', () {
      final events = [
        AgendaEvent(
          id: 'e2',
          userId: 'u1',
          title: 'Séance Gym',
          eventType: 'Sport',
          startTime: DateTime(2026, 7, 28, 18, 0),
          endTime: DateTime(2026, 7, 28, 19, 0),
        ),
      ];

      final params = RankingParams(
        profile: defaultProfile,
        events: events,
        favoriteIds: {},
        personalization: const OutfitPersonalizationState.initial(),
        mlScoreMap: {},
        llmDetailsByOutfitId: {},
        secondaryLlmEnabled: false,
        targetDay: today,
        weatherContext: null,
        strictWeatherMode: true,
        creativeMixEnabled: false,
        creativeExplorationShare: 0.1,
        creativeBoost: 10,
        excludedOutfitIds: {},
        referenceNow: referenceNow,
      );

      final results = rankingService.rankOutfits(params);

      final sportOutfit = results.firstWhere((r) => r.outfit.id == 'sport');
      expect(sportOutfit.score, greaterThan(0));
      expect(sportOutfit.reasons, contains('Compatible avec vos activités sportives'));
    });

    test('should apply weather boost for casual styles in hot weather', () {
      final hotWeather = OutfitWeatherContext(
        label: 'Sunny',
        temperature: 32,
        humidity: 40,
        windSpeed: 5,
        main: 'Clear',
      );

      final params = RankingParams(
        profile: defaultProfile,
        events: [],
        favoriteIds: {},
        personalization: const OutfitPersonalizationState.initial(),
        mlScoreMap: {},
        llmDetailsByOutfitId: {},
        secondaryLlmEnabled: false,
        targetDay: today,
        weatherContext: hotWeather,
        strictWeatherMode: true,
        creativeMixEnabled: false,
        creativeExplorationShare: 0.1,
        creativeBoost: 10,
        excludedOutfitIds: {},
        referenceNow: referenceNow,
      );

      final results = rankingService.rankOutfits(params);
      
      final casualOutfit = results.firstWhere((r) => r.outfit.id == 'casual_moderne');
      expect(casualOutfit.reasons, contains('Adapté aux conditions météo'));
    });
  });
}
