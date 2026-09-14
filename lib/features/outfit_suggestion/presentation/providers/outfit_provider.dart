import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/outfit_model.dart';
import '../../../ai_ml/presentation/providers/ml_provider.dart';

// Liste statique de tenues (simulant une base de données)
final allOutfitsProvider = Provider<List<OutfitSuggestion>>((ref) {
  return [
    OutfitSuggestion(
      id: '1',
      title: 'Business Casual',
      items: ['Blazer ajusté', 'Chemise blanche', 'Pantalon chino'],
      reason: 'Parfait pour équilibrer les épaules et les hanches.',
      temperatureRange: 20.0,
      weatherCondition: 'Ensoleillé',
      occasions: ['Travail', 'Réunion'],
      matchingBodyTypes: ['Sablier (X)', 'Rectangulaire'],
      suggestedAt: DateTime.now(),
    ),
    OutfitSuggestion(
      id: '2',
      title: 'Sportif Urbain',
      items: ['Sweat à capuche', 'Jean slim', 'Baskets'],
      reason: 'Ajoute du volume en bas pour compenser les épaules larges.',
      temperatureRange: 15.0,
      weatherCondition: 'Frais',
      occasions: ['Détente', 'Sortie'],
      matchingBodyTypes: ['Triangle Inversé (V)'],
      suggestedAt: DateTime.now(),
    ),
    OutfitSuggestion(
      id: '3',
      title: 'Soirée Élégante',
      items: ['Robe empire', 'Talons hauts', 'Pochette'],
      reason: 'Souligne la taille et floute les hanches.',
      temperatureRange: 22.0,
      weatherCondition: 'Clair',
      occasions: ['Dîner', 'Mariage'],
      matchingBodyTypes: ['Poire (A)'],
      suggestedAt: DateTime.now(),
    ),
    OutfitSuggestion(
      id: '4',
      title: 'Confort Quotidien',
      items: ['T-shirt col V', 'Pantalon droit', 'Cardigan'],
      reason: 'Vêtements structurés pour harmoniser la silhouette.',
      temperatureRange: 18.0,
      weatherCondition: 'Variable',
      occasions: ['Quotidien'],
      matchingBodyTypes: ['Rectangle (H)'],
      suggestedAt: DateTime.now(),
    ),
  ];
});

// Provider qui filtre les tenues en fonction de la morphologie détectée
final suggestedOutfitsProvider = Provider<List<OutfitSuggestion>>((ref) {
  final currentMorphology = ref.watch(currentMorphologyProvider);
  final allOutfits = ref.watch(allOutfitsProvider);

  if (currentMorphology == null) return [];

  return allOutfits.where((outfit) {
    return outfit.matchingBodyTypes.contains(currentMorphology.bodyType);
  }).toList();
});
