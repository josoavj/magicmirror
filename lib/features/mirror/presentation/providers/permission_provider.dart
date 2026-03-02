import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/permission_service.dart';

/// Provider qui vérifie si toutes les permissions nécessaires sont accordées
final allPermissionsGrantedProvider = FutureProvider<bool>((ref) async {
  final cameraGranted = await PermissionService.requestCameraPermission();
  return cameraGranted;
});

/// Provider pour demander manuellement les permissions
final requestCameraPermissionProvider = FutureProvider<bool>((ref) async {
  return await PermissionService.requestCameraPermission();
});

/// Provider pour vérifier l'état actuel de la caméra
final cameraPermissionProvider = FutureProvider<bool>((ref) async {
  return await PermissionService.isCameraPermissionGranted();
});

/// Provider factice pour le micro (non utilisé mais requis par le widget actuel)
final microphonePermissionProvider = Provider<AsyncValue<bool>>((ref) => const AsyncValue.data(true));
final requestMicrophonePermissionProvider = FutureProvider<bool>((ref) async => true);
final requestLocationPermissionProvider = FutureProvider<bool>((ref) async => true);
final requestPhotosPermissionProvider = FutureProvider<bool>((ref) async => true);

/// Provider pour le service
final permissionServiceProvider = Provider((ref) => PermissionService());
