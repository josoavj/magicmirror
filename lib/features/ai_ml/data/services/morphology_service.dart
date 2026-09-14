import 'dart:math';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/features/ai_ml/data/models/morphology_model.dart';

class MorphologyService {
  late final PoseDetector _poseDetector;
  bool _isInitialized = false;

  // Stabilisation: garder la dernière confiance et mesures
  MorphologyData? _lastMorphology;
  final int _stabilizationFrames = 5;
  int _frameCounter = 0;

  // Variables pour stabilisation avec moyenne mobile
  final List<double> _ratioHistory = [];
  final List<double> _confidenceHistory = [];
  final int _historySize = 10; // Garder les 10 dernières mesures

  MorphologyService() {
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );
      _isInitialized = true;
      logger.info('PoseDetector initialise', tag: 'MorphologyService');
    } catch (e) {
      logger.error(
        'Erreur init PoseDetector',
        tag: 'MorphologyService',
        error: e,
      );
      _isInitialized = false;
    }
  }

  Future<void> dispose() async {
    try {
      await _poseDetector.close();
      logger.info('PoseDetector dispose', tag: 'MorphologyService');
    } catch (e) {
      logger.error(
        'Erreur fermeture PoseDetector',
        tag: 'MorphologyService',
        error: e,
      );
    }
  }

  /// Traitement de l'image pour détecter la pose
  Future<MorphologyData?> analyzePose(InputImage inputImage) async {
    if (!_isInitialized) {
      logger.warning('PoseDetector non init', tag: 'MorphologyService');
      return null;
    }

    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) {
        return null;
      }

      final pose = poses.first;
      if (!_isValidPose(pose)) {
        // BUG FIX #5: Ne pas retourner les données périmées si pose invalide
        return null;
      }

      final morphology = _calculateMorphology(pose);

      // Stabilisation
      _frameCounter++;
      if (_frameCounter >= _stabilizationFrames) {
        _lastMorphology = morphology;
        _frameCounter = 0;
        return morphology;
      }

      return _lastMorphology;
    } catch (e) {
      logger.error('Erreur analyse ML', tag: 'MorphologyService', error: e);
      return null;
    }
  }

  /// Vérifie que la pose est valide - Points essentiels requis
  bool _isValidPose(Pose pose) {
    final requiredLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      // Ajout pour meilleure précision
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];

    for (final landmark in requiredLandmarks) {
      if (pose.landmarks[landmark] == null) {
        return false;
      }
    }
    return true;
  }

  /// Calcule la confiance en fonction de la stabilité des landmarks
  /// Plus les points clés sont proches de la normale, plus la confiance est haute
  double _calculateConfidence(Pose pose, double baseRatio) {
    try {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

      if (leftShoulder == null || rightShoulder == null) {
        return 0;
      }

      // Vérifier la symétrie: si épaules sont symétriques, bonne détection
      final leftY = leftShoulder.y;
      final rightY = rightShoulder.y;
      final yDifference = (leftY - rightY).abs();

      // Normalisation de la différence Y (0-50 pixels = bon)
      final yConfidence = (1.0 - (yDifference / 50).clamp(0, 1)) * 100;

      // Vérifier si le ratio est dans une plage normale (0.7-1.5)
      double ratioConfidence = 100;
      if (baseRatio > 1.5 || baseRatio < 0.7) {
        ratioConfidence = 50; // Ratio anormal = moins sûr
      } else if (baseRatio > 1.3 || baseRatio < 0.8) {
        ratioConfidence = 75; // Ratio limite = moyen
      }

      // Moyenne : stabilité + ratio
      // BUG FIX #2: Garantir confiance entre 0-100
      return ((yConfidence + ratioConfidence) / 2).clamp(0, 100);
    } catch (e) {
      logger.error(
        'Erreur calcul confiance',
        tag: 'MorphologyService',
        error: e,
      );
      return 50; // Valeur par défaut conservative
    }
  }

  /// Applique une moyenne mobile + détection d'outliers pour le ratio
  double _calculateStabilizedRatio(double newRatio) {
    _ratioHistory.add(newRatio);
    if (_ratioHistory.length > _historySize) {
      _ratioHistory.removeAt(0);
    }

    if (_ratioHistory.length < 3) {
      return newRatio; // BUG FIX #9: Besoin min 3 pour calcul valide
    }

    // Calcule moyenne et écart-type
    double mean = _ratioHistory.reduce((a, b) => a + b) / _ratioHistory.length;
    double variance =
        _ratioHistory
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        _ratioHistory.length;
    double stdDev = sqrt(
      variance.clamp(0.0001, double.infinity),
    ); // BUG FIX: Éviter sqrt(0)

    // BUG FIX #9: Utiliser une threshold adaptative au lieu de hardcoded 2.0
    final threshold = stdDev > 0 ? 2.0 * stdDev : 0.1;

    // Détecte les outliers (valeur trop loin de la moyenne)
    if ((newRatio - mean).abs() > threshold) {
      logger.debug(
        'Ratio outlier détecté: $newRatio vs moyenne $mean (écart: ${(newRatio - mean).abs()})',
        tag: 'MorphologyService',
      );
      return mean; // Ignorer outlier, garder la moyenne
    }

    return newRatio; // Nouvelle valeur est OK
  }

  /// Applique une moyenne mobile pour la confiance
  double _calculateStabilizedConfidence(double newConfidence) {
    _confidenceHistory.add(newConfidence);
    if (_confidenceHistory.length > _historySize) {
      _confidenceHistory.removeAt(0);
    }

    // Simple moyenne mobile
    return _confidenceHistory.reduce((a, b) => a + b) /
        _confidenceHistory.length;
  }

  /// Calcule des ratios avancés pour morphologie précise
  String _classifyAdvancedMorphology({
    required double shoulderWidth,
    required double elbowWidth,
    required double hipWidth,
  }) {
    double shoulderHipRatio = shoulderWidth / (hipWidth + 0.001);
    double shoulderElbowRatio = shoulderWidth / (elbowWidth + 0.001);

    // Classification avancée avec plus de critères

    // V+: Épaules beaucoup plus larges
    if (shoulderHipRatio > 1.3 && shoulderElbowRatio > 1.15) {
      return 'Triangle Inverse+ (V+)';
    }
    // V: Épaules plus larges que hanches
    if (shoulderHipRatio > 1.15) {
      return 'Triangle Inverse (V)';
    }
    // Sablier+: Symétrique avec taille fine
    if (shoulderHipRatio >= 0.95 &&
        shoulderHipRatio <= 1.05 &&
        shoulderElbowRatio > 1.25) {
      return 'Sablier+ (X+)';
    }
    // Sablier: Équilibré
    if (shoulderHipRatio >= 0.90 && shoulderHipRatio <= 1.10) {
      return 'Sablier (X)';
    }
    // Triangle: Hanches plus larges
    if (shoulderHipRatio < 0.90 && shoulderHipRatio > 0.75) {
      return 'Poire (A)';
    }
    // Triangle+: Hanches beaucoup plus larges
    if (shoulderHipRatio <= 0.75) {
      return 'Poire+ (A+)';
    }
    // Rectangle: Peu de différence
    return 'Rectangulaire (H)';
  }

  /// Calcule la hauteur estimée de la pose
  double _calculateHeightEstimate(Pose pose) {
    try {
      final head = pose.landmarks[PoseLandmarkType.nose];
      final feet = pose.landmarks[PoseLandmarkType.leftAnkle];

      // BUG FIX #1: Vérification stricte null + try-catch
      if (head == null || feet == null) {
        logger.debug(
          'Landmarks manquants pour hauteur',
          tag: 'MorphologyService',
        );
        return 0.0;
      }

      // BUG FIX #1: Vérifier que les valeurs sont valides (pas NaN/Infinity)
      if (!head.y.isFinite || !feet.y.isFinite) {
        return 0.0;
      }

      // Distance en pixels (relative à la frame)
      final heightPixels = (head.y - feet.y).abs();
      return heightPixels.isFinite ? heightPixels : 0.0;
    } catch (e) {
      logger.error('Erreur calcul hauteur', tag: 'MorphologyService', error: e);
      return 0.0;
    }
  }

  /// Calcule la symétrie du corps (0-100%, plus c'est close de 100, plus c'est symétrique)
  double _calculateSymmetryScore(Pose pose) {
    try {
      double asymmetries = 0;
      int validPairs = 0;

      // Points symétriques à comparer
      final symmetricPairs = [
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
        (PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow),
        (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
        (PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee),
      ];

      for (final pair in symmetricPairs) {
        final left = pose.landmarks[pair.$1];
        final right = pose.landmarks[pair.$2];

        if (left is PoseLandmark && right is PoseLandmark) {
          // BUG FIX #1: Vérifier que les valeurs sont valides
          if (left.y.isFinite && right.y.isFinite) {
            // Mesure l'asymétrie verticale (plus la différence Y est grande, plus asymétrique)
            final yDiff = (left.y - right.y).abs();
            asymmetries += yDiff;
            validPairs++;
          }
        }
      }

      // BUG FIX #9: Gérer le cas où aucune paire valide n'existe
      if (validPairs == 0) return 0.0;

      // Normaliser à une note de symétrie (0-100)
      // Plus asymmetries est grand, plus la note baisse
      return (100 - (asymmetries.clamp(0, 200) / 200) * 100).clamp(0, 100);
    } catch (e) {
      logger.error(
        'Erreur calcul symétrie',
        tag: 'MorphologyService',
        error: e,
      );
      return 0.0;
    }
  }

  /// Calcule la qualité globale de la pose
  int _calculatePoseQuality(Pose pose) {
    try {
      final detectedLandmarks = pose.landmarks.entries
          // ignore: unnecessary_null_comparison
          .where((entry) => entry.value != null)
          .length;

      // BUG FIX #1: Vérifier que le divisor n'est pas 0
      if (detectedLandmarks == 0) {
        return 0;
      }

      // Max 33 landmarks dans google_ml_kit
      final qualityPercent = (detectedLandmarks / 33) * 100;
      return qualityPercent.round().clamp(0, 100);
    } catch (e) {
      logger.error(
        'Erreur calcul qualité pose',
        tag: 'MorphologyService',
        error: e,
      );
      return 0;
    }
  }

  /// Calcule la morphologie
  MorphologyData _calculateMorphology(Pose pose) {
    try {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

      if (leftShoulder == null ||
          rightShoulder == null ||
          leftElbow == null ||
          rightElbow == null ||
          leftHip == null ||
          rightHip == null) {
        return MorphologyData(
          bodyType: 'Non detectee',
          confidence: 0,
          measurements: {},
          detectedAt: DateTime.now(),
        );
      }

      // Mesures élargies (4 → 8 points)
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final elbowWidth = (leftElbow.x - rightElbow.x).abs();
      final hipWidth = (leftHip.x - rightHip.x).abs();

      // Classification avancée
      String bodyType = _classifyAdvancedMorphology(
        shoulderWidth: shoulderWidth,
        elbowWidth: elbowWidth,
        hipWidth: hipWidth,
      );

      // Ratio pour stabilisation
      double ratio = shoulderWidth / (hipWidth + 0.001);

      // Calcule la confiance réelle basée sur la stabilité et le ratio
      double rawConfidence = _calculateConfidence(pose, ratio);

      // Applique la stabilisation
      final stabilizedRatio = _calculateStabilizedRatio(ratio);
      final stabilizedConfidence = _calculateStabilizedConfidence(
        rawConfidence,
      );

      // Calcule les mesures détaillées
      final heightEstimate = _calculateHeightEstimate(pose);
      final symmetryScore = _calculateSymmetryScore(pose);
      final poseQuality = _calculatePoseQuality(pose);

      return MorphologyData(
        bodyType: bodyType,
        confidence: stabilizedConfidence,
        measurements: {
          'shoulder_width': shoulderWidth.toStringAsFixed(1),
          'elbow_width': elbowWidth.toStringAsFixed(1),
          'hip_width': hipWidth.toStringAsFixed(1),
          'ratio_shoulder_hip': stabilizedRatio.toStringAsFixed(2),
          'ratio_shoulder_elbow': (shoulderWidth / (elbowWidth + 0.001))
              .toStringAsFixed(2),
          'height_estimate': heightEstimate.toStringAsFixed(0),
          'symmetry_score': symmetryScore.toStringAsFixed(1),
          'pose_quality': '$poseQuality%',
        },
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error(
        'Erreur calcul morphologie',
        tag: 'MorphologyService',
        error: e,
      );
      return MorphologyData(
        bodyType: 'Erreur',
        confidence: 0,
        measurements: {},
        detectedAt: DateTime.now(),
      );
    }
  }

  MorphologyData? getLastMorphology() => _lastMorphology;
}
