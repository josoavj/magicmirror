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

  MlFrameProcessor({required this.ref, required this.camera});

  /// Point d'entrée principal pour le flux caméra
  Future<void> processCameraFrame(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return;

      // Utilise le MorphologyNotifier pour traiter la frame
      final morphologyNotifier = ref.read(currentMorphologyProvider.notifier);
      await morphologyNotifier.processFrame(inputImage);
    } catch (e) {
      logger.error('Erreur ML Frame', tag: 'MlFrameProcessor', error: e);
    } finally {
      // Un léger délai peut aider à ne pas saturer le CPU sur les vieux devices
      await Future.delayed(const Duration(milliseconds: 50));
      _isProcessing = false;
    }
  }

  /// Conversion technique CameraImage -> InputImage
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
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
