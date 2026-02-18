/// Modèle pour une suggestion de tenue
class OutfitSuggestion {
  final String id;
  final List<String> items; // Liste des vêtements suggérés
  final String reason; // Explication de la suggestion
  final double temperatureRange; // Température recommandée
  final String weatherCondition;
  final List<String> occasions; // Occasions/types d'événement
  final DateTime suggestedAt;

  OutfitSuggestion({
    required this.id,
    required this.items,
    required this.reason,
    required this.temperatureRange,
    required this.weatherCondition,
    required this.occasions,
    required this.suggestedAt,
  });
}
