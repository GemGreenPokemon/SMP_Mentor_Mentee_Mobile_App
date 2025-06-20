import 'package:flutter/material.dart';
import '../../utils/registration_helpers.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: RegistrationHelpers.getBackgroundGradientColors(),
        ),
      ),
      child: child,
    );
  }
}