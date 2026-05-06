/// Modèle pour représenter les données de morphologie détectées
class MorphologyData {
  final String bodyType; // ex: "Poire (A)", "Sablier (X)", "Rectangulaire (H)"
  final double confidence; // 0-100
  final Map<String, dynamic> measurements;
  final DateTime detectedAt;

  const MorphologyData({
    required this.bodyType,
    required this.confidence,
    required this.measurements,
    required this.detectedAt,
  });

  // --- Sérialisation ---

  factory MorphologyData.fromJson(Map<String, dynamic> json) {
    return MorphologyData(
      bodyType: json['body_type'] as String? ?? 'Non détectée',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      measurements: (json['measurements'] as Map<String, dynamic>?) ?? {},
      detectedAt: json['detected_at'] != null
          ? DateTime.parse(json['detected_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'body_type': bodyType,
        'confidence': confidence,
        'measurements': measurements,
        'detected_at': detectedAt.toIso8601String(),
      };

  // --- Copie immutable ---

  MorphologyData copyWith({
    String? bodyType,
    double? confidence,
    Map<String, dynamic>? measurements,
    DateTime? detectedAt,
  }) {
    return MorphologyData(
      bodyType: bodyType ?? this.bodyType,
      confidence: confidence ?? this.confidence,
      measurements: measurements ?? Map.from(this.measurements),
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }

  // --- Égalité structurelle ---

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MorphologyData) return false;
    return bodyType == other.bodyType &&
        confidence == other.confidence &&
        detectedAt == other.detectedAt;
  }

  @override
  int get hashCode => Object.hash(bodyType, confidence, detectedAt);

  @override
  String toString() =>
      'MorphologyData(bodyType: $bodyType, confidence: ${confidence.toStringAsFixed(1)}%, '
      'measurements: ${measurements.length} fields, detectedAt: $detectedAt)';
}
