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

/// Morphologie stabilisee pour limiter les rebuilds frequents.
final stableMorphologyProvider =
    StateNotifierProvider<StableMorphologyNotifier, MorphologyData?>((ref) {
      return StableMorphologyNotifier(ref);
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

class StableMorphologyNotifier extends StateNotifier<MorphologyData?> {
  StableMorphologyNotifier(this._ref) : super(null) {
    _subscription = _ref.listen<MorphologyData?>(
      currentMorphologyProvider,
      (previous, next) => _maybeEmit(next),
    );
    _ref.onDispose(() => _subscription?.close());
  }

  final Ref _ref;
  ProviderSubscription<MorphologyData?>? _subscription;
  DateTime? _lastEmittedAt;
  String? _lastBodyType;
  double? _lastConfidence;

  void _maybeEmit(MorphologyData? next) {
    if (next == null) {
      if (state != null) {
        state = null;
      }
      return;
    }

    final now = DateTime.now();
    final poseQuality = _tryParseDouble(next.measurements['pose_quality']);
    final confidence = next.confidence;
    final bodyType = next.bodyType;

    const minIntervalMs = 1200;
    const minConfidence = 50.0;
    const minPoseQuality = 50.0;
    const minConfidenceDelta = 6.0;
    const minChangeConfidence = 45.0;
    const minChangePoseQuality = 45.0;

    final elapsedMs = _lastEmittedAt == null
        ? minIntervalMs
        : now.difference(_lastEmittedAt!).inMilliseconds;
    final enoughTime = elapsedMs >= minIntervalMs;
    final bodyTypeChanged = _lastBodyType == null || _lastBodyType != bodyType;
    final confidenceDelta = _lastConfidence == null
        ? 100.0
        : (confidence - _lastConfidence!).abs();

    final qualityOk =
        confidence >= minConfidence && poseQuality >= minPoseQuality;
    final changeOk =
        confidence >= minChangeConfidence &&
        poseQuality >= minChangePoseQuality &&
        bodyTypeChanged;

    if (!qualityOk && !changeOk) {
      return;
    }

    if (enoughTime ||
        bodyTypeChanged ||
        confidenceDelta >= minConfidenceDelta) {
      state = next;
      _lastEmittedAt = now;
      _lastBodyType = bodyType;
      _lastConfidence = confidence;
    }
  }

  double _tryParseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
