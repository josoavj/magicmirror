import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/services/outfit_ranking_service.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_favorites_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_suggestion_section.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';

class OutfitFavoritesScreen extends ConsumerWidget {
  const OutfitFavoritesScreen({super.key});

  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final detectedMorphology = ref.watch(stableMorphologyProvider);
    final rankingProfile =
        detectedMorphology != null && detectedMorphology.confidence >= 50
        ? profile.copyWith(morphology: detectedMorphology.bodyType)
        : profile;
    final favoriteIds = ref.watch(outfitFavoritesProvider);
    final personalization = ref.watch(outfitPersonalizationProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weatherBundleAsync = ref.watch(outfitWeatherBundleProvider);
    final todayEventsAsync = ref.watch(agendaEventsForDayProvider(today));

    return Scaffold(
      appBar: AppBar(
        title: Text(_tr(context, 'Mes favoris', 'My favorites')),
        actions: [
          IconButton(
            tooltip: _tr(context, 'Actualiser', 'Refresh'),
            onPressed: () {
              ref.invalidate(outfitWeatherBundleProvider);
              ref.invalidate(agendaEventsForDayProvider(today));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          OutfitSuggestionSection(
            title: '',
            targetDay: today,
            profile: rankingProfile,
            favoriteIds: favoriteIds,
            personalization: personalization,
            eventsAsync: todayEventsAsync,
            favoritesOnly: true,
            weatherContext: weatherBundleAsync.maybeWhen(
              data: (bundle) => OutfitRankingService.weatherContextFromCurrent(
                bundle.currentWeather,
              ),
              orElse: () => null,
            ),
          ),
        ],
      ),
    );
  }
}
