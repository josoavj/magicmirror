import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_shared_providers.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_list_card.dart';
import 'package:intl/intl.dart';

class OutfitSuggestionSection extends ConsumerWidget {
  final String title;
  final DateTime targetDay;
  final UserProfile profile;
  final Set<String> favoriteIds;
  final OutfitPersonalizationState personalization;
  final AsyncValue<List<AgendaEvent>> eventsAsync;
  final OutfitWeatherContext? weatherContext;
  final bool favoritesOnly;

  const OutfitSuggestionSection({
    super.key,
    required this.title,
    required this.targetDay,
    required this.profile,
    required this.favoriteIds,
    required this.personalization,
    required this.eventsAsync,
    this.weatherContext,
    this.favoritesOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimisation : arrondir l'heure au quart d'heure le plus proche pour maximiser le cache Riverpod
    final now = DateTime.now();
    final minutes = (now.minute / 15).round() * 15;
    final roundedNow = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      minutes,
    );

    final llmDetailsAsync = ref.watch(outfitSecondaryLlmDetailsProvider);
    final mlScoresAsync = ref.watch(outfitMlScoreMapProvider);

    return eventsAsync.when(
      data: (events) {
        final llmDetails = llmDetailsAsync.value ?? const {};
        final params = RankingParams(
          profile: profile,
          events: events,
          favoriteIds: favoriteIds,
          personalization: personalization,
          mlScoreMap: mlScoresAsync.value ?? const {},
          llmDetailsByOutfitId: llmDetails,
          secondaryLlmEnabled: llmDetails.isNotEmpty,
          targetDay: targetDay,
          weatherContext: weatherContext,
          strictWeatherMode: true,
          creativeMixEnabled: true,
          creativeExplorationShare: 0.15,
          creativeBoost: 12,
          excludedOutfitIds: const {},
          referenceNow: roundedNow,
          favoritesOnly: favoritesOnly,
        );
        final ranked = ref.watch(rankedOutfitsProvider(params));
        final visibleRanked = ranked;
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
            if (events.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                events
                    .take(3)
                    .map(
                      (event) =>
                          '${DateFormat('HH:mm').format(event.startTime)} ${event.title}',
                    )
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            if (visibleRanked.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  favoritesOnly
                      ? (Localizations.localeOf(context).languageCode == 'en'
                            ? 'No saved favorite matches this day.'
                            : 'Aucun favori ne correspond à cette journée.')
                      : (Localizations.localeOf(context).languageCode == 'en'
                            ? 'No outfit matches your profile and this day’s conditions.'
                            : 'Aucune tenue ne correspond à votre profil et aux conditions de cette journée.'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              )
            else
              ...visibleRanked.map(
                (item) => OutfitListCard(
                  rankedOutfit: item,
                  isFavorite: favoriteIds.contains(item.outfit.id),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Calendar data could not be loaded.'
                : 'Impossible de charger les événements du calendrier.',
            style: const TextStyle(color: Colors.white70),
          ),
          TextButton.icon(
            onPressed: () =>
                ref.invalidate(agendaEventsForDayProvider(targetDay)),
            icon: const Icon(Icons.refresh),
            label: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Retry'
                  : 'Réessayer',
            ),
          ),
        ],
      ),
    );
  }
}
