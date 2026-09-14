import 'package:camera/camera.dart';
import '../datasources/camera_local_datasource.dart';

abstract class CameraRepository {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> initializeCamera(CameraDescription camera);
  Future<void> disposeCamera(CameraController controller);
  Future<XFile?> takePicture(CameraController controller);
  Future<void> startVideoRecording(CameraController controller);
  Future<XFile?> stopVideoRecording(CameraController controller);
}

class CameraRepositoryImpl implements CameraRepository {
  final CameraLocalDataSource dataSource;

  CameraRepositoryImpl({required this.dataSource});

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return await dataSource.getAvailableCameras();
  }

  @override
  Future<CameraController> initializeCamera(CameraDescription camera) async {
    return await dataSource.initializeCamera(camera);
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    await dataSource.disposeCamera(controller);
  }

  @override
  Future<XFile?> takePicture(CameraController controller) async {
    return await dataSource.takePicture(controller);
  }

  @override
  Future<void> startVideoRecording(CameraController controller) async {
    await dataSource.startVideoRecording(controller);
  }

  @override
  Future<XFile?> stopVideoRecording(CameraController controller) async {
    return await dataSource.stopVideoRecording(controller);
  }
}