import 'package:flutter/material.dart';
import '../utils/registration_constants.dart';

class RegistrationCard extends StatelessWidget {
  final Widget child;

  const RegistrationCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RegistrationConstants.largeBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(RegistrationConstants.largePadding),
        child: child,
      ),
    );
  }
}