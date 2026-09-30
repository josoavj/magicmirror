import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/services/outfit_ranking_service.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_favorites_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_profile_header.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_suggestion_section.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_weather_context_card.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';

class OutfitSuggestionScreen extends ConsumerStatefulWidget {
  const OutfitSuggestionScreen({super.key});

  @override
  ConsumerState<OutfitSuggestionScreen> createState() =>
      _OutfitSuggestionScreenState();
}

class _OutfitSuggestionScreenState
    extends ConsumerState<OutfitSuggestionScreen> {
  bool _favoritesOnly = false;

  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  Widget build(BuildContext context) {
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
    final tomorrow = today.add(const Duration(days: 1));
    final weatherBundleAsync = ref.watch(outfitWeatherBundleProvider);
    final todayEventsAsync = ref.watch(agendaEventsForDayProvider(today));
    final tomorrowEventsAsync = ref.watch(agendaEventsForDayProvider(tomorrow));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_tr(context, 'Mes tenues', 'My outfits')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _tr(context, 'Actualiser les données', 'Refresh data'),
            onPressed: () {
              ref.invalidate(outfitWeatherBundleProvider);
              ref.invalidate(agendaEventsForDayProvider(today));
              ref.invalidate(agendaEventsForDayProvider(tomorrow));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 32),
            children: [
              OutfitProfileHeader(
                profile: profile,
                detectedMorphology:
                    rankingProfile.morphology != profile.morphology
                    ? rankingProfile.morphology
                    : null,
              ),
              const SizedBox(height: 12),
              OutfitWeatherContextCard(weatherAsync: weatherBundleAsync),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_tr(context, 'Suggestions', 'Suggestions')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.favorite_outline),
                    label: Text(
                      '${_tr(context, 'Favoris', 'Favorites')} (${favoriteIds.length})',
                    ),
                  ),
                ],
                selected: {_favoritesOnly},
                onSelectionChanged: (selection) =>
                    setState(() => _favoritesOnly = selection.first),
              ),
              const SizedBox(height: 20),
              OutfitSuggestionSection(
                title: _favoritesOnly
                    ? _tr(context, 'Favoris du jour', 'Today’s favorites')
                    : _tr(context, 'Aujourd’hui', 'Today'),
                targetDay: today,
                profile: rankingProfile,
                favoriteIds: favoriteIds,
                personalization: personalization,
                eventsAsync: todayEventsAsync,
                favoritesOnly: _favoritesOnly,
                weatherContext: weatherBundleAsync.maybeWhen(
                  data: (bundle) =>
                      OutfitRankingService.weatherContextFromCurrent(
                        bundle.currentWeather,
                      ),
                  orElse: () => null,
                ),
              ),
              if (!_favoritesOnly) ...[
                const SizedBox(height: 24),
                OutfitSuggestionSection(
                  title: _tr(context, 'Demain', 'Tomorrow'),
                  targetDay: tomorrow,
                  profile: rankingProfile,
                  favoriteIds: favoriteIds,
                  personalization: personalization,
                  eventsAsync: tomorrowEventsAsync,
                  favoritesOnly: false,
                  weatherContext: weatherBundleAsync.maybeWhen(
                    data: (bundle) =>
                        OutfitRankingService.weatherContextFromForecast(
                          bundle.tomorrowForecast,
                        ),
                    orElse: () => null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
