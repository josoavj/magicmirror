import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/outfit_model.dart';
import '../../../ai_ml/presentation/providers/ml_provider.dart';
import '../../../user_profile/presentation/providers/user_profile_provider.dart';
import '../../../weather/presentation/widgets/weather_widget.dart';
import 'outfit_suggestion_shared_providers.dart';

// Liste statique enrichie de tenues (simulant une base de données avec styles et genres)
final allOutfitsProvider = Provider<List<OutfitSuggestion>>((ref) {
  final now = DateTime.now();
  return [
    // Tenues HOMME
    OutfitSuggestion(
      id: 'h_business_1',
      title: 'Business Classique',
      items: ['Costume bleu marine', 'Chemise blanche', 'Derbies cuir'],
      reason: 'Structure la silhouette et donne de la prestance.',
      temperatureRange: 18.0,
      weatherCondition: 'Variable',
      occasions: ['Travail', 'Réunion'],
      matchingBodyTypes: ['Sablier (X)', 'Rectangulaire', 'Triangle Inverse (V)'],
      genderTargets: ['homme', 'all'],
      styles: ['business', 'elegant'],
      suggestedAt: now,
    ),
    OutfitSuggestion(
      id: 'h_casual_1',
      title: 'Casual Printemps',
      items: ['Polo ajusté', 'Chino beige', 'Sneakers blanches'],
      reason: 'Confortable tout en gardant une ligne propre.',
      temperatureRange: 22.0,
      weatherCondition: 'Ensoleillé',
      occasions: ['Quotidien', 'Sortie'],
      matchingBodyTypes: ['Rectangulaire', 'Sablier (X)'],
      genderTargets: ['homme', 'all'],
      styles: ['casual', 'minimaliste'],
      suggestedAt: now,
    ),
    OutfitSuggestion(
      id: 'h_street_1',
      title: 'Streetwear Oversize',
      items: ['Hoodie ample', 'Cargo pants', 'Sneakers chunky'],
      reason: 'Ajoute du volume en bas pour équilibrer les épaules.',
      temperatureRange: 15.0,
      weatherCondition: 'Frais',
      occasions: ['Détente', 'Urbain'],
      matchingBodyTypes: ['Triangle Inverse (V)', 'Triangle Inverse+ (V+)'],
      genderTargets: ['homme', 'all'],
      styles: ['streetwear', 'sport'],
      suggestedAt: now,
    ),

    // Tenues FEMME
    OutfitSuggestion(
      id: 'f_elegant_1',
      title: 'Soirée Élégante',
      items: ['Robe empire', 'Talons hauts', 'Pochette'],
      reason: 'Souligne la taille et floute les hanches.',
      temperatureRange: 24.0,
      weatherCondition: 'Clair',
      occasions: ['Dîner', 'Soirée'],
      matchingBodyTypes: ['Poire (A)', 'Poire+ (A+)', 'Sablier (X)'],
      genderTargets: ['femme', 'all'],
      styles: ['elegant', 'chic'],
      suggestedAt: now,
    ),
    OutfitSuggestion(
      id: 'f_casual_1',
      title: 'Casual Chic',
      items: ['Blouse fluide', 'Jeans taille haute', 'Bottines'],
      reason: 'Marque la taille tout en allongeant les jambes.',
      temperatureRange: 16.0,
      weatherCondition: 'Variable',
      occasions: ['Quotidien', 'Travail'],
      matchingBodyTypes: ['Sablier (X)', 'Poire (A)', 'Rectangulaire'],
      genderTargets: ['femme', 'all'],
      styles: ['casual', 'elegant'],
      suggestedAt: now,
    ),
    OutfitSuggestion(
      id: 'f_street_1',
      title: 'Urbain Dynamique',
      items: ['Crop top', 'Pantalon large', 'Sneakers'],
      reason: 'Met en valeur le buste et équilibre la silhouette.',
      temperatureRange: 26.0,
      weatherCondition: 'Ensoleillé',
      occasions: ['Sortie', 'Détente'],
      matchingBodyTypes: ['Triangle Inverse (V)', 'Rectangulaire'],
      genderTargets: ['femme', 'all'],
      styles: ['streetwear', 'casual'],
      suggestedAt: now,
    ),

    // Tenues UNISEXE / HIVER
    OutfitSuggestion(
      id: 'u_winter_1',
      title: 'Grand Froid',
      items: ['Manteau long en laine', 'Pull col roulé', 'Pantalon épais', 'Bottes'],
      reason: 'Coupe structurée qui maintient la chaleur sans casser la ligne.',
      temperatureRange: 5.0,
      weatherCondition: 'Froid',
      occasions: ['Quotidien', 'Travail'],
      matchingBodyTypes: ['Sablier (X)', 'Rectangulaire', 'Poire (A)', 'Triangle Inverse (V)'],
      genderTargets: ['homme', 'femme', 'all'],
      styles: ['casual', 'elegant', 'minimaliste'],
      suggestedAt: now,
    ),
    OutfitSuggestion(
      id: 'u_sport_1',
      title: 'Sportif Actif',
      items: ['Veste coupe-vent', 'T-shirt technique', 'Legging / Jogging'],
      reason: 'Coupe athlétique pour la liberté de mouvement.',
      temperatureRange: 12.0,
      weatherCondition: 'Nuageux',
      occasions: ['Sport', 'Détente'],
      matchingBodyTypes: ['Sablier (X)', 'Rectangulaire', 'Triangle Inverse (V)', 'Poire (A)'],
      genderTargets: ['homme', 'femme', 'all'],
      styles: ['sport'],
      suggestedAt: now,
    ),
  ];
});

/// Fonction utilitaire pour vérifier si les chaînes se correspondent (insensible à la casse)
bool _matchesTokens(String value, List<String> targets) {
  if (targets.isEmpty || targets.contains('all')) return true;
  final normalizedValue = value.toLowerCase().trim();
  return targets.any((t) => normalizedValue.contains(t.toLowerCase().trim()) || t.toLowerCase().trim().contains(normalizedValue));
}

/// Fonction utilitaire pour vérifier l'intersection de deux listes
bool _hasIntersection(List<String> list1, List<String> list2) {
  if (list1.isEmpty || list2.isEmpty) return true; // Si l'un est vide, pas de restriction stricte
  for (final item in list1) {
    if (_matchesTokens(item, list2)) return true;
  }
  return false;
}

// Provider qui filtre les tenues en fonction de : la morphologie détectée, le profil utilisateur, et la météo.
final suggestedOutfitsProvider = Provider<List<OutfitSuggestion>>((ref) {
  final currentMorphology = ref.watch(currentMorphologyProvider);
  final userProfile = ref.watch(userProfileProvider);
  final weatherAsync = ref.watch(currentWeatherProvider);
  final mlScoreMapAsync = ref.watch(outfitMlScoreMapProvider);
  final llmScoreMapAsync = ref.watch(outfitSecondaryLlmScoreMapProvider);
  final allOutfits = ref.watch(allOutfitsProvider);

  // 1. Déterminer la morphologie (priorité à la caméra, sinon profil)
  final bodyType = currentMorphology?.bodyType ?? userProfile.morphology;
  if (bodyType.isEmpty || bodyType == 'Inconnu') return [];

  // Extraire les maps de scores (elles seront rechargées de manière asynchrone)
  final mlScoreMap = mlScoreMapAsync.maybeWhen(data: (d) => d, orElse: () => const <String, double>{});
  final llmScoreMap = llmScoreMapAsync.maybeWhen(data: (d) => d, orElse: () => const <String, double>{});

  var filteredList = allOutfits.where((outfit) {
    // A. Filtrage par Morphologie
    bool matchMorphology = outfit.matchingBodyTypes.any((bt) => 
        bt.toLowerCase().contains(bodyType.toLowerCase()) || 
        bodyType.toLowerCase().contains(bt.toLowerCase()));
    
    if (!matchMorphology && outfit.matchingBodyTypes.isNotEmpty) return false;

    // B. Filtrage par Genre (Profil Supabase)
    if (userProfile.gender.isNotEmpty) {
      final gender = userProfile.gender.toLowerCase();
      // On accepte si l'outfit cible le genre de l'utilisateur, ou si l'utilisateur est 'non-binaire' (accepte all), ou si l'outfit est 'all'
      bool matchGender = outfit.genderTargets.contains('all') || 
                         _matchesTokens(gender, outfit.genderTargets) ||
                         gender.contains('binaire') || gender.contains('autre');
      if (!matchGender) return false;
    }

    // C. Filtrage par Styles préférés (Profil Supabase)
    if (userProfile.preferredStyles.isNotEmpty && outfit.styles.isNotEmpty) {
      bool matchStyle = _hasIntersection(outfit.styles, userProfile.preferredStyles);
      if (!matchStyle) return false;
    }

    // D. Filtrage par Météo (si disponible)
    bool isWeatherCompatible = true;
    weatherAsync.whenData((weather) {
      if (weather != null) {
        // Logique de température très basique
        final tempDiff = (outfit.temperatureRange - weather.temperature).abs();
        // Si l'écart de température est trop grand (ex: manteau d'hiver à 30°C), on pénalise ou filtre
        // Ici on filtre si l'écart est > 12 degrés
        if (tempDiff > 12.0) {
           isWeatherCompatible = false;
        }
      }
    });

    if (!isWeatherCompatible) return false;

    return true;
  }).toList();

  // 2. Trier par score LLM / ML
  filteredList.sort((a, b) {
    final scoreAMl = mlScoreMap[a.id] ?? 0.0;
    final scoreALlm = llmScoreMap[a.id] ?? 0.0;
    final totalA = scoreAMl + scoreALlm;

    final scoreBMl = mlScoreMap[b.id] ?? 0.0;
    final scoreBLlm = llmScoreMap[b.id] ?? 0.0;
    final totalB = scoreBMl + scoreBLlm;

    return totalB.compareTo(totalA); // Tri décroissant (le plus grand score en premier)
  });

  return filteredList;
});
