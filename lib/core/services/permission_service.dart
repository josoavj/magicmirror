import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Demande les permissions nécessaires en fonction de la plateforme
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;

    if (Platform.isLinux || Platform.isWindows) {
      return true;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    return true;
  }

  /// Vérifie si la permission est déjà accordée
  static Future<bool> isCameraPermissionGranted() async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows) {
      return true;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return await Permission.camera.isGranted;
    }

    return true;
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows) {
      return;
    }
    await openAppSettings();
  }
}
