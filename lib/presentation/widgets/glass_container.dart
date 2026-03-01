import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Alignment begin;
  final Alignment end;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blur = 15.0,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16.0),
    this.opacity = 0.1,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [
                Colors.white.withOpacity(opacity * 2),
                Colors.white.withOpacity(opacity / 2),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
