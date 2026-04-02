import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../data/models/morphology_model.dart';
import '../../data/services/morphology_service.dart';
import '../utils/ml_frame_processor.dart';
import 'package:magicmirror/core/utils/app_logger.dart';

final morphologyServiceProvider = Provider<MorphologyService>((ref) {
  final service = MorphologyService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// État pour stocker la morphologie détectée
final currentMorphologyProvider =
    StateNotifierProvider<MorphologyNotifier, MorphologyData?>((ref) {
      final service = ref.watch(morphologyServiceProvider);
      return MorphologyNotifier(service);
    });

/// État pour tracer le traitement ML
final isMlProcessingProvider = StateProvider<bool>((ref) => false);

/// Dernière erreur runtime du pipeline ML (null si aucune)
final mlRuntimeErrorProvider = StateProvider<String?>((ref) => null);

/// Provider pour le processeur ML avec caméra
final mlFrameProcessorProvider =
    Provider.family<MlFrameProcessor, CameraDescription>((ref, camera) {
      return MlFrameProcessor(ref: ref, camera: camera);
    });

/// Notifier pour gérer les mises à jour de morphologie
class MorphologyNotifier extends StateNotifier<MorphologyData?> {
  final MorphologyService _service;
  DateTime? _lastDebugLogAt;
  String? _lastLoggedBodyType;
  double? _lastLoggedConfidence;

  MorphologyNotifier(this._service) : super(null);

  /// Traite une image et met à jour la morphologie
  Future<void> processFrame(
    InputImage inputImage, {
    required int frameWidth,
    required int frameHeight,
  }) async {
    try {
      final morphology = await _service.analyzePose(
        inputImage,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      if (morphology != null) {
        state = morphology;
        final now = DateTime.now();
        final confidenceDelta = _lastLoggedConfidence == null
            ? 100.0
            : (morphology.confidence - _lastLoggedConfidence!).abs();
        final bodyTypeChanged = _lastLoggedBodyType != morphology.bodyType;
        final enoughTimePassed =
            _lastDebugLogAt == null ||
            now.difference(_lastDebugLogAt!).inSeconds >= 3;

        if (bodyTypeChanged || confidenceDelta >= 5 || enoughTimePassed) {
          logger.debug(
            'Morphologie mise à jour: ${morphology.bodyType} (${morphology.confidence.toStringAsFixed(1)}%)',
            tag: 'MorphologyNotifier',
          );
          _lastDebugLogAt = now;
          _lastLoggedBodyType = morphology.bodyType;
          _lastLoggedConfidence = morphology.confidence;
        }
      }
    } catch (e) {
      logger.error(
        'Erreur traitement frame',
        tag: 'MorphologyNotifier',
        error: e,
      );
    }
  }

  /// Réinitialise la morphologie
  void reset() {
    state = null;
  }

  /// Retourne la dernière morphologie détectée (pour la stabilisation)
  MorphologyData? getLatest() => state;
}
