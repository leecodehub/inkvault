import 'dart:math' as math;
import 'package:flutter/material.dart';

class YinYangPainter extends CustomPainter {
  final Color darkColor;
  final Color lightColor;

  YinYangPainter({
    required this.darkColor,
    required this.lightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint darkPaint = Paint()..color = darkColor;
    final Paint lightPaint = Paint()..color = lightColor;

    // 1. Outer circle base (Dark section)
    canvas.drawCircle(center, radius, darkPaint);

    // 2. Light section (S-curve path)
    final Path lightPath = Path();
    lightPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi,
    );

    lightPath.arcTo(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius / 2),
        radius: radius / 2,
      ),
      math.pi / 2,
      -math.pi,
      false,
    );

    lightPath.arcTo(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy + radius / 2),
        radius: radius / 2,
      ),
      math.pi / 2,
      math.pi,
      false,
    );

    // Draw the S-curve light section (No dots drawn afterwards)
    canvas.drawPath(lightPath, lightPaint);
  }

  @override
  bool shouldRepaint(covariant YinYangPainter oldDelegate) {
    return oldDelegate.darkColor != darkColor ||
        oldDelegate.lightColor != lightColor;
  }
}
