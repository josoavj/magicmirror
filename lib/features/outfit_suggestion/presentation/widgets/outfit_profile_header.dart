import 'package:flutter/material.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';

class OutfitProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final String? detectedMorphology;

  const OutfitProfileHeader({
    super.key,
    required this.profile,
    this.detectedMorphology,
  });

  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white12,
              backgroundImage: profile.avatarUrl.startsWith('http')
                  ? NetworkImage(profile.avatarUrl)
                  : null,
              child: profile.avatarUrl.startsWith('http')
                  ? null
                  : Text(
                      profile.displayName.isEmpty
                          ? '?'
                          : profile.displayName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.gender} · ${profile.age} ${_tr(context, 'ans', 'years')} · ${profile.heightCm} cm',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.morphology} · ${profile.preferredStyles.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  if (detectedMorphology != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${_tr(context, 'Détectée par la caméra', 'Camera detected')} : $detectedMorphology',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
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
