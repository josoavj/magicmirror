import 'dart:math';
import 'package:flutter/foundation.dart';
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
  Future<MorphologyData?> analyzePose(
    InputImage inputImage, {
    required int frameWidth,
    required int frameHeight,
  }) async {
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

      // Déporter les calculs mathématiques lourds sur un Isolate (thread secondaire)
      final rawData = await compute(
        _computeRawMorphologyData,
        {
          'pose': pose,
          'frameWidth': frameWidth,
          'frameHeight': frameHeight,
        },
      );

      final morphology = _buildFinalMorphology(rawData);

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
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,   // Ajout pour forcer le corps complet
      PoseLandmarkType.rightAnkle,  // Ajout pour forcer le corps complet
    ];

    for (final type in requiredLandmarks) {
      final landmark = pose.landmarks[type];
      // On s'assure que le point existe et qu'il est réellement visible (likelihood > 0.6)
      // Le modèle a tendance à extrapoler les jambes hors champ si on ne vérifie pas la probabilité.
      if (landmark == null || landmark.likelihood < 0.6) {
        return false;
      }
    }
    return true;
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
      _outlierLogCounter++;
      if (_outlierLogCounter % 20 == 0) {
        logger.debug(
          'Ratio outlier détecté: $newRatio vs moyenne $mean (écart: ${(newRatio - mean).abs()})',
          tag: 'MorphologyService',
        );
      }
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



  /// Construit l'objet final sur le thread principal pour inclure la stabilisation (qui requiert un état)
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
      final double heightEstimate = rawData['heightEstimate'];
      final double symmetryScore = rawData['symmetryScore'];
      final int poseQuality = rawData['poseQuality'];
      final trackingBox = rawData['trackingBox'];

      // Applique la stabilisation (utilise l'état de l'instance)
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
          'ratio_shoulder_elbow': (shoulderWidth / (elbowWidth + 0.001)).toStringAsFixed(2),
          'height_estimate': heightEstimate.toStringAsFixed(0),
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
      logger.error('Erreur construction finale morphologie', tag: 'MorphologyService', error: e);
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

/// Fonction Top-Level pour exécution dans un Isolate
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

  if (leftShoulder == null || rightShoulder == null || leftElbow == null || rightElbow == null || leftHip == null || rightHip == null) {
    return {'error': true};
  }

  final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
  final elbowWidth = (leftElbow.x - rightElbow.x).abs();
  final hipWidth = (leftHip.x - rightHip.x).abs();

  double shoulderHipRatio = shoulderWidth / (hipWidth + 0.001);
  double shoulderElbowRatio = shoulderWidth / (elbowWidth + 0.001);
  String bodyType = 'Rectangulaire (H)';
  if (shoulderHipRatio > 1.3 && shoulderElbowRatio > 1.15) {
    bodyType = 'Triangle Inverse+ (V+)';
  } else if (shoulderHipRatio > 1.15) {
    bodyType = 'Triangle Inverse (V)';
  } else if (shoulderHipRatio >= 0.95 && shoulderHipRatio <= 1.05 && shoulderElbowRatio > 1.25) {
    bodyType = 'Sablier+ (X+)';
  } else if (shoulderHipRatio >= 0.90 && shoulderHipRatio <= 1.10) {
    bodyType = 'Sablier (X)';
  } else if (shoulderHipRatio < 0.90 && shoulderHipRatio > 0.75) {
    bodyType = 'Poire (A)';
  } else if (shoulderHipRatio <= 0.75) {
    bodyType = 'Poire+ (A+)';
  }

  double ratio = shoulderWidth / (hipWidth + 0.001);
  
  // Calcul confiance raw
  final leftY = leftShoulder.y;
  final rightY = rightShoulder.y;
  final yDifference = (leftY - rightY).abs();
  final yConfidence = (1.0 - (yDifference / 50).clamp(0, 1)) * 100;
  double ratioConfidence = 100;
  if (ratio > 1.5 || ratio < 0.7) {
    ratioConfidence = 50;
  } else if (ratio > 1.3 || ratio < 0.8) {
    ratioConfidence = 75;
  }
  double rawConfidence = ((yConfidence + ratioConfidence) / 2).clamp(0, 100);

  // Calcul Hauteur
  double heightEstimate = 0.0;
  final head = pose.landmarks[PoseLandmarkType.nose];
  final feet = pose.landmarks[PoseLandmarkType.leftAnkle];
  if (head != null && feet != null && head.y.isFinite && feet.y.isFinite) {
    final heightPixels = (head.y - feet.y).abs();
    heightEstimate = heightPixels.isFinite ? heightPixels : 0.0;
  }

  // Calcul Symétrie
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
  double symmetryScore = 0.0;
  if (validPairs > 0) {
    symmetryScore = (100 - (asymmetries.clamp(0, 200) / 200) * 100).clamp(0, 100);
  }

  // Calcul Qualité
  final detectedLandmarks = pose.landmarks.length;
  int poseQuality = detectedLandmarks == 0 ? 0 : ((detectedLandmarks / 33) * 100).round().clamp(0, 100);

  // Bounding Box
  final points = pose.landmarks.values.where((lm) => lm.x.isFinite && lm.y.isFinite).toList();
  List<double> trackingBox = [0.15, 0.10, 0.70, 0.80];
  if (points.isNotEmpty && frameWidth > 0 && frameHeight > 0) {
    var minX = points.first.x;
    var minY = points.first.y;
    var maxX = points.first.x;
    var maxY = points.first.y;
    for (final point in points.skip(1)) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }
    final padX = (maxX - minX).abs() * 0.18;
    final padY = (maxY - minY).abs() * 0.20;
    minX = (minX - padX).clamp(0, frameWidth.toDouble());
    minY = (minY - padY).clamp(0, frameHeight.toDouble());
    maxX = (maxX + padX).clamp(0, frameWidth.toDouble());
    maxY = (maxY + padY).clamp(0, frameHeight.toDouble());
    final left = (minX / frameWidth).clamp(0.0, 1.0);
    final top = (minY / frameHeight).clamp(0.0, 1.0);
    final width = ((maxX - minX) / frameWidth).clamp(0.05, 1.0);
    final height = ((maxY - minY) / frameHeight).clamp(0.05, 1.0);
    trackingBox = [left, top, width, height];
  }

  return {
    'error': false,
    'ratio': ratio,
    'rawConfidence': rawConfidence,
    'bodyType': bodyType,
    'shoulderWidth': shoulderWidth,
    'elbowWidth': elbowWidth,
    'hipWidth': hipWidth,
    'heightEstimate': heightEstimate,
    'symmetryScore': symmetryScore,
    'poseQuality': poseQuality,
    'trackingBox': trackingBox,
  };
}
