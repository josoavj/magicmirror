import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 30.0,
    this.opacity = 0.08,
    this.padding,
    Object? width,
  });

  @override
  Widget build(BuildContext context) {
    // Reduce blur on Android for better performance on Impeller renderer
    final effectiveBlur = Platform.isAndroid ? blur * 0.6 : blur;
    final effectiveOpacity = Platform.isAndroid
        ? opacity + 0.02
        : opacity; // Slightly more opaque on Android for better visibility

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: effectiveOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: effectiveOpacity + 0.02),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
