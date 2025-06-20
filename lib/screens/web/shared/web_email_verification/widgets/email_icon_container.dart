import 'package:flutter/material.dart';
import '../utils/verification_constants.dart';

class EmailIconContainer extends StatelessWidget {
  const EmailIconContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VerificationConstants.iconContainerSize,
      height: VerificationConstants.iconContainerSize,
      decoration: BoxDecoration(
        color: VerificationConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(VerificationConstants.iconContainerRadius),
      ),
      child: const Icon(
        Icons.email_outlined,
        size: VerificationConstants.iconSize,
        color: VerificationConstants.primaryColor,
      ),
    );
  }
}