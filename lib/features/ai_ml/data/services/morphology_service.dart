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
      logger.error('Erreur init PoseDetector', tag: 'MorphologyService', error: e);
      _isInitialized = false;
    }
  }

  Future<void> dispose() async {
    try {
      await _poseDetector.close();
      logger.info('PoseDetector dispose', tag: 'MorphologyService');
    } catch (e) {
      logger.error('Erreur fermeture PoseDetector', tag: 'MorphologyService', error: e);
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

  /// Vérifie que la pose est valide
  bool _isValidPose(Pose pose) {
    final requiredLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];

    for (final landmark in requiredLandmarks) {
      if (pose.landmarks[landmark] == null) {
        return false;
      }
    }
    return true;
  }

  /// Calcule la morphologie
  MorphologyData _calculateMorphology(Pose pose) {
    try {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

      if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
        return MorphologyData(
          bodyType: 'Non detectee',
          confidence: 0,
          measurements: {},
          detectedAt: DateTime.now(),
        );
      }

      // Accès direct aux coordonnées (API google_ml_kit)
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final hipWidth = (leftHip.x - rightHip.x).abs();

      // Classification
      String bodyType = 'Rectangulaire';
      double ratio = shoulderWidth / (hipWidth + 0.001);

      if (ratio > 1.2) {
        bodyType = 'Triangle Inverse (V)';
      } else if (ratio < 0.85) {
        bodyType = 'Poire (A)';
      } else if (ratio >= 0.95 && ratio <= 1.05) {
        bodyType = 'Sablier (X)';
      }

      return MorphologyData(
        bodyType: bodyType,
        confidence: 85.0,
        measurements: {
          'shoulder_width': shoulderWidth.toStringAsFixed(1),
          'hip_width': hipWidth.toStringAsFixed(1),
          'ratio': ratio.toStringAsFixed(2),
        },
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Erreur calcul morphologie', tag: 'MorphologyService', error: e);
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
