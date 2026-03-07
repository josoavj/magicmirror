import 'package:camera/camera.dart';
import 'package:magicmirror/core/utils/app_logger.dart';

/// Exception custom pour erreurs caméra
class CameraException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  CameraException({required this.message, this.code, this.originalError});

  @override
  String toString() => 'CameraException($code): $message';
}

abstract class CameraLocalDataSource {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> initializeCamera(CameraDescription camera);
  Future<void> disposeCamera(CameraController controller);
  Future<XFile?> takePicture(CameraController controller);
  Future<void> startVideoRecording(CameraController controller);
  Future<XFile?> stopVideoRecording(CameraController controller);
}

class CameraLocalDataSourceImpl implements CameraLocalDataSource {
  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      return cameras;
    } catch (e) {
      logger.error(
        'Erreur caméras disponibles',
        tag: 'CameraDataSource',
        error: e,
      );
      // BUG FIX #4: Exception custom avec contexte au lieu de Exception générique
      throw CameraException(
        message: 'Impossible de récupérer les caméras disponibles',
        code: 'GET_CAMERAS_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<CameraController> initializeCamera(CameraDescription camera) async {
    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      return controller;
    } catch (e) {
      logger.error('Erreur init caméra', tag: 'CameraDataSource', error: e);
      // BUG FIX #4: Exception custom
      throw CameraException(
        message: 'Impossible d\'initialiser la caméra',
        code: 'INIT_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (e) {
      logger.error('Erreur dispose caméra', tag: 'CameraDataSource', error: e);
      // BUG FIX #4: Exception custom
      throw CameraException(
        message: 'Impossible de libérer la caméra',
        code: 'DISPOSE_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<XFile?> takePicture(CameraController controller) async {
    try {
      if (!controller.value.isInitialized) {
        return null;
      }
      return await controller.takePicture();
    } catch (e) {
      logger.error('Erreur capture', tag: 'CameraDataSource', error: e);
      // BUG FIX #4: Exception custom
      throw CameraException(
        message: 'Erreur lors de la capture d\'image',
        code: 'CAPTURE_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<void> startVideoRecording(CameraController controller) async {
    try {
      if (!controller.value.isInitialized ||
          controller.value.isRecordingVideo) {
        return;
      }
      await controller.startVideoRecording();
    } catch (e) {
      logger.error(
        'Erreur début enregistrement',
        tag: 'CameraDataSource',
        error: e,
      );
      // BUG FIX #4: Exception custom
      throw CameraException(
        message: 'Impossible de démarrer l\'enregistrement vidéo',
        code: 'RECORDING_START_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<XFile?> stopVideoRecording(CameraController controller) async {
    try {
      if (!controller.value.isRecordingVideo) {
        return null;
      }
      return await controller.stopVideoRecording();
    } catch (e) {
      logger.error(
        'Erreur fin enregistrement',
        tag: 'CameraDataSource',
        error: e,
      );
      // BUG FIX #4: Exception custom
      throw CameraException(
        message: 'Impossible d\'arrêter l\'enregistrement vidéo',
        code: 'RECORDING_STOP_FAILED',
        originalError: e,
      );
    }
  }
}
