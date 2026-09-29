import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/services/outfit_ranking_service.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_profile_header.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_suggestion_section.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';

class OutfitSuggestionScreen extends ConsumerStatefulWidget {
  final bool initialShowFavorites;
  const OutfitSuggestionScreen({super.key, this.initialShowFavorites = false});

  @override
  ConsumerState<OutfitSuggestionScreen> createState() =>
      _OutfitSuggestionScreenState();
}

class _OutfitSuggestionScreenState
    extends ConsumerState<OutfitSuggestionScreen> {
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.initialShowFavorites;
  }

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
              _buildContextCard(context, weatherBundleAsync),
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
                title: _tr(context, 'Aujourd’hui', 'Today'),
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
              const SizedBox(height: 24),
              OutfitSuggestionSection(
                title: _tr(context, 'Demain', 'Tomorrow'),
                targetDay: tomorrow,
                profile: rankingProfile,
                favoriteIds: favoriteIds,
                personalization: personalization,
                eventsAsync: tomorrowEventsAsync,
                favoritesOnly: _favoritesOnly,
                weatherContext: weatherBundleAsync.maybeWhen(
                  data: (bundle) =>
                      OutfitRankingService.weatherContextFromForecast(
                        bundle.tomorrowForecast,
                      ),
                  orElse: () => null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard(
    BuildContext context,
    AsyncValue<OutfitWeatherBundle> weatherAsync,
  ) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: weatherAsync.when(
        loading: () => Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              _tr(context, 'Chargement météo…', 'Loading weather…'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        error: (error, stack) => Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tr(
                  context,
                  'Météo indisponible : les suggestions restent basées sur votre profil et votre agenda.',
                  'Weather unavailable: suggestions still use your profile and calendar.',
                ),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        data: (bundle) {
          final current = bundle.currentWeather;
          final forecast = bundle.tomorrowForecast;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_cloudy_outlined,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tr(context, 'Contexte météo', 'Weather context'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                current == null
                    ? _tr(
                        context,
                        'Météo actuelle indisponible',
                        'Current weather unavailable',
                      )
                    : '${_tr(context, 'Aujourd’hui', 'Today')} · ${current.cityName} · ${current.description} · ${current.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                forecast == null
                    ? _tr(
                        context,
                        'Prévision de demain indisponible',
                        'Tomorrow’s forecast unavailable',
                      )
                    : '${_tr(context, 'Demain', 'Tomorrow')} · ${forecast.description} · ${forecast.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(color: Colors.white70),
              ),
              if (current?.isFallback == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _tr(
                      context,
                      'Données météo de secours utilisées.',
                      'Fallback weather data is being used.',
                    ),
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
