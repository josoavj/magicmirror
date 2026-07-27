import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/services/outfit_ranking_service.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_profile_header.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/widgets/outfit_suggestion_section.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';

class OutfitSuggestionScreen extends ConsumerWidget {
  final bool initialShowFavorites;
  const OutfitSuggestionScreen({super.key, this.initialShowFavorites = false});

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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutfitProfileHeader(profile: profile),
                const SizedBox(height: 24),
                OutfitSuggestionSection(
                  title: _tr(context, 'Aujourd\'hui', 'Today'),
                  targetDay: today,
                  profile: profile,
                  favoriteIds: favoriteIds,
                  personalization: personalization,
                  eventsAsync: todayEventsAsync,
                  weatherContext: weatherBundleAsync.maybeWhen(
                    data:
                        (b) => OutfitRankingService.weatherContextFromCurrent(
                          b.currentWeather,
                        ),
                    orElse: () => null,
                  ),
                ),
                const SizedBox(height: 24),
                OutfitSuggestionSection(
                  title: _tr(context, 'Demain', 'Tomorrow'),
                  targetDay: tomorrow,
                  profile: profile,
                  favoriteIds: favoriteIds,
                  personalization: personalization,
                  eventsAsync: tomorrowEventsAsync,
                  weatherContext: weatherBundleAsync.maybeWhen(
                    data:
                        (b) => OutfitRankingService.weatherContextFromForecast(
                          b.tomorrowForecast,
                        ),
                    orElse: () => null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
