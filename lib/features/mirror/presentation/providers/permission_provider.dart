import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/services/permission_service.dart';
// Permission Service Provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

// Camera Permission Provider
final cameraPermissionProvider = FutureProvider<PermissionStatus>((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.checkCameraPermission();
});

// Request Camera Permission Provider
final requestCameraPermissionProvider = FutureProvider<PermissionStatus>((
  ref,
) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.requestCameraPermission();
});

// Microphone Permission Provider
final microphonePermissionProvider = FutureProvider<PermissionStatus>((
  ref,
) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.checkMicrophonePermission();
});

// Request Microphone Permission Provider
final requestMicrophonePermissionProvider = FutureProvider<PermissionStatus>((
  ref,
) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.requestMicrophonePermission();
});

// Location Permission Provider
final requestLocationPermissionProvider = FutureProvider<PermissionStatus>((
  ref,
) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.requestLocationPermission();
});

// Photos Permission Provider
final requestPhotosPermissionProvider = FutureProvider<PermissionStatus>((
  ref,
) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.requestPhotosPermission();
});

// All Permissions Granted Provider
final allPermissionsGrantedProvider = FutureProvider<bool>((ref) async {
  final cameraPermission = await ref.watch(cameraPermissionProvider.future);
  final micPermission = await ref.watch(microphonePermissionProvider.future);

  return cameraPermission.isGranted && micPermission.isGranted;
});
