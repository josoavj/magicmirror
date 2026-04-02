import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/responsive_helper.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/outfit_provider.dart';
import '../../data/models/outfit_model.dart';

class OutfitRecommendationWidget extends ConsumerWidget {
  const OutfitRecommendationWidget({super.key, this.enableTts = true});

  final bool enableTts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedOutfits = ref.watch(suggestedOutfitsProvider);
    final settings = ref.watch(appSettingsProvider);

    // Écouter les changements pour déclencher la synthèse vocale
    if (enableTts) {
      ref.listen<List<OutfitSuggestion>>(suggestedOutfitsProvider, (
        previous,
        next,
      ) {
        if (next.isNotEmpty &&
            (previous == null ||
                previous.isEmpty ||
                next.first.id != previous.first.id)) {
          final outfit = next.first;
          final tts = ref.read(ttsServiceProvider);
          final isEnglish = settings.ttsLanguage.startsWith('en');
          final speech = isEnglish
              ? "Here is a suggestion for you: ${outfit.title}. ${outfit.reason}. I suggest wearing: ${outfit.items.join(', ')}."
              : "Voici une suggestion pour vous : ${outfit.title}. ${outfit.reason}. Je vous conseille de porter : ${outfit.items.join(', ')}.";
          tts.speak(
            speech,
            enabled: settings.enableAudioFeedback && settings.ttsEnabled,
            interruptCurrent: settings.ttsInterruptCurrent,
            language: settings.ttsLanguage,
            speechRate: settings.ttsSpeechRate,
            pitch: settings.ttsPitch,
            minRepeatInterval: Duration(seconds: settings.ttsMinRepeatSeconds),
          );
        }
      });
    }

    if (suggestedOutfits.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestedOutfits
            .map((outfit) => _OutfitCardWidget(outfit: outfit))
            .toList(),
      ),
    );
  }
}

class _OutfitCardWidget extends StatelessWidget {
  final OutfitSuggestion outfit;

  const _OutfitCardWidget({required this.outfit});

  @override
  Widget build(BuildContext context) {
    // Calcul responsive de la largeur
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = ResponsiveHelper.isMobile(context)
        ? (screenWidth * 0.7).clamp(200.0, 290.0)
        : 300.0;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GlassContainer(
        borderRadius: 22,
        blur: 32,
        opacity: 0.11,
        tintColor: Colors.tealAccent,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      outfit.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.resp(
                          context,
                          mobile: 15,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: ResponsiveHelper.resp(
                      context,
                      mobile: 18,
                      tablet: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                outfit.reason,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: ResponsiveHelper.resp(
                    context,
                    mobile: 11,
                    tablet: 13,
                  ),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(color: Colors.white24, height: 20),
              ...outfit.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.label_outline,
                        color: Colors.white70,
                        size: ResponsiveHelper.resp(
                          context,
                          mobile: 12,
                          tablet: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.resp(
                              context,
                              mobile: 12,
                              tablet: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: outfit.occasions
                    .map(
                      (occ) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          occ,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: ResponsiveHelper.resp(
                              context,
                              mobile: 9,
                              tablet: 10,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
