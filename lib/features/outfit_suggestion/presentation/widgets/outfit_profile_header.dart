import 'package:flutter/material.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class OutfitProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const OutfitProfileHeader({super.key, required this.profile});

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      blur: 25,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(context, 'Votre Profil', 'Your Profile'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.gender}, ${profile.age} ${_tr(context, 'ans', 'years')}, ${profile.morphology}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
