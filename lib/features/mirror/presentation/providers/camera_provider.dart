import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/camera_local_datasource.dart';
import '../../data/repositories/camera_repository.dart';

// Datasource Provider
final cameraLocalDataSourceProvider = Provider<CameraLocalDataSource>((ref) {
  return CameraLocalDataSourceImpl();
});

// Repository Provider
final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  final dataSource = ref.watch(cameraLocalDataSourceProvider);
  return CameraRepositoryImpl(dataSource: dataSource);
});

// Available Cameras Provider
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  final repository = ref.watch(cameraRepositoryProvider);
  return await repository.getAvailableCameras();
});

// Camera Controller Provider
final cameraControllerProvider =
    FutureProvider.family<CameraController, CameraDescription>((ref, camera) async {
  final repository = ref.watch(cameraRepositoryProvider);
  return await repository.initializeCamera(camera);
});

// Front Camera Provider (automatically selects front camera)
final frontCameraProvider = FutureProvider<CameraDescription?>((ref) async {
  final cameras = await ref.watch(availableCamerasProvider.future);
  try {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
  } catch (e) {
    return cameras.isNotEmpty ? cameras.first : null;
  }
});

// Recording State Provider
final isRecordingProvider = StateProvider<bool>((ref) => false);
