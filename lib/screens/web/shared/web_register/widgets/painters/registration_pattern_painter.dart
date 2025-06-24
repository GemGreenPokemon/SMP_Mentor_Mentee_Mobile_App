import 'package:flutter/material.dart';
import 'dart:math' as math;

class RegistrationPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    final patternPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw hexagonal pattern
    for (double x = 0; x < size.width; x += spacing * 1.5) {
      for (double y = 0; y < size.height; y += spacing * 1.732) {
        final offset = (y / (spacing * 1.732)).floor() % 2 == 0 ? 0.0 : spacing * 0.75;
        _drawHexagon(canvas, Offset(x + offset, y), spacing / 2, paint);
        
        // Add subtle fill to some hexagons
        if ((x / spacing).floor() % 3 == 0 && (y / spacing).floor() % 3 == 0) {
          _drawHexagon(canvas, Offset(x + offset, y), spacing / 2, patternPaint);
        }
      }
    }

    // Add diagonal lines for depth
    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width; i += spacing * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        diagonalPaint,
      );
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * 3.14159 / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}