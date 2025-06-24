import 'package:flutter/material.dart';
import '../../utils/registration_constants.dart';

class RegistrationFormPanel extends StatelessWidget {
  final Widget child;

  const RegistrationFormPanel({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(RegistrationConstants.extraLargePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}