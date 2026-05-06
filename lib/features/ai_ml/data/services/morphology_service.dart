import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/features/ai_ml/data/models/morphology_model.dart';

class MorphologyService {
  // (late final levait une LateInitializationError si le constructeur échouait)
  PoseDetector? _poseDetector;
  bool _isInitialized = false;

  // Stabilisation: garder la dernière confiance et mesures
  MorphologyData? _lastMorphology;
  final int _stabilizationFrames = 5;
  int _frameCounter = 0;

  // Variables pour stabilisation avec moyenne mobile
  final List<double> _ratioHistory = [];
  final List<double> _confidenceHistory = [];
  final int _historySize = 10;
  int _outlierLogCounter = 0;

  MorphologyService() {
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );
      _isInitialized = true;
      logger.info('PoseDetector initialisé', tag: 'MorphologyService');
    } catch (e) {
      logger.error('Erreur init PoseDetector', tag: 'MorphologyService', error: e);
      _isInitialized = false;
    }
  }

  Future<void> dispose() async {
    try {
      await _poseDetector?.close(); 
      _poseDetector = null;
      _isInitialized = false;
      logger.info('PoseDetector disposé', tag: 'MorphologyService');
    } catch (e) {
      logger.error('Erreur fermeture PoseDetector', tag: 'MorphologyService', error: e);
    }
  }

  /// Traitement de l'image pour détecter la pose
  Future<MorphologyData?> analyzePose(
    InputImage inputImage, {
    required int frameWidth,
    required int frameHeight,
  }) async {
    if (!_isInitialized || _poseDetector == null) {
      logger.warning('PoseDetector non initialisé', tag: 'MorphologyService');
      return null;
    }

    try {
      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;
      if (!_isValidPose(pose)) return null;

      final rawData = await compute(
        _computeRawMorphologyData,
        {'pose': pose, 'frameWidth': frameWidth, 'frameHeight': frameHeight},
      );

      final morphology = _buildFinalMorphology(rawData);

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

  /// Vérifie que la pose est valide — points essentiels + likelihood > 0.6
  bool _isValidPose(Pose pose) {
    final requiredLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,  // Force corps complet visible
      PoseLandmarkType.rightAnkle,
    ];
    for (final type in requiredLandmarks) {
      final landmark = pose.landmarks[type];
      if (landmark == null || landmark.likelihood < 0.6) return false;
    }
    return true;
  }

  /// Moyenne mobile + détection d'outliers (seuil 2σ adaptatif) pour le ratio
  double _calculateStabilizedRatio(double newRatio) {
    _ratioHistory.add(newRatio);
    if (_ratioHistory.length > _historySize) _ratioHistory.removeAt(0);
    if (_ratioHistory.length < 3) return newRatio;

    final mean = _ratioHistory.reduce((a, b) => a + b) / _ratioHistory.length;
    final variance = _ratioHistory
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        _ratioHistory.length;
    final stdDev = sqrt(variance.clamp(0.0001, double.infinity));
    final threshold = stdDev > 0 ? 2.0 * stdDev : 0.1;

    if ((newRatio - mean).abs() > threshold) {
      _outlierLogCounter++;
      if (_outlierLogCounter % 20 == 0) {
        logger.debug(
          'Ratio outlier: $newRatio vs moyenne $mean',
          tag: 'MorphologyService',
        );
      }
      return mean;
    }
    return newRatio;
  }

  /// Moyenne mobile pour la confiance
  double _calculateStabilizedConfidence(double newConfidence) {
    _confidenceHistory.add(newConfidence);
    if (_confidenceHistory.length > _historySize) _confidenceHistory.removeAt(0);
    return _confidenceHistory.reduce((a, b) => a + b) / _confidenceHistory.length;
  }

  /// Construit l'objet final (thread principal — accès à l'état de stabilisation)
  MorphologyData _buildFinalMorphology(Map<String, dynamic> rawData) {
    try {
      if (rawData['error'] == true) {
        return MorphologyData(
          bodyType: 'Non détectée',
          confidence: 0,
          measurements: {},
          detectedAt: DateTime.now(),
        );
      }

      final double ratio = rawData['ratio'];
      final double rawConfidence = rawData['rawConfidence'];
      final String bodyType = rawData['bodyType'];
      final double shoulderWidth = rawData['shoulderWidth'];
      final double elbowWidth = rawData['elbowWidth'];
      final double hipWidth = rawData['hipWidth'];
      final double heightRatio = rawData['heightRatio']; 
      final double symmetryScore = rawData['symmetryScore'];
      final int poseQuality = rawData['poseQuality'];
      final trackingBox = rawData['trackingBox'];

      final stabilizedRatio = _calculateStabilizedRatio(ratio);
      final stabilizedConfidence = _calculateStabilizedConfidence(rawConfidence);

      return MorphologyData(
        bodyType: bodyType,
        confidence: stabilizedConfidence,
        measurements: {
          'shoulder_width': shoulderWidth.toStringAsFixed(1),
          'elbow_width': elbowWidth.toStringAsFixed(1),
          'hip_width': hipWidth.toStringAsFixed(1),
          'ratio_shoulder_hip': stabilizedRatio.toStringAsFixed(2),
          'ratio_shoulder_elbow':
              (shoulderWidth / (elbowWidth + 0.001)).toStringAsFixed(2),
          // height_ratio est normalisé [0.0–1.0] par rapport au frame
          'height_ratio': heightRatio.toStringAsFixed(3),
          'symmetry_score': symmetryScore.toStringAsFixed(1),
          'pose_quality': '$poseQuality%',
          'bbox_left_n': trackingBox[0].toStringAsFixed(4),
          'bbox_top_n': trackingBox[1].toStringAsFixed(4),
          'bbox_width_n': trackingBox[2].toStringAsFixed(4),
          'bbox_height_n': trackingBox[3].toStringAsFixed(4),
        },
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Erreur construction morphologie', tag: 'MorphologyService', error: e);
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

// ---------------------------------------------------------------------------
// Fonction top-level pour exécution dans un Isolate (thread secondaire)
// ---------------------------------------------------------------------------

Map<String, dynamic> _computeRawMorphologyData(Map<String, dynamic> params) {
  final Pose pose = params['pose'];
  final int frameWidth = params['frameWidth'];
  final int frameHeight = params['frameHeight'];

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
    return {'error': true};
  }

  final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
  final elbowWidth = (leftElbow.x - rightElbow.x).abs();
  final hipWidth = (leftHip.x - rightHip.x).abs();

  final double ratio = shoulderWidth / (hipWidth + 0.001);
  final double shoulderElbowRatio = shoulderWidth / (elbowWidth + 0.001);

  // Classification exhaustive sans gap.
  // Ancienne version : ratio (1.10, 1.15] tombait implicitement en défaut
  // "Rectangulaire (H)" sans condition explicite → maintenant couvert.
  // Sablier+ étendu à tout [0.90, 1.10] au lieu de [0.95, 1.05] uniquement.
  final String bodyType;
  if (ratio > 1.3 && shoulderElbowRatio > 1.15) {
    bodyType = 'Triangle Inverse+ (V+)';
  } else if (ratio > 1.15) {
    bodyType = 'Triangle Inverse (V)';
  } else if (ratio > 1.10) {
    bodyType = 'Rectangulaire (H)'; // gap [1.10–1.15] maintenant explicite
  } else if (ratio >= 0.90 && shoulderElbowRatio > 1.25) {
    bodyType = 'Sablier+ (X+)';    // [0.90–1.10] taille fortement marquée
  } else if (ratio >= 0.90) {
    bodyType = 'Sablier (X)';      // [0.90–1.10] sans taille marquée
  } else if (ratio > 0.75) {
    bodyType = 'Poire (A)';
  } else {
    bodyType = 'Poire+ (A+)';
  }

  // --- Signal 1 : alignement horizontal des épaules ---
  final yDifference = (leftShoulder.y - rightShoulder.y).abs();
  final double yConfidence = (1.0 - (yDifference / 50).clamp(0, 1)) * 100;

  // --- Signal 2 : plausibilité du ratio ---
  double ratioConfidence = 100;
  if (ratio > 1.5 || ratio < 0.7) {
    ratioConfidence = 50;
  } else if (ratio > 1.3 || ratio < 0.8) {
    ratioConfidence = 75;
  }

  // Hauteur normalisée [0.0–1.0] par rapport au frameHeight.
  // Avant : valeur en pixels bruts, dépendante de la résolution et de la
  // distance caméra → impossible à comparer entre sessions.
  double heightRatio = 0.0;
  final head = pose.landmarks[PoseLandmarkType.nose];
  final feet = pose.landmarks[PoseLandmarkType.leftAnkle];
  if (head != null &&
      feet != null &&
      head.y.isFinite &&
      feet.y.isFinite &&
      frameHeight > 0) {
    final heightPixels = (head.y - feet.y).abs();
    heightRatio =
        heightPixels.isFinite ? (heightPixels / frameHeight).clamp(0.0, 1.0) : 0.0;
  }

  // --- Signal 3 : symétrie bilatérale (score 0–100) ---
  double asymmetries = 0;
  int validPairs = 0;
  final symmetricPairs = [
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee),
  ];
  for (final pair in symmetricPairs) {
    final left = pose.landmarks[pair.$1];
    final right = pose.landmarks[pair.$2];
    if (left != null && right != null && left.y.isFinite && right.y.isFinite) {
      asymmetries += (left.y - right.y).abs();
      validPairs++;
    }
  }
  final double symmetryScore = validPairs > 0
      ? (100 - (asymmetries.clamp(0, 200) / 200) * 100).clamp(0, 100)
      : 0.0;

  // --- Signal 4 : qualité de la pose (% landmarks détectés / 33) ---
  final int poseQuality =
      pose.landmarks.isEmpty ? 0 : ((pose.landmarks.length / 33) * 100).round().clamp(0, 100);

  // Confiance composite pondérée sur 4 signaux indépendants.
  // Ancienne version : seulement yConfidence + ratioConfidence (2 signaux,
  // ignorait la symétrie et la qualité déjà calculées).
  final double rawConfidence = (yConfidence * 0.30 +
          ratioConfidence * 0.20 +
          symmetryScore * 0.30 +
          poseQuality.toDouble() * 0.20)
      .clamp(0.0, 100.0);

  // --- Bounding box normalisée ---
  final points =
      pose.landmarks.values.where((lm) => lm.x.isFinite && lm.y.isFinite).toList();
  List<double> trackingBox = [0.15, 0.10, 0.70, 0.80];
  if (points.isNotEmpty && frameWidth > 0 && frameHeight > 0) {
    var minX = points.first.x;
    var minY = points.first.y;
    var maxX = points.first.x;
    var maxY = points.first.y;
    for (final p in points.skip(1)) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    final padX = (maxX - minX).abs() * 0.18;
    final padY = (maxY - minY).abs() * 0.20;
    minX = (minX - padX).clamp(0, frameWidth.toDouble());
    minY = (minY - padY).clamp(0, frameHeight.toDouble());
    maxX = (maxX + padX).clamp(0, frameWidth.toDouble());
    maxY = (maxY + padY).clamp(0, frameHeight.toDouble());
    trackingBox = [
      (minX / frameWidth).clamp(0.0, 1.0),
      (minY / frameHeight).clamp(0.0, 1.0),
      ((maxX - minX) / frameWidth).clamp(0.05, 1.0),
      ((maxY - minY) / frameHeight).clamp(0.05, 1.0),
    ];
  }

  return {
    'error': false,
    'ratio': ratio,
    'rawConfidence': rawConfidence,
    'bodyType': bodyType,
    'shoulderWidth': shoulderWidth,
    'elbowWidth': elbowWidth,
    'hipWidth': hipWidth,
    'heightRatio': heightRatio, 
    'symmetryScore': symmetryScore,
    'poseQuality': poseQuality,
    'trackingBox': trackingBox,
  };
}
