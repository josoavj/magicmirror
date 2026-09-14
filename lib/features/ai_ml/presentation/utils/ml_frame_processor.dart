import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import '../providers/ml_provider.dart';

class MlFrameProcessor {
  final Ref ref;
  final CameraDescription camera;
  bool _isProcessing = false;

  // Performance tracking
  final List<int> _processingTimesMs = [];
  final int _timingHistorySize = 10;
  int _dynamicDelayMs = 50; // Délai initial

  MlFrameProcessor({required this.ref, required this.camera});

  /// Point d'entrée principal pour le flux caméra
  Future<void> processCameraFrame(CameraImage image) async {
    if (_isProcessing) {
      logger.debug('Frame déjà en traitement, skip', tag: 'MlFrameProcessor');
      return;
    }

    if (!_isValidCameraImage(image)) {
      logger.warning('CameraImage invalide, skip', tag: 'MlFrameProcessor');
      return;
    }

    _isProcessing = true;
    final frameStartTime = DateTime.now();

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        logger.warning(
          'Conversion InputImage échouée',
          tag: 'MlFrameProcessor',
        );
        return;
      }

      // Utilise le MorphologyNotifier pour traiter la frame
      final morphologyNotifier = ref.read(currentMorphologyProvider.notifier);
      await morphologyNotifier.processFrame(inputImage);
    } catch (e) {
      logger.error('Erreur ML Frame', tag: 'MlFrameProcessor', error: e);
    } finally {
      // Calcule le temps écoulé
      final processingTimeMs = DateTime.now()
          .difference(frameStartTime)
          .inMilliseconds;
      _updateDynamicDelay(processingTimeMs);

      // Applique le délai dynamique pour éviter saturer le CPU
      await Future.delayed(Duration(milliseconds: _dynamicDelayMs));
      _isProcessing = false;
    }
  }

  bool _isValidCameraImage(CameraImage image) {
    try {
      // Vérifier que l'image a au moins un plan
      if (image.planes.isEmpty) {
        return false;
      }

      // Vérifier que chaque plan a des données
      for (final plane in image.planes) {
        if (plane.bytes.isEmpty) {
          return false;
        }
      }

      // Vérifier les dimensions
      if (image.width <= 0 || image.height <= 0) {
        return false;
      }

      return true;
    } catch (e) {
      logger.debug(
        'Erreur validation CameraImage: $e',
        tag: 'MlFrameProcessor',
      );
      return false;
    }
  }

  /// Met à jour le délai en fonction des performances mesurées
  void _updateDynamicDelay(int processingTimeMs) {
    _processingTimesMs.add(processingTimeMs);
    if (_processingTimesMs.length > _timingHistorySize) {
      _processingTimesMs.removeAt(0);
    }

    // Ne pas calculer la moyenne si la liste est vide (sécurité)
    if (_processingTimesMs.isEmpty) {
      _dynamicDelayMs = 50;
      return;
    }

    // Calcule le temps moyen
    final avgProcessingTime =
        _processingTimesMs.reduce((a, b) => a + b) ~/ _processingTimesMs.length;

    // Ajuste le délai basé sur le temps moyen de traitement
    if (avgProcessingTime < 20) {
      // Très rapide → délai court
      _dynamicDelayMs = 20;
    } else if (avgProcessingTime < 35) {
      // Rapide → délai normal
      _dynamicDelayMs = 35;
    } else if (avgProcessingTime < 50) {
      // Moyen → délai repos
      _dynamicDelayMs = 50;
    } else if (avgProcessingTime < 100) {
      // Lent → plus de repos
      _dynamicDelayMs = 100;
    } else {
      // Très lent → délai maximum
      _dynamicDelayMs = 150;
    }

    // Log tous les 30 frames
    if (_processingTimesMs.length % 30 == 0) {
      logger.debug(
        'ML Performance: avg=${avgProcessingTime}ms, delay=${_dynamicDelayMs}ms, history=${_processingTimesMs.length}/$_timingHistorySize',
        tag: 'MlFrameProcessor',
      );
    }
  }

  /// Conversion technique CameraImage -> InputImage
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        if (plane.bytes.isEmpty) {
          logger.warning('Plane bytes vide détecté', tag: 'MlFrameProcessor');
          return null;
        }
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = _getInputImageRotation();
      final format = _getInputImageFormat(image);

      if (format == null) return null;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      logger.error(
        'Erreur conversion CameraImage',
        tag: 'MlFrameProcessor',
        error: e,
      );
      return null;
    }
  }

  /// Calcule la rotation nécessaire pour que l'IA "voit" l'image à l'endroit
  InputImageRotation _getInputImageRotation() {
    // Sur mobile, le capteur est souvent physiquement pivoté de 90° ou 270°
    final rotation = camera.sensorOrientation;
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Identifie le format de pixel selon l'OS
  InputImageFormat? _getInputImageFormat(CameraImage image) {
    if (Platform.isAndroid) {
      return InputImageFormatValue.fromRawValue(image.format.raw);
    } else if (Platform.isIOS) {
      // Sur iOS, le format est souvent BGRA8888
      return InputImageFormat.bgra8888;
    }
    return null;
  }
}
