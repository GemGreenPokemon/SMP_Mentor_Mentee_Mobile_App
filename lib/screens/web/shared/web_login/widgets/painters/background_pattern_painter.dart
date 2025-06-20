import 'package:flutter/material.dart';

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    // Create floating circles
    for (int i = 0; i < 20; i++) {
      final x = (i * 137.5) % size.width;
      final y = (i * 89.3) % size.height;
      final radius = 20.0 + (i % 5) * 15.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Add some geometric shapes
    paint.color = Colors.white.withOpacity(0.03);
    for (int i = 0; i < 10; i++) {
      final x = (i * 234.7) % size.width;
      final y = (i * 156.8) % size.height;
      
      canvas.save();
      canvas.translate(x + 30, y + 30);
      canvas.rotate(i * 0.5);
      canvas.drawRect(const Rect.fromLTWH(-30, -30, 60, 60), paint);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}