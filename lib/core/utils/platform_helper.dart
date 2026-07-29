import 'package:flutter/foundation.dart';

/// Helper utility to check the platform in a web-safe way.
class PlatformHelper {
  /// Returns true if the application is running on the web.
  static bool get isWeb => kIsWeb;

  /// Returns true if the application is running on Android.
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns true if the application is running on iOS.
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns true if the application is running on macOS.
  static bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Returns true if the application is running on Linux.
  static bool get isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Returns true if the application is running on Windows.
  static bool get isWindows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Returns true if the application is running on a desktop platform.
  static bool get isDesktop => isMacOS || isLinux || isWindows;

  /// Returns true if the application is running on a mobile platform.
  static bool get isMobile => isAndroid || isIOS;
}
