import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_list_card.dart';

class OutfitSuggestionSection extends ConsumerWidget {
  final String title;
  final DateTime targetDay;
  final UserProfile profile;
  final Set<String> favoriteIds;
  final OutfitPersonalizationState personalization;
  final AsyncValue<List<AgendaEvent>> eventsAsync;
  final OutfitWeatherContext? weatherContext;

  const OutfitSuggestionSection({
    super.key,
    required this.title,
    required this.targetDay,
    required this.profile,
    required this.favoriteIds,
    required this.personalization,
    required this.eventsAsync,
    this.weatherContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimisation : arrondir l'heure au quart d'heure le plus proche pour maximiser le cache Riverpod
    final now = DateTime.now();
    final minutes = (now.minute / 15).round() * 15;
    final roundedNow = DateTime(now.year, now.month, now.day, now.hour, minutes);

    return eventsAsync.when(
      data: (events) {
        final params = RankingParams(
          profile: profile,
          events: events,
          favoriteIds: favoriteIds,
          personalization: personalization,
          mlScoreMap: const {},
          llmDetailsByOutfitId: const {},
          secondaryLlmEnabled: false,
          targetDay: targetDay,
          weatherContext: weatherContext,
          strictWeatherMode: true,
          creativeMixEnabled: false,
          creativeExplorationShare: 0.1,
          creativeBoost: 10,
          excludedOutfitIds: const {},
          referenceNow: roundedNow,
        );
        final ranked = ref.watch(rankedOutfitsProvider(params));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...ranked.map(
              (item) => OutfitListCard(
                rankedOutfit: item,
                isFavorite: favoriteIds.contains(item.outfit.id),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }
}
