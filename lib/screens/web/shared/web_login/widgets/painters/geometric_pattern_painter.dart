import 'package:flutter/material.dart';
import 'dart:math' as math;

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw diagonal lines
    for (int i = 0; i < 15; i++) {
      final y = (i * size.height / 15);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * 0.3, y - size.height * 0.2),
        paint,
      );
    }
    
    // Draw hexagonal pattern
    paint.color = Colors.white.withOpacity(0.04);
    paint.style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 5; j++) {
        final centerX = (i * 80.0) - 40;
        final centerY = (j * 100.0) - 50;
        
        if (centerX < size.width && centerY < size.height) {
          _drawHexagon(canvas, Offset(centerX, centerY), 25, paint);
        }
      }
    }
  }
  
  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
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