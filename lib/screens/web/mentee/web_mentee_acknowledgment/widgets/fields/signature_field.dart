import 'package:flutter/material.dart';
import '../../utils/acknowledgment_constants.dart';

class SignatureField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const SignatureField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: AcknowledgmentStrings.nameFieldHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
          borderSide: BorderSide(
            color: AcknowledgmentColors.primaryDark,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
          borderSide: BorderSide(
            color: AcknowledgmentColors.errorRed,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          Icons.person,
          color: AcknowledgmentColors.primaryDark,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      style: TextStyle(
        fontSize: AcknowledgmentSizes.fontSizeMedium,
        color: AcknowledgmentColors.textDark,
      ),
    );
  }
}