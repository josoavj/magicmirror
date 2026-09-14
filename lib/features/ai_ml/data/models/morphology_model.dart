/// Modèle pour représenter les données de morphologie détectées
class MorphologyData {
  final String bodyType; // ex: "Poire", "Sablier", "Rectangulaire"
  final double confidence; // 0-100
  final Map<String, dynamic> measurements;
  final DateTime detectedAt;

  MorphologyData({
    required this.bodyType,
    required this.confidence,
    required this.measurements,
    required this.detectedAt,
  });
}
