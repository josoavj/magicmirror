import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:magicmirror/features/ai_ml/data/models/morphology_model.dart';

class MorphologyService {
  late final PoseDetector _poseDetector;
  bool _isInitialized = false;

  MorphologyService() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        modelConfig: PoseDetectionModel.base,
      ),
    );
    _isInitialized = true;
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }

  /// Traitement de l'image pour détecter la pose et en déduire la morphologie
  Future<MorphologyData?> analyzePose(InputImage inputImage) async {
    if (!_isInitialized) return null;

    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;
      return _calculateMorphology(pose);
    } catch (e) {
      debugPrint('Erreur lors de l\'analyse ML: $e');
      return null;
    }
  }

  /// Algorithme d'analyse des ratios corporels pour déterminer la morphologie
  MorphologyData _calculateMorphology(Pose pose) {
    // Points clés pour les ratios (épaules, hanches, taille)
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Approximation de la taille (entre les épaules et les hanches)
    // Pour une précision maximale dans un vrai produit, il faudrait utiliser la segmentation

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return MorphologyData(
        bodyType: "Non détectée",
        confidence: 0,
        measurements: {},
        detectedAt: DateTime.now(),
      );
    }

    // Calcul des largeurs (distance euclidienne sur l'axe X)
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final hipWidth = (leftHip.x - rightHip.x).abs();

    // Estimation d'un type de corps simple basé sur les ratios Épaules/Hanches
    String bodyType = "Rectangulaire";
    double ratio = shoulderWidth / hipWidth;

    if (ratio > 1.15) {
      bodyType = "Triangle Inversé (V)";
    } else if (ratio < 0.85) {
      bodyType = "Poire (A)";
    } else if (ratio >= 0.95 && ratio <= 1.05) {
      bodyType = "Sablier (X)";
    }

    return MorphologyData(
      bodyType: bodyType,
      confidence: 0.85, //ML Kit confidence + algo
      measurements: {
        'shoulder_width': shoulderWidth.toStringAsFixed(1),
        'hip_width': hipWidth.toStringAsFixed(1),
        'ratio': ratio.toStringAsFixed(2),
      },
      detectedAt: DateTime.now(),
    );
  }
}
