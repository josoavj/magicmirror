import 'package:flutter/material.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class MirrorOutfitBadge extends StatelessWidget {
  const MirrorOutfitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/outfit-suggestion'),
        child: GlassContainer(
          borderRadius: 18,
          blur: 18,
          opacity: 0.18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  Localizations.of<AppLocalizations>(context, AppLocalizations)
                          ?.outfitReadyBadge ??
                      'Full body detected - Outfits ready',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
