import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import '../../../../presentation/widgets/glass_container.dart';

class OutfitSuggestionScreen extends ConsumerWidget {
  const OutfitSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Suggestions de Tenue'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Recommandations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suggestions personnalisées basées sur vos préférences',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                _buildProfileContext(profile),

                const SizedBox(height: 24),

                // Outfit Cards
                ..._buildOutfitCards(profile),

                const SizedBox(height: 24),

                // Méteo actuelle
                _buildWeatherSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContext(UserProfile profile) {
    return GlassContainer(
      borderRadius: 20,
      blur: 25,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil applique',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.gender}, ${profile.age} ans, ${profile.morphology}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Styles preferes: ${profile.preferredStyles.join(', ')}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOutfitCards(UserProfile profile) {
    final ranked = _rankOutfits(profile);
    return ranked.map(_buildOutfitCard).toList();
  }

  List<_RankedOutfit> _rankOutfits(UserProfile profile) {
    final allOutfits = [
      _Outfit(
        title: 'Casual Moderne',
        description: 'Jeans + T-shirt léger',
        icon: Icons.checkroom,
        color: const Color(0xFF3B82F6),
        styles: const ['casual', 'minimaliste'],
        compatibleMorphologies: const [
          'Silhouette droite',
          'Hanches et epaules equilibrees',
        ],
        genderTargets: const ['all'],
        minAge: 16,
        maxAge: 60,
      ),
      _Outfit(
        title: 'Élégant',
        description: 'Chemise + Pantalon chino',
        icon: Icons.style,
        color: const Color(0xFF8B5CF6),
        styles: const ['elegant', 'business'],
        compatibleMorphologies: const [
          'Hanches et epaules equilibrees',
          'Epaules plus larges',
        ],
        genderTargets: const ['all'],
        minAge: 20,
        maxAge: 65,
      ),
      _Outfit(
        title: 'Sport',
        description: 'Legging + Hoodie',
        icon: Icons.sports,
        color: const Color(0xFF10B981),
        styles: const ['sport'],
        compatibleMorphologies: const [
          'Hanches plus marquees',
          'Taille tres marquee',
          'Silhouette droite',
        ],
        genderTargets: const ['all'],
        minAge: 12,
        maxAge: 50,
      ),
      _Outfit(
        title: 'Street Dynamics',
        description: 'Cargo + bomber oversize',
        icon: Icons.local_fire_department,
        color: const Color(0xFFEC4899),
        styles: const ['streetwear', 'casual'],
        compatibleMorphologies: const [
          'Epaules tres marquees',
          'Silhouette droite',
        ],
        genderTargets: const ['all'],
        minAge: 14,
        maxAge: 40,
      ),
      _Outfit(
        title: 'Business Smart',
        description: 'Blazer + pantalon taille haute',
        icon: Icons.business_center,
        color: const Color(0xFFF59E0B),
        styles: const ['business', 'elegant'],
        compatibleMorphologies: const [
          'Hanches tres marquees',
          'Hanches et epaules equilibrees',
          'Epaules plus larges',
        ],
        genderTargets: const ['all'],
        minAge: 24,
        maxAge: 70,
      ),
      _Outfit(
        title: 'Minimal Monochrome',
        description: 'Palette neutre + coupe clean',
        icon: Icons.layers,
        color: const Color(0xFF14B8A6),
        styles: const ['minimaliste', 'casual'],
        compatibleMorphologies: const ['all'],
        genderTargets: const ['all'],
        minAge: 18,
        maxAge: 80,
      ),
    ];

    final normalizedStyles = profile.preferredStyles
        .map(_normalizeStyle)
        .toSet();
    final normalizedGender = profile.gender.toLowerCase();

    final ranked = allOutfits.map((outfit) {
      var score = 0;
      final reasons = <String>[];

      if (outfit.styles.any(normalizedStyles.contains)) {
        score += 45;
        reasons.add('Correspond a vos styles');
      }

      if (profile.age >= outfit.minAge && profile.age <= outfit.maxAge) {
        score += 20;
        reasons.add('Adapte a votre tranche d\'age');
      }

      if (_matchesMorphology(
        profileMorphology: profile.morphology,
        compatibleMorphologies: outfit.compatibleMorphologies,
      )) {
        score += 25;
        reasons.add('Compatible avec votre morphologie');
      }

      final isGenderMatch =
          outfit.genderTargets.contains('all') ||
          outfit.genderTargets.any(
            (gender) => normalizedGender.contains(gender),
          );
      if (isGenderMatch) {
        score += 10;
      }

      return _RankedOutfit(outfit: outfit, score: score, reasons: reasons);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return ranked.take(4).toList();
  }

  String _normalizeStyle(String value) {
    final v = value.toLowerCase();
    if (v.contains('eleg')) {
      return 'elegant';
    }
    if (v.contains('mini')) {
      return 'minimaliste';
    }
    return v;
  }

  bool _matchesMorphology({
    required String profileMorphology,
    required List<String> compatibleMorphologies,
  }) {
    if (compatibleMorphologies.contains('all')) {
      return true;
    }

    final aliases = _morphologyAliases(profileMorphology);
    return compatibleMorphologies.any(aliases.contains);
  }

  Set<String> _morphologyAliases(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'Sablier (X)':
      case 'Hanches et epaules equilibrees':
        return {'Sablier (X)', 'Hanches et epaules equilibrees'};
      case 'Poire (A)':
      case 'Hanches plus marquees':
        return {'Poire (A)', 'Hanches plus marquees'};
      case 'Rectangulaire (H)':
      case 'Silhouette droite':
        return {'Rectangulaire (H)', 'Silhouette droite'};
      case 'Triangle Inverse (V)':
      case 'Epaules plus larges':
        return {'Triangle Inverse (V)', 'Epaules plus larges'};
      case 'Triangle Inverse+ (V+)':
      case 'Epaules tres marquees':
        return {'Triangle Inverse+ (V+)', 'Epaules tres marquees'};
      case 'Sablier+ (X+)':
      case 'Taille tres marquee':
        return {'Sablier+ (X+)', 'Taille tres marquee'};
      case 'Poire+ (A+)':
      case 'Hanches tres marquees':
        return {'Poire+ (A+)', 'Hanches tres marquees'};
      case 'Non definie':
      case 'Silhouette non definie':
        return {'Non definie', 'Silhouette non definie'};
      default:
        return {normalized};
    }
  }

  Widget _buildOutfitCard(_RankedOutfit rankedOutfit) {
    final outfit = rankedOutfit.outfit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [outfit.color, outfit.color.withValues(alpha: 0.6)],
                ),
              ),
              child: Center(
                child: Icon(outfit.icon, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outfit.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rankedOutfit.reasons
                        .map(
                          (reason) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              reason,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${rankedOutfit.score} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return GlassContainer(
      borderRadius: 20,
      blur: 25,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Conditions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.cloud_queue,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherStat('Temp', '22°C'),
              _buildWeatherStat('Humidité', '65%'),
              _buildWeatherStat('Vent', '12 km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Outfit {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> styles;
  final List<String> compatibleMorphologies;
  final List<String> genderTargets;
  final int minAge;
  final int maxAge;

  const _Outfit({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.styles,
    required this.compatibleMorphologies,
    required this.genderTargets,
    required this.minAge,
    required this.maxAge,
  });
}

class _RankedOutfit {
  final _Outfit outfit;
  final int score;
  final List<String> reasons;

  const _RankedOutfit({
    required this.outfit,
    required this.score,
    required this.reasons,
  });
}
