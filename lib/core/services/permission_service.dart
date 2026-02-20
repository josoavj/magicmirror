import 'package:magicmirror/core/services/permission_service.dart' as permission;
import 'package:permission_handler/permission_handler.dart';

class PermissionStatus {
  final bool isGranted;
  final bool isDenied;
  final bool isPermanentlyDenied;
  final PermissionType type;

  PermissionStatus({
    required this.isGranted,
    required this.isDenied,
    required this.isPermanentlyDenied,
    required this.type,
  });

  factory PermissionStatus.fromPermissionStatus(
    permission.PermissionStatus status,
    PermissionType type,
  ) {
    return PermissionStatus(
      isGranted: status.isGranted,
      isDenied: status.isDenied,
      isPermanentlyDenied: status.isPermanentlyDenied,
      type: type,
    );
  }
}

enum PermissionType { camera, microphone, photos, location, contacts, calendar }

abstract class PermissionService {
  Future<PermissionStatus> requestCameraPermission();
  Future<PermissionStatus> requestMicrophonePermission();
  Future<PermissionStatus> requestPhotosPermission();
  Future<PermissionStatus> requestLocationPermission();
  Future<PermissionStatus> checkCameraPermission();
  Future<PermissionStatus> checkMicrophonePermission();
  Future<void> openAppSettings();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return PermissionStatus.fromPermissionStatus(status as PermissionStatus, PermissionType.camera);
  }

  @override
  Future<PermissionStatus> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return PermissionStatus.fromPermissionStatus(
      status as PermissionStatus,
      PermissionType.microphone,
    );
  }

  @override
  Future<PermissionStatus> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return PermissionStatus.fromPermissionStatus(status as PermissionStatus, PermissionType.photos);
  }

  @override
  Future<PermissionStatus> requestLocationPermission() async {
    final status = await Permission.location.request();
    return PermissionStatus.fromPermissionStatus(
      status as PermissionStatus,
      PermissionType.location,
    );
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return PermissionStatus.fromPermissionStatus(status as PermissionStatus, PermissionType.camera);
  }

  @override
  Future<PermissionStatus> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return PermissionStatus.fromPermissionStatus(
      status as PermissionStatus,
      PermissionType.microphone,
    );
  }

  @override
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
