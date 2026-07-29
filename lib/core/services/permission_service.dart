import 'package:magicmirror/core/utils/platform_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Demande les permissions nécessaires en fonction de la plateforme
  static Future<bool> requestCameraPermission() async {
    if (PlatformHelper.isWeb) return true;

    if (PlatformHelper.isLinux || PlatformHelper.isWindows) {
      return true;
    }

    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    return true;
  }

  /// Vérifie si la permission est déjà accordée
  static Future<bool> isCameraPermissionGranted() async {
    if (PlatformHelper.isWeb || PlatformHelper.isLinux || PlatformHelper.isWindows) {
      return true;
    }

    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      return await Permission.camera.isGranted;
    }

    return true;
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    if (PlatformHelper.isWeb || PlatformHelper.isLinux || PlatformHelper.isWindows) {
      return;
    }
    await openAppSettings();
  }
}
