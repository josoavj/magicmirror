import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart' as ph;

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
    ph.PermissionStatus status,
    PermissionType type,
  ) {
    return PermissionStatus(
      isGranted: status.isGranted,
      isDenied: status.isDenied,
      isPermanentlyDenied: status.isPermanentlyDenied,
      type: type,
    );
  }

  factory PermissionStatus.granted(PermissionType type) {
    return PermissionStatus(
      isGranted: true,
      isDenied: false,
      isPermanentlyDenied: false,
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
  bool get _isLinux => !kIsWeb && Platform.isLinux;
  bool get _isWindows => !kIsWeb && Platform.isWindows;
  bool get _isDesktopOrWeb => kIsWeb || _isLinux || _isWindows;

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    if (_isDesktopOrWeb) return PermissionStatus.granted(PermissionType.camera);
    final status = await ph.Permission.camera.request();
    return PermissionStatus.fromPermissionStatus(status, PermissionType.camera);
  }

  @override
  Future<PermissionStatus> requestMicrophonePermission() async {
    if (_isDesktopOrWeb) {
      return PermissionStatus.granted(PermissionType.microphone);
    }
    final status = await ph.Permission.microphone.request();
    return PermissionStatus.fromPermissionStatus(
      status,
      PermissionType.microphone,
    );
  }

  @override
  Future<PermissionStatus> requestPhotosPermission() async {
    if (_isDesktopOrWeb) return PermissionStatus.granted(PermissionType.photos);
    final status = await ph.Permission.photos.request();
    return PermissionStatus.fromPermissionStatus(status, PermissionType.photos);
  }

  @override
  Future<PermissionStatus> requestLocationPermission() async {
    if (_isDesktopOrWeb) {
      return PermissionStatus.granted(PermissionType.location);
    }
    final status = await ph.Permission.location.request();
    return PermissionStatus.fromPermissionStatus(
      status,
      PermissionType.location,
    );
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async {
    if (_isDesktopOrWeb) return PermissionStatus.granted(PermissionType.camera);
    final status = await ph.Permission.camera.status;
    return PermissionStatus.fromPermissionStatus(status, PermissionType.camera);
  }

  @override
  Future<PermissionStatus> checkMicrophonePermission() async {
    if (_isDesktopOrWeb) {
      return PermissionStatus.granted(PermissionType.microphone);
    }
    final status = await ph.Permission.microphone.status;
    return PermissionStatus.fromPermissionStatus(
      status,
      PermissionType.microphone,
    );
  }

  @override
  Future<void> openAppSettings() async {
    if (_isDesktopOrWeb) return;
    await ph.openAppSettings();
  }
}
