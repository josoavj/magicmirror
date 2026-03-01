import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/outfit_provider.dart';
import '../../../presentation/widgets/glass_container.dart';

class OutfitRecommendationWidget extends ConsumerWidget {
  const OutfitRecommendationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedOutfits = ref.watch(suggestedOutfitsProvider);

    if (suggestedOutfits.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestedOutfits
            .map(
              (outfit) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GlassContainer(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            outfit.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        outfit.reason,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      ...outfit.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.label_outline,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  occ,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
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
            )
            .toList(),
      ),
    );
  }
}
