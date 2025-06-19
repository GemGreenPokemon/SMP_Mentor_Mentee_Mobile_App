import 'package:flutter/material.dart';

class AnnouncementFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AnnouncementFloatingActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2D52),
                  Color(0xFF1A4A7F),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2D52).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton.large(
              onPressed: onPressed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}