import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_favorites_provider.dart';

class OutfitListCard extends ConsumerWidget {
  final RankedOutfit rankedOutfit;
  final bool isFavorite;

  const OutfitListCard({
    super.key,
    required this.rankedOutfit,
    required this.isFavorite,
  });

  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfit = rankedOutfit.outfit;
    final personalization = ref.read(outfitPersonalizationProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: CircleAvatar(
            backgroundColor: outfit.color.withValues(alpha: 0.2),
            child: Icon(outfit.icon, color: outfit.color),
          ),
          title: Text(
            outfit.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${outfit.outfitType} · ${outfit.quickSummary}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isFavorite
                    ? _tr(context, 'Retirer des favoris', 'Remove favorite')
                    : _tr(context, 'Ajouter aux favoris', 'Add favorite'),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.pinkAccent : Colors.white70,
                ),
                onPressed: () => ref
                    .read(outfitFavoritesProvider.notifier)
                    .toggleFavorite(outfit.id),
              ),
              const Icon(Icons.expand_more, color: Colors.white54),
            ],
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                outfit.description,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            _piece(
              context,
              Icons.checkroom,
              _tr(context, 'Haut', 'Top'),
              outfit.topPiece,
            ),
            _piece(
              context,
              Icons.content_cut,
              _tr(context, 'Bas', 'Bottom'),
              outfit.bottomPiece,
            ),
            _piece(
              context,
              Icons.directions_walk,
              _tr(context, 'Chaussures', 'Shoes'),
              outfit.shoesPiece,
            ),
            if (outfit.layerPiece.trim().isNotEmpty)
              _piece(
                context,
                Icons.layers_outlined,
                _tr(context, 'Couche extérieure', 'Outer layer'),
                outfit.layerPiece,
              ),
            if (outfit.accessoryPieces.isNotEmpty)
              _piece(
                context,
                Icons.auto_awesome,
                _tr(context, 'Accessoires', 'Accessories'),
                outfit.accessoryPieces.join(', '),
              ),
            const SizedBox(height: 10),
            if (outfit.styles.isNotEmpty)
              _tagGroup(
                context,
                _tr(context, 'Styles', 'Styles'),
                outfit.styles,
              ),
            if (outfit.compatibleMorphologies.isNotEmpty &&
                !outfit.compatibleMorphologies.contains('all'))
              _tagGroup(
                context,
                _tr(
                  context,
                  'Morphologies compatibles',
                  'Compatible body shapes',
                ),
                outfit.compatibleMorphologies,
              ),
            if (rankedOutfit.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _tr(context, 'Pourquoi cette tenue ?', 'Why this outfit?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...rankedOutfit.reasons
                  .take(4)
                  .map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 15,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const Divider(color: Colors.white24, height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tr(
                      context,
                      'Cette suggestion vous convient ?',
                      'Is this suggestion useful?',
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: _tr(context, 'Oui', 'Yes'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => personalization.recordFeedback(
                    outfitId: outfit.id,
                    styles: outfit.styles,
                    positive: true,
                  ),
                  icon: const Icon(
                    Icons.thumb_up_alt_outlined,
                    color: Colors.lightGreenAccent,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: _tr(context, 'Non', 'No'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => personalization.recordFeedback(
                    outfitId: outfit.id,
                    styles: outfit.styles,
                    positive: false,
                  ),
                  icon: const Icon(
                    Icons.thumb_down_alt_outlined,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _piece(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _tagGroup(BuildContext context, String label, List<String> values) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          runSpacing: 3,
          children: [
            Text(
              '$label :',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            ...values.map(
              (value) => Chip(
                label: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: BorderSide.none,
              ),
            ),
          ],
        ),
      );
}
