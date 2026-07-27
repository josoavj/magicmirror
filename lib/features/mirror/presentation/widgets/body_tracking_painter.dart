import 'package:flutter/material.dart';

class BodyTrackingPainter extends CustomPainter {
  final Rect normalizedRect;

  const BodyTrackingPainter({required this.normalizedRect});

  @override
  void paint(Canvas canvas, Size size) {
    final safeLeft = normalizedRect.left.clamp(0.0, 1.0);
    final safeTop = normalizedRect.top.clamp(0.0, 1.0);
    final safeWidth = normalizedRect.width.clamp(0.05, 1.0);
    final safeHeight = normalizedRect.height.clamp(0.05, 1.0);

    final drawRect = Rect.fromLTWH(
      safeLeft * size.width,
      safeTop * size.height,
      safeWidth * size.width,
      safeHeight * size.height,
    );

    final border = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final glow = Paint()
      ..color = const Color(0x8022C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final rrect = RRect.fromRectAndRadius(drawRect, const Radius.circular(12));
    canvas.drawRRect(rrect, glow);
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(covariant BodyTrackingPainter oldDelegate) {
    return oldDelegate.normalizedRect != normalizedRect;
  }
}
