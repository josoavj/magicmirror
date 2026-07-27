import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_shared_providers.dart';
import 'package:magicmirror/features/settings/presentation/widgets/outfit_settings_widgets.dart';

class OutfitInsightsSettingsScreen extends ConsumerWidget {
  const OutfitInsightsSettingsScreen({super.key});

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(outfitTelemetryProvider);
    final strictMode = ref.watch(outfitStrictWeatherModeProvider);

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
              OutfitSettingsSection(
                title: _tr(context, 'Moteur', 'Engine'),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        _tr(context, 'Mode strict', 'Strict mode'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: strictMode,
                      onChanged: (val) {
                        ref
                            .read(outfitStrictWeatherModeProvider.notifier)
                            .state = val;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutfitSettingsSection(
                title: _tr(context, 'Statistiques', 'Metrics'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Likes: ${telemetry.likes}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Dislikes: ${telemetry.dislikes}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Vues: ${telemetry.seen}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.read(outfitTelemetryProvider.notifier).reset();
                      },
                      child: Text(_tr(context, 'Réinitialiser', 'Reset')),
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
}
