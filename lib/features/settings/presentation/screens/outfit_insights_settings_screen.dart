import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_shared_providers.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';

class OutfitInsightsSettingsScreen extends ConsumerWidget {
  const OutfitInsightsSettingsScreen({super.key});

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localTelemetry = ref.watch(outfitTelemetryProvider);
    final cloudTelemetryAsync = ref.watch(outfitCloudTelemetryProvider);
    final mergedTelemetry = cloudTelemetryAsync.maybeWhen(
      data: (cloud) => OutfitTelemetryState(
        likes: localTelemetry.likes + cloud.likes,
        dislikes: localTelemetry.dislikes + cloud.dislikes,
        seen: localTelemetry.seen + cloud.seen,
        favoriteAdds: localTelemetry.favoriteAdds + cloud.favoriteAdds,
        favoriteRemoves: localTelemetry.favoriteRemoves + cloud.favoriteRemoves,
      ),
      orElse: () => localTelemetry,
    );

    final strictWeatherMode = ref.watch(outfitStrictWeatherModeProvider);
    final creativeMixEnabled = ref.watch(outfitCreativeMixEnabledProvider);
    final creativeExplorationShare = ref.watch(
      outfitCreativeExplorationShareProvider,
    );
    final creativeBoost = ref.watch(outfitCreativeBoostProvider);
    final secondaryLlmEnabled = ref.watch(outfitSecondaryLlmEnabledProvider);
    final secondaryLlmWeight = ref.watch(outfitSecondaryLlmWeightProvider);
    final llamaUseProfileContext = ref.watch(
      outfitLlamaUseProfileContextProvider,
    );
    final llamaStrictGenderFilter = ref.watch(
      outfitLlamaStrictGenderFilterProvider,
    );
    final profile = ref.watch(userProfileProvider);
    final mlScoreMapAsync = ref.watch(outfitMlScoreMapProvider);
    final secondaryLlmScoreMapAsync = ref.watch(
      outfitSecondaryLlmScoreMapProvider,
    );
    final favoritesSyncStatus = ref.watch(outfitFavoritesSyncStatusProvider);
    final favoritesSyncMessage = ref.watch(outfitFavoritesSyncMessageProvider);
    final activeEmail =
        Supabase.instance.client.auth.currentUser?.email ??
        _tr(context, 'Non connecté', 'Not connected');

    String pct(double value) => '${(value * 100).toStringAsFixed(0)}%';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _tr(context, 'Paramètres des suggestions', 'Suggestion settings'),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                borderRadius: 16,
                blur: 18,
                opacity: 0.1,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(context, 'Compte actif', 'Active account'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: 16,
                blur: 18,
                opacity: 0.1,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(context, 'Paramètres moteur', 'Ranking settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Mode météo strict',
                              'Strict weather mode',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: strictWeatherMode,
                          onChanged: (value) {
                            ref
                                    .read(
                                      outfitStrictWeatherModeProvider.notifier,
                                    )
                                    .state =
                                value;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Mode créatif suggestions',
                              'Creative suggestion mode',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: creativeMixEnabled,
                          onChanged: (value) {
                            ref
                                    .read(
                                      outfitCreativeMixEnabledProvider.notifier,
                                    )
                                    .state =
                                value;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(
                        context,
                        'Part d\'exploration: ${(creativeExplorationShare * 100).round()}%',
                        'Exploration share: ${(creativeExplorationShare * 100).round()}%',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: creativeExplorationShare.clamp(0.1, 0.8),
                      min: 0.1,
                      max: 0.8,
                      divisions: 14,
                      label: '${(creativeExplorationShare * 100).round()}%',
                      onChanged: (value) {
                        ref
                                .read(
                                  outfitCreativeExplorationShareProvider
                                      .notifier,
                                )
                                .state =
                            value;
                      },
                    ),
                    Text(
                      _tr(
                        context,
                        'Intensite creative: $creativeBoost',
                        'Creative intensity: $creativeBoost',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: creativeBoost.toDouble().clamp(0, 20),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: creativeBoost.toString(),
                      onChanged: (value) {
                        ref.read(outfitCreativeBoostProvider.notifier).state =
                            value.round();
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Activer 2e modele LLM',
                              'Enable secondary LLM model',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: secondaryLlmEnabled,
                          onChanged: (value) {
                            ref
                                    .read(
                                      outfitSecondaryLlmEnabledProvider
                                          .notifier,
                                    )
                                    .state =
                                value;
                          },
                        ),
                      ],
                    ),
                    Text(
                      _tr(
                        context,
                        'Poids 2e LLM: ${(secondaryLlmWeight * 100).round()}%',
                        'Secondary LLM weight: ${(secondaryLlmWeight * 100).round()}%',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: secondaryLlmWeight.clamp(0.0, 0.7),
                      min: 0,
                      max: 0.7,
                      divisions: 14,
                      label: '${(secondaryLlmWeight * 100).round()}%',
                      onChanged: (value) {
                        ref
                                .read(outfitSecondaryLlmWeightProvider.notifier)
                                .state =
                            value;
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Llama prend le contexte profil',
                              'Llama uses profile context',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: llamaUseProfileContext,
                          onChanged: (value) {
                            ref
                                    .read(
                                      outfitLlamaUseProfileContextProvider
                                          .notifier,
                                    )
                                    .state =
                                value;
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Filtre sexe strict pour Llama',
                              'Strict gender filter for Llama',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: llamaStrictGenderFilter,
                          onChanged: (value) {
                            ref
                                    .read(
                                      outfitLlamaStrictGenderFilterProvider
                                          .notifier,
                                    )
                                    .state =
                                value;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tr(
                        context,
                        'Contexte profil envoye a Llama: Sexe ${profile.gender}, Morphologie ${profile.morphology}, Styles ${profile.preferredStyles.join(', ')}',
                        'Profile context sent to Llama: Gender ${profile.gender}, Morphology ${profile.morphology}, Styles ${profile.preferredStyles.join(', ')}',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tr(
                                context,
                                'Variete inter-jours activee: les tenues proposees aujourd\'hui sont exclues des suggestions de demain.',
                                'Cross-day variety enabled: outfits shown today are excluded from tomorrow suggestions.',
                              ),
                              style: TextStyle(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.95,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          ref
                                  .read(
                                    outfitStrictWeatherModeProvider.notifier,
                                  )
                                  .state =
                              true;
                          ref
                              .read(outfitCreativeMixEnabledProvider.notifier)
                              .state = AppConfig
                              .enableCreativeOutfitMix;
                          ref
                              .read(
                                outfitCreativeExplorationShareProvider.notifier,
                              )
                              .state = AppConfig
                              .outfitCreativeExplorationShare;
                          ref.read(outfitCreativeBoostProvider.notifier).state =
                              AppConfig.outfitCreativeBoost;
                          ref
                              .read(outfitSecondaryLlmEnabledProvider.notifier)
                              .state = AppConfig
                              .enableSecondaryLlmRanking;
                          ref
                              .read(outfitSecondaryLlmWeightProvider.notifier)
                              .state = AppConfig
                              .secondaryLlmWeight;
                          ref
                              .read(
                                outfitLlamaUseProfileContextProvider.notifier,
                              )
                              .state = AppConfig
                              .enableLlamaProfileContext;
                          ref
                              .read(
                                outfitLlamaStrictGenderFilterProvider.notifier,
                              )
                              .state = AppConfig
                              .enableLlamaStrictGenderFilter;
                        },
                        icon: const Icon(Icons.restore, size: 16),
                        label: Text(
                          _tr(
                            context,
                            'Reset parametres suggestions',
                            'Reset suggestion settings',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    mlScoreMapAsync.when(
                      data: (scores) {
                        final active = scores.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active
                                  ? _tr(
                                      context,
                                      'ML hybride actif (${scores.length} score(s) charges)',
                                      'Hybrid ML active (${scores.length} score(s) loaded)',
                                    )
                                  : _tr(
                                      context,
                                      'ML non alimente (scores cloud absents)',
                                      'ML not fed (cloud scores missing)',
                                    ),
                              style: TextStyle(
                                color: active
                                    ? Colors.greenAccent
                                    : Colors.amberAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            secondaryLlmScoreMapAsync.when(
                              data: (scores) {
                                final hasScores = scores.isNotEmpty;
                                return Text(
                                  hasScores
                                      ? _tr(
                                          context,
                                          '2e LLM actif (${scores.length} score(s) charges)',
                                          'Secondary LLM active (${scores.length} score(s) loaded)',
                                        )
                                      : _tr(
                                          context,
                                          '2e LLM non alimente (scores absents)',
                                          'Secondary LLM not fed (scores missing)',
                                        ),
                                  style: TextStyle(
                                    color: hasScores
                                        ? Colors.lightGreenAccent
                                        : Colors.amberAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                              loading: () => Text(
                                _tr(
                                  context,
                                  'Chargement des scores 2e LLM...',
                                  'Loading secondary LLM scores...',
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                              error: (_, __) => Text(
                                _tr(
                                  context,
                                  '2e LLM indisponible (fallback actif)',
                                  'Secondary LLM unavailable (fallback active)',
                                ),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Text(
                        _tr(
                          context,
                          'Chargement des scores ML...',
                          'Loading ML scores...',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                      error: (_, __) => const Text(
                        'ML indisponible (fallback heuristique actif)',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: 16,
                blur: 18,
                opacity: 0.1,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(
                        context,
                        'Metriques interactions',
                        'Interaction metrics',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          _tr(context, 'Likes', 'Likes'),
                          mergedTelemetry.likes.toString(),
                        ),
                        _chip(
                          _tr(context, 'Dislikes', 'Dislikes'),
                          mergedTelemetry.dislikes.toString(),
                        ),
                        _chip(
                          _tr(context, 'Taux acceptation', 'Acceptance rate'),
                          pct(mergedTelemetry.acceptanceRate),
                        ),
                        _chip(
                          _tr(context, 'Taux rejet', 'Rejection rate'),
                          pct(mergedTelemetry.rejectionRate),
                        ),
                        _chip(
                          _tr(context, 'Tenues vues', 'Outfits seen'),
                          mergedTelemetry.seen.toString(),
                        ),
                        _chip(
                          _tr(context, 'Ajouts favoris', 'Favorite adds'),
                          mergedTelemetry.favoriteAdds.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          ref.read(outfitTelemetryProvider.notifier).reset();
                        },
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: Text(
                          _tr(
                            context,
                            'Reset metriques locales',
                            'Reset local metrics',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 11,
        ),
      ),
    );
  }

  IconData _favoritesSyncIcon(OutfitFavoritesSyncStatus status) {
    switch (status) {
      case OutfitFavoritesSyncStatus.idle:
        return Icons.pause_circle_outline;
      case OutfitFavoritesSyncStatus.syncing:
        return Icons.sync;
      case OutfitFavoritesSyncStatus.synced:
        return Icons.cloud_done;
      case OutfitFavoritesSyncStatus.localOnly:
        return Icons.cloud_off;
      case OutfitFavoritesSyncStatus.error:
        return Icons.error_outline;
    }
  }

  Color _favoritesSyncColor(OutfitFavoritesSyncStatus status) {
    switch (status) {
      case OutfitFavoritesSyncStatus.idle:
        return Colors.white70;
      case OutfitFavoritesSyncStatus.syncing:
        return Colors.lightBlueAccent;
      case OutfitFavoritesSyncStatus.synced:
        return Colors.greenAccent;
      case OutfitFavoritesSyncStatus.localOnly:
        return Colors.amberAccent;
      case OutfitFavoritesSyncStatus.error:
        return Colors.redAccent;
    }
  }
}
