import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
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
  int _skippedFrames = 0;

  // Performance tracking
  final List<int> _processingTimesMs = [];
  final int _timingHistorySize = 10;
  int _dynamicDelayMs = 50; // Délai initial

  MlFrameProcessor({required this.ref, required this.camera});

  /// Point d'entrée principal pour le flux caméra
  Future<void> processCameraFrame(CameraImage image) async {
    if (_isProcessing) {
      _skippedFrames++;
      if (_skippedFrames % 30 == 0) {
        logger.debug(
          'Frames ignorées (traitement en cours): $_skippedFrames',
          tag: 'MlFrameProcessor',
        );
      }
      return;
    }

    _skippedFrames = 0;

    if (!_isValidCameraImage(image)) {
      logger.warning('CameraImage invalide, skip', tag: 'MlFrameProcessor');
      return;
    }

    _isProcessing = true;
    ref.read(isMlProcessingProvider.notifier).state = true;
    final frameStartTime = DateTime.now();

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        ref.read(mlRuntimeErrorProvider.notifier).state =
            'Format caméra incompatible avec ML Kit';
        logger.warning(
          'Conversion InputImage échouée',
          tag: 'MlFrameProcessor',
        );
        return;
      }

      // Utilise le MorphologyNotifier pour traiter la frame
      final morphologyNotifier = ref.read(currentMorphologyProvider.notifier);
      await morphologyNotifier.processFrame(
        inputImage,
        frameWidth: image.width,
        frameHeight: image.height,
      );
      ref.read(mlRuntimeErrorProvider.notifier).state = null;
    } catch (e) {
      if (e.toString().contains('InputImageConverterError')) {
        ref.read(mlRuntimeErrorProvider.notifier).state =
            'Format caméra non supporté par ML Kit';
      } else {
        ref.read(mlRuntimeErrorProvider.notifier).state =
            'Erreur analyse ML: ${e.runtimeType}';
      }
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
      ref.read(isMlProcessingProvider.notifier).state = false;
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
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = _getInputImageRotation();

      late final Uint8List bytes;
      late final InputImageFormat format;
      late final int bytesPerRow;

      if (Platform.isAndroid) {
        final nv21 = _toNv21Bytes(image);
        if (nv21 == null) {
          return null;
        }
        bytes = nv21;
        format = InputImageFormat.nv21;
        bytesPerRow = image.width;
      } else {
        final pixelFormat = _getInputImageFormat(image);
        if (pixelFormat == null) {
          return null;
        }
        final firstPlane = image.planes.first;
        bytes = firstPlane.bytes;
        format = pixelFormat;
        bytesPerRow = firstPlane.bytesPerRow;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: format,
          bytesPerRow: bytesPerRow,
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

  Uint8List? _toNv21Bytes(CameraImage image) {
    if (image.planes.isEmpty) {
      return null;
    }

    // Cas deja NV21 (plan unique)
    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    if (image.planes.length < 3) {
      logger.warning(
        'Format Android non supporté: ${image.planes.length} plans',
        tag: 'MlFrameProcessor',
      );
      return null;
    }

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = width * height;
    final uvSize = width * height ~/ 2;
    final nv21 = Uint8List(ySize + uvSize);

    var offset = 0;

    // Copie Y
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < height; row++) {
      final rowOffset = row * yPlane.bytesPerRow;
      for (var col = 0; col < width; col++) {
        nv21[offset++] = yPlane.bytes[rowOffset + col * yPixelStride];
      }
    }

    // Interleave VU
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < uvHeight; row++) {
      final uRowOffset = row * uPlane.bytesPerRow;
      final vRowOffset = row * vPlane.bytesPerRow;
      for (var col = 0; col < uvWidth; col++) {
        nv21[offset++] = vPlane.bytes[vRowOffset + col * vPixelStride];
        nv21[offset++] = uPlane.bytes[uRowOffset + col * uPixelStride];
      }
    }

    return nv21;
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
