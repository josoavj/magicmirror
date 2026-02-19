import 'package:camera/camera.dart';

abstract class CameraLocalDataSource {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> initializeCamera(CameraDescription camera);
  Future<void> disposeCamera(CameraController controller);
  Future<XFile?> takePicture(CameraController controller);
  Future<void> startVideoRecording(CameraController controller);
  Future<XFile?> stopVideoRecording(CameraController controller);
}

class CameraLocalDataSourceImpl implements CameraLocalDataSource {
  late CameraController? _currentController;

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      return cameras;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des caméras: $e');
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
      _currentController = controller;

      return controller;
    } catch (e) {
      throw Exception('Erreur initialisation caméra: $e');
    }
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    try {
      await controller.dispose();
      _currentController = null;
    } catch (e) {
      throw Exception('Erreur lors de la libération de la caméra: $e');
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
      throw Exception('Erreur lors de la capture: $e');
    }
  }

  @override
  Future<void> startVideoRecording(CameraController controller) async {
    try {
      if (!controller.value.isInitialized || controller.value.isRecordingVideo) {
        return;
      }
      await controller.startVideoRecording();
    } catch (e) {
      throw Exception('Erreur démarrage enregistrement: $e');
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
      throw Exception('Erreur arrêt enregistrement: $e');
    }
  }
}
