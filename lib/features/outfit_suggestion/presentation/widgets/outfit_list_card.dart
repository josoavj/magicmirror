import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class OutfitListCard extends ConsumerWidget {
  final RankedOutfit rankedOutfit;
  final bool isFavorite;

  const OutfitListCard({
    super.key,
    required this.rankedOutfit,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfit = rankedOutfit.outfit;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 16,
        blur: 20,
        opacity: 0.1,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(outfit.icon, color: outfit.color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    outfit.quickSummary,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.pink : Colors.white70,
              ),
              onPressed:
                  () => ref
                      .read(outfitFavoritesProvider.notifier)
                      .toggleFavorite(outfit.id),
            ),
          ],
        ),
      ),
    );
  }
}
