/// Repository pour les suggestions de tenue
abstract class OutfitRepository {
  Future<dynamic> getSuggestions(
    String morphologyType,
    double temperature,
    String weatherCondition,
  );
  Future<dynamic> saveFavorite(String outfitId);
  Future<dynamic> getFavorites();
}
