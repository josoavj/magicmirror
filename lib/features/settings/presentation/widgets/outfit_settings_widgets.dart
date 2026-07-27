import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class OutfitSettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const OutfitSettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blur: 18,
      opacity: 0.1,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
