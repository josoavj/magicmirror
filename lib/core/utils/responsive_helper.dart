import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop, mirror }

class ResponsiveHelper {
  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    // Détection spécifique pour le Magic Mirror (Ratio vertical ou grand écran fixe)
    if (width >= 1200 && height >= 1800) {
      return DeviceType.mirror;
    }

    if (width >= 1024) {
      return DeviceType.desktop;
    }

    if (width >= 600) {
      return DeviceType.tablet;
    }

    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static bool isMirror(BuildContext context) =>
      getDeviceType(context) == DeviceType.mirror;

  // Calculateur de taille responsive (font-size, padding, etc.)
  static double resp(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? mirror,
  }) {
    DeviceType type = getDeviceType(context);
    switch (type) {
      case DeviceType.mirror:
        return mirror ?? desktop ?? tablet ?? mobile * 2.5;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile * 1.5;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.25;
      case DeviceType.mobile:
      return mobile;
    }
  }
}
