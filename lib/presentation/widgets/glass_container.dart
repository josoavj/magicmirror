import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/theme/app_colors.dart';
import 'package:magicmirror/core/utils/platform_helper.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';

class GlassContainer extends ConsumerWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 30.0,
    this.opacity = AppColors.glassOpacity,
    this.tintColor,
    this.borderWidth = 1.1,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isMobile = shortestSide < 600;

    // Performance optimization: disable blur in low performance mode
    final effectiveBlur =
        settings.lowPerformanceMode
            ? 0.0
            : (isMobile
                ? AppColors.getOptimizedBlur(blur) * 0.82
                : AppColors.getOptimizedBlur(blur));

    final effectiveOpacity = isMobile ? opacity + 0.03 : opacity;
    final baseTint = tintColor ?? AppColors.glassBackground;
    final highlightAlpha = isMobile ? 0.22 : 0.18;
    final edgeAlpha = isMobile ? 0.28 : 0.24;
    final shadowAlpha = PlatformHelper.isAndroid ? 0.12 : 0.08;

    Widget current = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: edgeAlpha),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: isMobile ? 24 : 18,
            spreadRadius: isMobile ? 1 : 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseTint.withValues(alpha: effectiveOpacity + 0.08),
            baseTint.withValues(alpha: effectiveOpacity),
            baseTint.withValues(alpha: (effectiveOpacity - 0.02).clamp(0, 1)),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: highlightAlpha),
                      Colors.white.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.22, 0.5],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: RadialGradient(
                    center: const Alignment(-0.75, -0.85),
                    radius: isMobile ? 1.3 : 1.0,
                    colors: [
                      Colors.white.withValues(alpha: isMobile ? 0.18 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );

    if (effectiveBlur > 0) {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: current,
        ),
      );
    } else {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: current,
      );
    }

    return current;
  }
}
