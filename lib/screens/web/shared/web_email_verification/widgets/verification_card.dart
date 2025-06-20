import 'package:flutter/material.dart';
import '../utils/verification_constants.dart';

class VerificationCard extends StatelessWidget {
  final List<Widget> children;
  
  const VerificationCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerificationConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VerificationConstants.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}