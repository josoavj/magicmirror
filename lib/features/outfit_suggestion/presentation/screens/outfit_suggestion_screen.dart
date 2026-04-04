import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';
import 'package:magicmirror/features/weather/data/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../presentation/widgets/glass_container.dart';

final agendaEventsForDayProvider =
    FutureProvider.family<List<AgendaEvent>, DateTime>((ref, day) async {
      final service = ref.watch(agendaSupabaseServiceProvider);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      return service.fetchEventsForDay(normalizedDay);
    });

final outfitWeatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final outfitWeatherBundleProvider = FutureProvider<_OutfitWeatherBundle>((
  ref,
) async {
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

final outfitFavoritesProvider =
    StateNotifierProvider<OutfitFavoritesNotifier, Set<String>>((ref) {
      return OutfitFavoritesNotifier(ref);
    });

enum OutfitFavoritesSyncStatus { idle, syncing, synced, localOnly, error }

final outfitFavoritesSyncStatusProvider =
    StateProvider<OutfitFavoritesSyncStatus>((ref) {
      return OutfitFavoritesSyncStatus.idle;
    });

final outfitFavoritesSyncMessageProvider = StateProvider<String>((ref) {
  return 'Aucune synchronisation';
});

final outfitStrictWeatherModeProvider = StateProvider<bool>((ref) {
  return true;
});

class OutfitFavoritesNotifier extends StateNotifier<Set<String>> {
  OutfitFavoritesNotifier(this._ref) : super(<String>{}) {
    _attachAuthListener();
    // Defer initial load to avoid mutating other providers during build.
    Future.microtask(_load);
  }

  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;

  static const _prefsKey = 'outfit.favorite.ids';

  bool _isUndefinedColumnError(Object error) {
    if (error is PostgrestException && error.code == '42703') {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('42703') && message.contains('column');
  }

  String _syncErrorMessage(String operation, Object error) {
    if (_isUndefinedColumnError(error)) {
      return 'Schema Supabase incomplet (42703): ajoutez favorite_outfit_ids dans profiles.';
    }
    return '$operation: ${error.toString()}';
  }

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocal(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }

  void _attachAuthListener() {
    final client = _client;
    if (client == null) {
      return;
    }
    _authSubscription = client.auth.onAuthStateChange.listen((event) {
      final userId = event.session?.user.id;
      if (userId != null && userId.isNotEmpty) {
        unawaited(_retryCloudSync());
      }
    });
  }

  Future<Set<String>?> _loadFromSupabase() async {
    final client = _client;
    if (client == null) {
      return null;
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    try {
      final data = await client
          .from('profiles')
          .select('favorite_outfit_ids')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null || data['favorite_outfit_ids'] == null) {
        return <String>{};
      }

      final raw = data['favorite_outfit_ids'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toSet();
      }
      return <String>{};
    } catch (error) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          _syncErrorMessage('Lecture cloud impossible', error);
      return null;
    }
  }

  Future<bool> _saveToSupabase(Set<String> ids) async {
    final client = _client;
    if (client == null) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Supabase indisponible sur cet ecran';
      return false;
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Connexion requise pour synchroniser les favoris';
      return false;
    }

    try {
      await client
          .from('profiles')
          .upsert({
            'user_id': userId,
            'favorite_outfit_ids': ids.toList(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id')
          .select('user_id')
          .maybeSingle();
      return true;
    } catch (error) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          _syncErrorMessage('Sync cloud echouee', error);
      return false;
    }
  }

  Future<void> _retryCloudSync() async {
    final localIds = Set<String>.from(state);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
        OutfitFavoritesSyncStatus.syncing;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
        'Nouvelle tentative de synchronisation cloud...';

    final remoteIds = await _loadFromSupabase();
    if (remoteIds == null) {
      _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
          OutfitFavoritesSyncStatus.localOnly;
      return;
    }

    final merged = <String>{...localIds, ...remoteIds};
    state = merged;
    await _saveLocal(merged);

    final pushed = await _saveToSupabase(merged);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state = pushed
        ? OutfitFavoritesSyncStatus.synced
        : OutfitFavoritesSyncStatus.localOnly;
    if (pushed) {
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Favoris synchronises avec le cloud';
    }
  }

  Future<void> _load() async {
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
        OutfitFavoritesSyncStatus.syncing;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
        'Synchronisation des favoris...';

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? const <String>[];
    final localIds = ids.toSet();
    state = localIds;

    final remoteIds = await _loadFromSupabase();
    if (remoteIds == null) {
      _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
          OutfitFavoritesSyncStatus.localOnly;
      if (_ref.read(outfitFavoritesSyncMessageProvider) ==
          'Synchronisation des favoris...') {
        _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
            'Mode local (cloud indisponible)';
      }
      return;
    }

    if (remoteIds.isNotEmpty || localIds.isEmpty) {
      state = remoteIds;
      await _saveLocal(remoteIds);
      _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
          OutfitFavoritesSyncStatus.synced;
      _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
          'Favoris synchronises avec le cloud';
      return;
    }

    // Si le cloud est vide mais local non vide, on pousse local vers Supabase.
    final pushed = await _saveToSupabase(localIds);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state = pushed
        ? OutfitFavoritesSyncStatus.synced
        : OutfitFavoritesSyncStatus.localOnly;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state = pushed
        ? 'Favoris synchronises avec le cloud'
        : 'Mode local (sync cloud echouee)';
  }

  Future<void> toggleFavorite(String outfitId) async {
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state =
        OutfitFavoritesSyncStatus.syncing;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state =
        'Mise a jour des favoris...';

    final next = Set<String>.from(state);
    if (next.contains(outfitId)) {
      next.remove(outfitId);
    } else {
      next.add(outfitId);
    }
    state = next;
    await _saveLocal(next);
    final synced = await _saveToSupabase(next);
    _ref.read(outfitFavoritesSyncStatusProvider.notifier).state = synced
        ? OutfitFavoritesSyncStatus.synced
        : OutfitFavoritesSyncStatus.localOnly;
    _ref.read(outfitFavoritesSyncMessageProvider.notifier).state = synced
        ? 'Favoris synchronises avec le cloud'
        : 'Mode local (sync cloud echouee)';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class OutfitSuggestionScreen extends ConsumerWidget {
  const OutfitSuggestionScreen({super.key, this.initialShowFavorites = false});

  final bool initialShowFavorites;

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final isFavoritesMode = initialShowFavorites;
    final profile = ref.watch(userProfileProvider);
    final favoriteIds = ref.watch(outfitFavoritesProvider);
    final strictWeatherMode = ref.watch(outfitStrictWeatherModeProvider);
    final favoritesSyncStatus = ref.watch(outfitFavoritesSyncStatusProvider);
    final favoritesSyncMessage = ref.watch(outfitFavoritesSyncMessageProvider);
    final activeEmail =
        Supabase.instance.client.auth.currentUser?.email ??
        _tr(context, 'Non connecte', 'Not connected');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayEventsAsync = ref.watch(agendaEventsForDayProvider(today));
    final tomorrowEventsAsync = ref.watch(agendaEventsForDayProvider(tomorrow));
    final weatherBundleAsync = ref.watch(outfitWeatherBundleProvider);

    final todayEvents = todayEventsAsync.maybeWhen(
      data: (events) => events,
      orElse: () => const <AgendaEvent>[],
    );
    final tomorrowEvents = tomorrowEventsAsync.maybeWhen(
      data: (events) => events,
      orElse: () => const <AgendaEvent>[],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'Outfit Suggestions' : 'Suggestions de Tenue'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        isFavoritesMode
                            ? (isEnglish ? 'My Favorites' : 'Mes Favoris')
                            : (isEnglish
                                  ? 'Recommendations'
                                  : 'Recommandations'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFavoritesMode
                            ? (isEnglish
                                  ? 'Cloud collection of your saved outfits'
                                  : 'Collection cloud de vos tenues enregistrees')
                            : (isEnglish
                                  ? 'Personalized suggestions based on your preferences'
                                  : 'Suggestions personnalisees basees sur vos preferences'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _favoritesSyncIcon(favoritesSyncStatus),
                            size: 14,
                            color: _favoritesSyncColor(favoritesSyncStatus),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              favoritesSyncMessage,
                              style: TextStyle(
                                color: _favoritesSyncColor(favoritesSyncStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_tr(context, 'Compte actif', 'Active account')}: $activeEmail',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isFavoritesMode) ...[
                        _buildFavoritesModeHeader(favoriteIds.length),
                        const SizedBox(height: 16),
                      ],

                      if (!isFavoritesMode) ...[
                        _buildProfileContext(
                          context,
                          profile,
                          todayEvents: todayEvents,
                          tomorrowEvents: tomorrowEvents,
                        ),
                        const SizedBox(height: 14),
                        _buildRecommendationTuning(
                          context,
                          ref,
                          strictWeatherMode,
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildSuggestionSection(
                        ref: ref,
                        context: context,
                        title: isFavoritesMode
                            ? _tr(
                                context,
                                'Favoris disponibles aujourd\'hui',
                                'Available favorites today',
                              )
                            : _tr(
                                context,
                                'Suggestion pour aujourd\'hui',
                                'Suggestion for today',
                              ),
                        targetDay: today,
                        profile: profile,
                        favoriteIds: favoriteIds,
                        showOnlyFavorites: initialShowFavorites,
                        eventsAsync: todayEventsAsync,
                        weatherContext: weatherBundleAsync.maybeWhen(
                          data: (bundle) =>
                              _weatherContextFromCurrent(bundle.currentWeather),
                          orElse: () => null,
                        ),
                        strictWeatherMode: strictWeatherMode,
                        referenceNow: now,
                      ),

                      const SizedBox(height: 16),

                      _buildSuggestionSection(
                        ref: ref,
                        context: context,
                        title: isFavoritesMode
                            ? _tr(
                                context,
                                'Favoris disponibles demain',
                                'Available favorites tomorrow',
                              )
                            : _tr(
                                context,
                                'Suggestion pour demain',
                                'Suggestion for tomorrow',
                              ),
                        targetDay: tomorrow,
                        profile: profile,
                        favoriteIds: favoriteIds,
                        showOnlyFavorites: initialShowFavorites,
                        eventsAsync: tomorrowEventsAsync,
                        weatherContext: weatherBundleAsync.maybeWhen(
                          data: (bundle) => _weatherContextFromForecast(
                            bundle.tomorrowForecast,
                          ),
                          orElse: () => null,
                        ),
                        strictWeatherMode: strictWeatherMode,
                        referenceNow: DateTime(
                          tomorrow.year,
                          tomorrow.month,
                          tomorrow.day,
                          8,
                        ),
                      ),

                      if (!isFavoritesMode) ...[
                        const SizedBox(height: 24),
                        _buildWeatherSection(weatherBundleAsync),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContext(
    BuildContext context,
    UserProfile profile, {
    required List<AgendaEvent> todayEvents,
    required List<AgendaEvent> tomorrowEvents,
  }) {
    final now = DateTime.now();
    final dayLabel = _weekdayLabelLocalized(now.weekday, context);
    final tomorrow = now.add(const Duration(days: 1));
    final prioritySlotToday = _resolvePrioritySlot(todayEvents, now);
    final prioritySlotTomorrow = _resolvePrioritySlot(
      tomorrowEvents,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8),
    );
    return SizedBox(
      width: double.infinity,
      child: GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(context, 'Profil applique', 'Applied profile'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${profile.gender}, ${profile.age} ${_tr(context, 'ans', 'years')}, ${profile.morphology}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr(context, 'Styles preferes', 'Preferred styles')}: ${profile.preferredStyles.join(', ')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr(context, 'Jour', 'Day')}: $dayLabel - ${_tr(context, 'Planning du jour', 'Today agenda')}: ${todayEvents.length} ${_tr(context, 'evenement(s)', 'event(s)')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr(context, 'Aujourd\'hui', 'Today')}: ${_slotLabelLocalized(prioritySlotToday, context)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_tr(context, 'Demain', 'Tomorrow')}: ${tomorrowEvents.length} ${_tr(context, 'evenement(s)', 'event(s)')} - ${_slotLabelLocalized(prioritySlotTomorrow, context)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationTuning(
    BuildContext context,
    WidgetRef ref,
    bool strictWeatherMode,
  ) {
    return GlassContainer(
      borderRadius: 16,
      blur: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(context, 'Mode meteo strict', 'Strict weather mode'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tr(
                    context,
                    'Filtre fortement les tenues incompatibles avec la meteo.',
                    'Strongly filters outfits incompatible with weather.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: strictWeatherMode,
            onChanged: (value) {
              ref.read(outfitStrictWeatherModeProvider.notifier).state = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection({
    required WidgetRef ref,
    required BuildContext context,
    required String title,
    required DateTime targetDay,
    required UserProfile profile,
    required Set<String> favoriteIds,
    required bool showOnlyFavorites,
    required AsyncValue<List<AgendaEvent>> eventsAsync,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required DateTime referenceNow,
  }) {
    return eventsAsync.when(
      data: (events) {
        final cards = _buildOutfitCards(
          ref,
          context,
          profile,
          events,
          targetDay: targetDay,
          favoriteIds: favoriteIds,
          showOnlyFavorites: showOnlyFavorites,
          weatherContext: weatherContext,
          strictWeatherMode: strictWeatherMode,
          referenceNow: referenceNow,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (weatherContext != null) ...[
              Text(
                '${_tr(context, 'Meteo', 'Weather')}: ${weatherContext.label}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...cards,
          ],
        );
      },
      loading: () => GlassContainer(
        borderRadius: 16,
        blur: 20,
        opacity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tr(
                  context,
                  'Chargement des suggestions...',
                  'Loading suggestions...',
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => GlassContainer(
        borderRadius: 16,
        blur: 20,
        opacity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Text(
          _tr(
            context,
            'Impossible de charger le planning pour cette suggestion.',
            'Unable to load schedule for this suggestion.',
          ),
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  List<Widget> _buildOutfitCards(
    WidgetRef ref,
    BuildContext context,
    UserProfile profile,
    List<AgendaEvent> events, {
    required DateTime targetDay,
    required Set<String> favoriteIds,
    required bool showOnlyFavorites,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required DateTime referenceNow,
  }) {
    final ranked = _rankOutfits(
      profile,
      events,
      favoriteIds: favoriteIds,
      targetDay: targetDay,
      weatherContext: weatherContext,
      strictWeatherMode: strictWeatherMode,
      referenceNow: referenceNow,
    );
    final visible = showOnlyFavorites
        ? ranked.where((item) => favoriteIds.contains(item.outfit.id)).toList()
        : ranked;

    if (visible.isEmpty) {
      return [
        GlassContainer(
          borderRadius: 16,
          blur: 20,
          opacity: 0.1,
          padding: const EdgeInsets.all(14),
          child: Text(
            showOnlyFavorites
                ? _tr(
                    context,
                    'Aucune tenue en favoris pour cette section.',
                    'No favorite outfit available for this section.',
                  )
                : _tr(
                    context,
                    'Aucune suggestion disponible.',
                    'No suggestion available.',
                  ),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ];
    }

    return visible
        .map(
          (item) => _buildOutfitCard(
            ref,
            context,
            item,
            isFavorite: favoriteIds.contains(item.outfit.id),
          ),
        )
        .toList();
  }

  List<_RankedOutfit> _rankOutfits(
    UserProfile profile,
    List<AgendaEvent> events, {
    required Set<String> favoriteIds,
    required DateTime targetDay,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required DateTime referenceNow,
  }) {
    final allOutfits = [
      _Outfit(
        id: 'casual_moderne',
        title: 'Casual Moderne',
        description: 'Jeans + T-shirt léger',
        icon: Icons.checkroom,
        color: const Color(0xFF3B82F6),
        styles: const ['casual', 'minimaliste'],
        compatibleMorphologies: const [
          'Silhouette droite',
          'Hanches et epaules equilibrees',
        ],
        genderTargets: const ['all'],
        minAge: 16,
        maxAge: 60,
      ),
      _Outfit(
        id: 'elegant',
        title: 'Élégant',
        description: 'Chemise + Pantalon chino',
        icon: Icons.style,
        color: const Color(0xFF8B5CF6),
        styles: const ['elegant', 'business'],
        compatibleMorphologies: const [
          'Hanches et epaules equilibrees',
          'Epaules plus larges',
        ],
        genderTargets: const ['all'],
        minAge: 20,
        maxAge: 65,
      ),
      _Outfit(
        id: 'sport',
        title: 'Sport',
        description: 'Legging + Hoodie',
        icon: Icons.sports,
        color: const Color(0xFF10B981),
        styles: const ['sport'],
        compatibleMorphologies: const [
          'Hanches plus marquees',
          'Taille tres marquee',
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
        icon: Icons.local_fire_department,
        color: const Color(0xFFEC4899),
        styles: const ['streetwear', 'casual'],
        compatibleMorphologies: const [
          'Epaules tres marquees',
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
        icon: Icons.business_center,
        color: const Color(0xFFF59E0B),
        styles: const ['business', 'elegant'],
        compatibleMorphologies: const [
          'Hanches tres marquees',
          'Hanches et epaules equilibrees',
          'Epaules plus larges',
        ],
        genderTargets: const ['all'],
        minAge: 24,
        maxAge: 70,
      ),
      _Outfit(
        id: 'minimal_monochrome',
        title: 'Minimal Monochrome',
        description: 'Palette neutre + coupe clean',
        icon: Icons.layers,
        color: const Color(0xFF14B8A6),
        styles: const ['minimaliste', 'casual'],
        compatibleMorphologies: const ['all'],
        genderTargets: const ['all'],
        minAge: 18,
        maxAge: 80,
      ),
    ];

    final normalizedStyles = profile.preferredStyles
        .map(_normalizeStyle)
        .toSet();
    final normalizedGender = profile.gender.toLowerCase();
    final planningSignals = _extractPlanningSignals(events);
    final isWeekend = _isWeekend(targetDay);
    final prioritySlot = _resolvePrioritySlot(events, referenceNow);
    final primaryContext = _resolvePrimaryContext(events, referenceNow);

    var candidates = allOutfits.where((outfit) {
      final ageOk =
          profile.age >= outfit.minAge && profile.age <= outfit.maxAge;
      final morphologyOk = _isMorphologyCompatible(profile.morphology, outfit);
      return ageOk && morphologyOk;
    }).toList();

    // Hard constraints first: remove clearly unsuitable outfits for the
    // immediate context to avoid noisy recommendations.
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

    if (candidates.isEmpty) {
      candidates = allOutfits;
    }

    final ranked = candidates.map((outfit) {
      var score = 10;
      final reasonScores = <String, int>{};
      final contextCompatible = _isContextCompatible(
        primaryContext,
        outfit.styles,
      );

      void addReason(String reason, int weight) {
        final current = reasonScores[reason] ?? 0;
        if (weight > current) {
          reasonScores[reason] = weight;
        }
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

      // Bonus additionnel si le style principal utilisateur est couvert.
      if (profile.preferredStyles.isNotEmpty) {
        final topStyle = _normalizeStyle(profile.preferredStyles.first);
        if (outfit.styles.contains(topStyle)) {
          score += 18;
          addReason('Aligne avec votre style principal', 110);
        }
      }

      if (profile.age >= outfit.minAge && profile.age <= outfit.maxAge) {
        score += 24;
        addReason('Adapte a votre tranche d\'age', 40);
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
          outfit.genderTargets.any(
            (gender) => normalizedGender.contains(gender),
          );
      if (isGenderMatch) {
        score += 12;
      }

      if (contextCompatible) {
        score += 24;
        addReason('Adapte a votre contexte principal', 90);
      } else {
        score -= 12;
      }

      final planningCoherence = _planningCoherenceBoost(
        planningSignals: planningSignals,
        primaryContext: primaryContext,
        styles: outfit.styles,
      );
      if (planningCoherence > 0) {
        score += planningCoherence;
        addReason('Cohérence avec vos priorites du jour', 88);
      } else if (planningCoherence < 0) {
        score += planningCoherence;
      }

      if (isWeekend &&
          outfit.styles.any((style) {
            return style == 'casual' ||
                style == 'streetwear' ||
                style == 'sport';
          })) {
        score += 12;
        addReason('Adapte au rythme du week-end', 35);
      }

      if (!isWeekend &&
          outfit.styles.any((style) {
            return style == 'business' || style == 'elegant';
          })) {
        score += 12;
        addReason('Adapte a une journee de semaine', 35);
      }

      if (planningSignals.hasWorkEvent &&
          outfit.styles.any(
            (style) => style == 'business' || style == 'elegant',
          )) {
        score += 30;
        addReason('Compatible avec votre planning pro', 105);
      } else if (planningSignals.hasWorkEvent) {
        score -= 8;
      }

      if (planningSignals.hasSportEvent && outfit.styles.contains('sport')) {
        score += 30;
        addReason('Compatible avec vos activites sportives', 105);
      } else if (planningSignals.hasSportEvent) {
        score -= 8;
      }

      if (planningSignals.hasEveningEvent &&
          outfit.styles.any(
            (style) => style == 'elegant' || style == 'streetwear',
          )) {
        score += 16;
        addReason('Adapte a vos sorties du soir', 65);
      }

      if (planningSignals.hasCasualEvent &&
          outfit.styles.any((style) {
            return style == 'casual' ||
                style == 'streetwear' ||
                style == 'minimaliste';
          })) {
        score += 14;
        addReason('Adapte a un planning detendu', 60);
      }

      if (events.isNotEmpty &&
          planningSignals.hasOutdoorEvent &&
          outfit.styles.any((style) => style == 'sport' || style == 'casual')) {
        score += 10;
        addReason('Confortable pour des deplacements exterieurs', 55);
      }

      final slotBoost = _slotScoreBoost(prioritySlot, outfit.styles);
      if (slotBoost > 0) {
        score += slotBoost;
        addReason(
          'Optimise pour le creneau ${_slotLabel(prioritySlot).toLowerCase()}',
          50,
        );
      }

      final weatherBoost = _weatherScoreBoost(
        weatherContext,
        outfit.styles,
        strictWeatherMode: strictWeatherMode,
      );
      if (weatherBoost > 0) {
        score += weatherBoost;
        addReason('Adapte aux conditions meteo', 100);
      } else if (weatherBoost < 0) {
        score += weatherBoost;
        addReason('Compromis meteo detecte', 45);
      }

      if (score < 0) {
        score = 0;
      }

      final reasons = _sortedReasons(reasonScores);

      return _RankedOutfit(outfit: outfit, score: score, reasons: reasons);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return ranked.take(4).toList();
  }

  String _normalizeStyle(String value) {
    final v = value.toLowerCase();
    if (v.contains('eleg')) {
      return 'elegant';
    }
    if (v.contains('mini')) {
      return 'minimaliste';
    }
    return v;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lundi';
      case DateTime.tuesday:
        return 'Mardi';
      case DateTime.wednesday:
        return 'Mercredi';
      case DateTime.thursday:
        return 'Jeudi';
      case DateTime.friday:
        return 'Vendredi';
      case DateTime.saturday:
        return 'Samedi';
      case DateTime.sunday:
        return 'Dimanche';
      default:
        return 'Jour inconnu';
    }
  }

  _PlanningSignals _extractPlanningSignals(List<AgendaEvent> events) {
    var hasWorkEvent = false;
    var hasSportEvent = false;
    var hasEveningEvent = false;
    var hasCasualEvent = false;
    var hasOutdoorEvent = false;

    for (final event in events) {
      if (event.isCompleted) {
        continue;
      }

      final eventBlob =
          '${event.eventType} ${event.title} ${event.description ?? ''}'
              .toLowerCase();

      if (_containsAny(eventBlob, const [
        'work',
        'travail',
        'reunion',
        'meeting',
        'bureau',
        'rdv pro',
        'professionnel',
        'business',
      ])) {
        hasWorkEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'sport',
        'gym',
        'run',
        'course',
        'training',
        'fitness',
      ])) {
        hasSportEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'soiree',
        'soir',
        'diner',
        'resto',
        'event',
        'sortie',
      ])) {
        hasEveningEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'amis',
        'detente',
        'shopping',
        'promenade',
        'famille',
        'loisir',
        'casual',
      ])) {
        hasCasualEvent = true;
      }

      if (_containsAny(eventBlob, const [
        'exterieur',
        'outdoor',
        'marche',
        'balade',
        'deplacement',
      ])) {
        hasOutdoorEvent = true;
      }

      if (event.startTime.hour >= 18) {
        hasEveningEvent = true;
      }
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
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  _DayTimeSlot _resolvePrioritySlot(List<AgendaEvent> events, DateTime now) {
    final pending = events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final event in pending) {
      if (!event.endTime.isBefore(now)) {
        return _slotFromHour(event.startTime.hour);
      }
    }

    return _slotFromHour(now.hour);
  }

  _DayTimeSlot _slotFromHour(int hour) {
    if (hour < 12) {
      return _DayTimeSlot.morning;
    }
    if (hour < 18) {
      return _DayTimeSlot.afternoon;
    }
    return _DayTimeSlot.evening;
  }

  String _slotLabel(_DayTimeSlot slot) {
    switch (slot) {
      case _DayTimeSlot.morning:
        return 'Matin';
      case _DayTimeSlot.afternoon:
        return 'Apres-midi';
      case _DayTimeSlot.evening:
        return 'Soiree';
    }
  }

  String _slotLabelLocalized(_DayTimeSlot slot, BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    switch (slot) {
      case _DayTimeSlot.morning:
        return isEnglish ? 'Morning' : 'Matin';
      case _DayTimeSlot.afternoon:
        return isEnglish ? 'Afternoon' : 'Apres-midi';
      case _DayTimeSlot.evening:
        return isEnglish ? 'Evening' : 'Soiree';
    }
  }

  String _weekdayLabelLocalized(int weekday, BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (!isEnglish) {
      return _weekdayLabel(weekday);
    }
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown day';
    }
  }

  int _slotScoreBoost(_DayTimeSlot slot, List<String> styles) {
    switch (slot) {
      case _DayTimeSlot.morning:
        if (styles.any((s) => s == 'business' || s == 'minimaliste')) {
          return 14;
        }
        if (styles.any((s) => s == 'casual')) {
          return 8;
        }
        return 0;
      case _DayTimeSlot.afternoon:
        if (styles.any((s) => s == 'casual' || s == 'streetwear')) {
          return 12;
        }
        if (styles.any((s) => s == 'business' || s == 'sport')) {
          return 8;
        }
        return 0;
      case _DayTimeSlot.evening:
        if (styles.any((s) => s == 'elegant' || s == 'streetwear')) {
          return 16;
        }
        if (styles.any((s) => s == 'minimaliste')) {
          return 8;
        }
        return 0;
    }
  }

  int _planningCoherenceBoost({
    required _PlanningSignals planningSignals,
    required _PlanningContext primaryContext,
    required List<String> styles,
  }) {
    var boost = 0;

    if (primaryContext == _PlanningContext.work) {
      if (styles.any((s) => s == 'business' || s == 'elegant')) {
        boost += 8;
      } else {
        boost -= 8;
      }
    }

    if (primaryContext == _PlanningContext.sport) {
      if (styles.contains('sport')) {
        boost += 8;
      } else {
        boost -= 8;
      }
    }

    if (planningSignals.hasWorkEvent && planningSignals.hasEveningEvent) {
      // Favor versatile outfits that can transition from work to evening.
      if (styles.any((s) => s == 'elegant' || s == 'minimaliste')) {
        boost += 6;
      }
      if (styles.length == 1 && styles.contains('sport')) {
        boost -= 6;
      }
    }

    if (planningSignals.hasWorkEvent && planningSignals.hasSportEvent) {
      // Mixed day: avoid ultra-specialized outfits.
      if (styles.length == 1 &&
          (styles.contains('business') || styles.contains('sport'))) {
        boost -= 6;
      }
      if (styles.any((s) => s == 'casual' || s == 'minimaliste')) {
        boost += 4;
      }
    }

    return boost;
  }

  List<String> _sortedReasons(Map<String, int> reasonScores) {
    final entries = reasonScores.entries.toList()
      ..sort((a, b) {
        final byWeight = b.value.compareTo(a.value);
        if (byWeight != 0) {
          return byWeight;
        }
        return a.key.compareTo(b.key);
      });
    return entries.map((e) => e.key).toList();
  }

  int _weatherScoreBoost(
    _OutfitWeatherContext? weather,
    List<String> styles, {
    required bool strictWeatherMode,
  }) {
    if (weather == null) {
      return 0;
    }

    var boost = 0;
    final main = weather.main.toLowerCase();

    if (weather.temperature >= 28) {
      if (styles.any(
        (s) => s == 'casual' || s == 'minimaliste' || s == 'sport',
      )) {
        boost += 14;
      }
    }

    if (weather.temperature <= 16) {
      if (styles.any(
        (s) => s == 'business' || s == 'elegant' || s == 'minimaliste',
      )) {
        boost += 12;
      }
    }

    if (main.contains('rain') ||
        main.contains('thunder') ||
        main.contains('snow')) {
      if (styles.any(
        (s) => s == 'business' || s == 'minimaliste' || s == 'casual',
      )) {
        boost += 10;
      }
    }

    if (weather.windSpeed >= 10) {
      if (styles.any((s) => s == 'sport' || s == 'casual')) {
        boost += 6;
      }
    }

    if (strictWeatherMode) {
      if (weather.temperature >= 31 &&
          styles.contains('business') &&
          !styles.contains('casual')) {
        boost -= 14;
      }

      if (weather.temperature <= 8 &&
          styles.length == 1 &&
          styles.contains('sport')) {
        boost -= 12;
      }

      final main = weather.main.toLowerCase();
      final isRainy =
          main.contains('rain') ||
          main.contains('thunder') ||
          main.contains('snow');
      if (isRainy &&
          styles.contains('streetwear') &&
          !styles.contains('business')) {
        boost -= 12;
      }
    }

    return boost;
  }

  bool _passesHardConstraints({
    required _Outfit outfit,
    required _OutfitWeatherContext? weatherContext,
    required bool strictWeatherMode,
    required _PlanningSignals planningSignals,
    required _PlanningContext primaryContext,
  }) {
    final styles = outfit.styles;

    // Work-first hard gate: if user has work context, keep at least one
    // business/elegant direction in the candidate set.
    final enforceWorkGate =
        (planningSignals.hasWorkEvent ||
            primaryContext == _PlanningContext.work) &&
        !planningSignals.hasSportEvent &&
        primaryContext != _PlanningContext.mixed;
    if (enforceWorkGate &&
        !styles.any((s) => s == 'business' || s == 'elegant')) {
      return false;
    }

    if (weatherContext == null) {
      return true;
    }

    if (!strictWeatherMode) {
      return true;
    }

    final main = weatherContext.main.toLowerCase();
    final isRainy =
        main.contains('rain') ||
        main.contains('thunder') ||
        main.contains('snow');

    // In rainy/snowy conditions, avoid highly exposed styles.
    if (isRainy &&
        styles.contains('streetwear') &&
        !styles.contains('business')) {
      return false;
    }

    // Very hot weather: avoid heavy formal-only outfits.
    if (weatherContext.temperature >= 31 &&
        styles.contains('business') &&
        !styles.contains('casual')) {
      return false;
    }

    // Very cold weather: avoid sport-only lightweight outfits.
    if (weatherContext.temperature <= 8 &&
        styles.length == 1 &&
        styles.contains('sport')) {
      return false;
    }

    return true;
  }

  bool _isMorphologyCompatible(String morphology, _Outfit outfit) {
    final normalized = morphology.trim().toLowerCase();
    if (normalized == 'silhouette non definie' || normalized == 'non definie') {
      return true;
    }
    return _matchesMorphology(
      profileMorphology: morphology,
      compatibleMorphologies: outfit.compatibleMorphologies,
    );
  }

  _PlanningContext _resolvePrimaryContext(
    List<AgendaEvent> events,
    DateTime referenceNow,
  ) {
    final pending = events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final event in pending) {
      if (!event.endTime.isBefore(referenceNow)) {
        return _contextFromEvent(event);
      }
    }

    if (pending.isNotEmpty) {
      return _contextFromEvent(pending.first);
    }

    return _PlanningContext.none;
  }

  _PlanningContext _contextFromEvent(AgendaEvent event) {
    final blob = '${event.eventType} ${event.title} ${event.description ?? ''}'
        .toLowerCase();

    if (_containsAny(blob, const [
      'work',
      'travail',
      'meeting',
      'reunion',
      'business',
      'bureau',
    ])) {
      return _PlanningContext.work;
    }
    if (_containsAny(blob, const [
      'sport',
      'gym',
      'training',
      'fitness',
      'run',
      'course',
    ])) {
      return _PlanningContext.sport;
    }
    if (_containsAny(blob, const [
      'soir',
      'soiree',
      'diner',
      'event',
      'sortie',
      'resto',
    ])) {
      return _PlanningContext.evening;
    }
    if (_containsAny(blob, const [
      'detente',
      'famille',
      'amis',
      'shopping',
      'loisir',
      'promenade',
    ])) {
      return _PlanningContext.casual;
    }
    return _PlanningContext.mixed;
  }

  bool _isContextCompatible(_PlanningContext context, List<String> styles) {
    switch (context) {
      case _PlanningContext.work:
        return styles.any((s) => s == 'business' || s == 'elegant');
      case _PlanningContext.sport:
        return styles.contains('sport');
      case _PlanningContext.evening:
        return styles.any((s) => s == 'elegant' || s == 'streetwear');
      case _PlanningContext.casual:
        return styles.any(
          (s) => s == 'casual' || s == 'minimaliste' || s == 'streetwear',
        );
      case _PlanningContext.mixed:
        return styles.any(
          (s) => s == 'casual' || s == 'minimaliste' || s == 'business',
        );
      case _PlanningContext.none:
        return true;
    }
  }

  bool _matchesMorphology({
    required String profileMorphology,
    required List<String> compatibleMorphologies,
  }) {
    if (compatibleMorphologies.contains('all')) {
      return true;
    }

    final aliases = _morphologyAliases(profileMorphology);
    return compatibleMorphologies.any(aliases.contains);
  }

  Set<String> _morphologyAliases(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'Sablier (X)':
      case 'Hanches et epaules equilibrees':
        return {'Sablier (X)', 'Hanches et epaules equilibrees'};
      case 'Poire (A)':
      case 'Hanches plus marquees':
        return {'Poire (A)', 'Hanches plus marquees'};
      case 'Rectangulaire (H)':
      case 'Silhouette droite':
        return {'Rectangulaire (H)', 'Silhouette droite'};
      case 'Triangle Inverse (V)':
      case 'Epaules plus larges':
        return {'Triangle Inverse (V)', 'Epaules plus larges'};
      case 'Triangle Inverse+ (V+)':
      case 'Epaules tres marquees':
        return {'Triangle Inverse+ (V+)', 'Epaules tres marquees'};
      case 'Sablier+ (X+)':
      case 'Taille tres marquee':
        return {'Sablier+ (X+)', 'Taille tres marquee'};
      case 'Poire+ (A+)':
      case 'Hanches tres marquees':
        return {'Poire+ (A+)', 'Hanches tres marquees'};
      case 'Non definie':
      case 'Silhouette non definie':
        return {'Non definie', 'Silhouette non definie'};
      default:
        return {normalized};
    }
  }

  Widget _buildOutfitCard(
    WidgetRef ref,
    BuildContext context,
    _RankedOutfit rankedOutfit, {
    required bool isFavorite,
  }) {
    final outfit = rankedOutfit.outfit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showOutfitDetailsSheet(
          ref,
          context,
          rankedOutfit,
          isFavorite: isFavorite,
        ),
        child: GlassContainer(
          borderRadius: 20,
          blur: 25,
          opacity: 0.1,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [outfit.color, outfit.color.withValues(alpha: 0.6)],
                  ),
                ),
                child: Center(
                  child: Icon(outfit.icon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outfit.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: rankedOutfit.reasons
                          .take(3)
                          .map(
                            (reason) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Appuyez pour voir tous les details',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorite
                        ? Colors.pinkAccent
                        : Colors.white.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${rankedOutfit.score} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOutfitDetailsSheet(
    WidgetRef ref,
    BuildContext context,
    _RankedOutfit rankedOutfit, {
    required bool isFavorite,
  }) async {
    final outfit = rankedOutfit.outfit;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: GlassContainer(
              borderRadius: 24,
              blur: 28,
              opacity: 0.14,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              outfit.color,
                              outfit.color.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Icon(outfit.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outfit.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outfit.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${rankedOutfit.score} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildDetailBlock(
                          title: 'Pourquoi cette tenue',
                          items: rankedOutfit.reasons,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Styles associes',
                          items: outfit.styles,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Morphologies compatibles',
                          items: outfit.compatibleMorphologies,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailBlock(
                          title: 'Tranche d\'age cible',
                          items: ['${outfit.minAge} a ${outfit.maxAge} ans'],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(outfitFavoritesProvider.notifier)
                            .toggleFavorite(outfit.id);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(
                        isFavorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Fermer les details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailBlock({
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesModeHeader(int favoritesCount) {
    return GlassContainer(
      borderRadius: 20,
      blur: 24,
      opacity: 0.12,
      padding: const EdgeInsets.all(16),
      tintColor: Colors.pinkAccent,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tenues favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$favoritesCount tenue(s) sauvegardée(s)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(AsyncValue<_OutfitWeatherBundle> weatherAsync) {
    return weatherAsync.when(
      data: (weatherBundle) {
        final current = weatherBundle.currentWeather;
        if (current == null) {
          return GlassContainer(
            borderRadius: 20,
            blur: 25,
            opacity: 0.1,
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Conditions météo indisponibles.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return GlassContainer(
          borderRadius: 20,
          blur: 25,
          opacity: 0.1,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conditions - ${current.cityName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.cloud_queue,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                current.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWeatherStat(
                    'Temp',
                    '${current.temperature.toStringAsFixed(1)}°C',
                  ),
                  _buildWeatherStat('Humidite', '${current.humidity}%'),
                  _buildWeatherStat(
                    'Vent',
                    '${current.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Chargement météo...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      error: (error, stackTrace) => GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: const Text(
          'Erreur lors du chargement de la météo.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _favoritesSyncColor(OutfitFavoritesSyncStatus status) {
    switch (status) {
      case OutfitFavoritesSyncStatus.synced:
        return Colors.greenAccent;
      case OutfitFavoritesSyncStatus.localOnly:
        return Colors.amberAccent;
      case OutfitFavoritesSyncStatus.error:
        return Colors.redAccent;
      case OutfitFavoritesSyncStatus.syncing:
        return Colors.lightBlueAccent;
      case OutfitFavoritesSyncStatus.idle:
        return Colors.white70;
    }
  }

  IconData _favoritesSyncIcon(OutfitFavoritesSyncStatus status) {
    switch (status) {
      case OutfitFavoritesSyncStatus.synced:
        return Icons.cloud_done;
      case OutfitFavoritesSyncStatus.localOnly:
        return Icons.cloud_off;
      case OutfitFavoritesSyncStatus.error:
        return Icons.error_outline;
      case OutfitFavoritesSyncStatus.syncing:
        return Icons.cloud_sync;
      case OutfitFavoritesSyncStatus.idle:
        return Icons.cloud_queue;
    }
  }
}

class _Outfit {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> styles;
  final List<String> compatibleMorphologies;
  final List<String> genderTargets;
  final int minAge;
  final int maxAge;

  const _Outfit({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.styles,
    required this.compatibleMorphologies,
    required this.genderTargets,
    required this.minAge,
    required this.maxAge,
  });
}

class _RankedOutfit {
  final _Outfit outfit;
  final int score;
  final List<String> reasons;

  const _RankedOutfit({
    required this.outfit,
    required this.score,
    required this.reasons,
  });
}

class _PlanningSignals {
  final bool hasWorkEvent;
  final bool hasSportEvent;
  final bool hasEveningEvent;
  final bool hasCasualEvent;
  final bool hasOutdoorEvent;

  const _PlanningSignals({
    required this.hasWorkEvent,
    required this.hasSportEvent,
    required this.hasEveningEvent,
    required this.hasCasualEvent,
    required this.hasOutdoorEvent,
  });
}

enum _DayTimeSlot { morning, afternoon, evening }

enum _PlanningContext { work, sport, evening, casual, mixed, none }

class _OutfitWeatherBundle {
  final WeatherResponse? currentWeather;
  final ForecastItem? tomorrowForecast;

  const _OutfitWeatherBundle({
    required this.currentWeather,
    required this.tomorrowForecast,
  });
}

class _OutfitWeatherContext {
  final String label;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String main;

  const _OutfitWeatherContext({
    required this.label,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.main,
  });
}

class _ForecastCoordinates {
  final double lat;
  final double lon;

  const _ForecastCoordinates({required this.lat, required this.lon});
}

Future<_ForecastCoordinates> _resolveForecastCoordinates() async {
  try {
    final permission = await Geolocator.checkPermission();
    var granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!granted) {
      final req = await Geolocator.requestPermission();
      granted =
          req == LocationPermission.always ||
          req == LocationPermission.whileInUse;
    }

    if (granted) {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
      );
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return _ForecastCoordinates(lat: pos.latitude, lon: pos.longitude);
    }
  } catch (_) {
    // Fallback below
  }

  return const _ForecastCoordinates(lat: -18.8792, lon: 47.5079);
}

ForecastItem? _pickTomorrowForecast(List<ForecastItem> forecasts) {
  final now = DateTime.now();
  final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
  final tomorrowItems = forecasts.where((item) {
    final d = item.dateTime;
    return d.year == tomorrowDate.year &&
        d.month == tomorrowDate.month &&
        d.day == tomorrowDate.day;
  }).toList();

  if (tomorrowItems.isEmpty) {
    return null;
  }

  tomorrowItems.sort((a, b) {
    final aDiff = (a.dateTime.hour - 12).abs();
    final bDiff = (b.dateTime.hour - 12).abs();
    return aDiff.compareTo(bDiff);
  });

  return tomorrowItems.first;
}

_OutfitWeatherContext? _weatherContextFromCurrent(WeatherResponse? weather) {
  if (weather == null) {
    return null;
  }

  return _OutfitWeatherContext(
    label:
        '${weather.description} | ${weather.temperature.toStringAsFixed(1)}°C | ${weather.humidity}% | ${weather.windSpeed.toStringAsFixed(1)} m/s',
    temperature: weather.temperature,
    humidity: weather.humidity,
    windSpeed: weather.windSpeed,
    main: weather.main,
  );
}

_OutfitWeatherContext? _weatherContextFromForecast(ForecastItem? forecast) {
  if (forecast == null) {
    return null;
  }

  return _OutfitWeatherContext(
    label:
        '${forecast.description} | ${forecast.temperature.toStringAsFixed(1)}°C | ${forecast.humidity}% | ${forecast.windSpeed.toStringAsFixed(1)} m/s',
    temperature: forecast.temperature,
    humidity: forecast.humidity,
    windSpeed: forecast.windSpeed,
    main: forecast.main,
  );
}
