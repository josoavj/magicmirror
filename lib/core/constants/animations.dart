import 'package:flutter/animation.dart';

class AppAnimations {
  // Durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationSlow = Duration(milliseconds: 600);
  static const Duration durationLong = Duration(milliseconds: 1000);

  // Curves
  static const Curve curveFastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveBounceIn = Curves.bounceIn;
  static const Curve curveBounceOut = Curves.bounceOut;
}
