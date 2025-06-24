import 'package:flutter/material.dart';

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw circles at various positions
    final positions = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.5),
    ];

    final radii = [120.0, 80.0, 100.0, 60.0, 150.0];

    for (int i = 0; i < positions.length; i++) {
      canvas.drawCircle(positions[i], radii[i], paint);
    }

    // Add some connecting lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(positions[0], positions[4], linePaint);
    canvas.drawLine(positions[1], positions[3], linePaint);
    canvas.drawLine(positions[2], positions[4], linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}