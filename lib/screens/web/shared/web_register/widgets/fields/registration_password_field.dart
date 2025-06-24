import 'package:flutter/material.dart';
import '../../utils/registration_constants.dart';

class RegistrationPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;

  const RegistrationPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          RegistrationConstants.passwordIcon,
          color: Colors.grey[600],
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible 
                ? RegistrationConstants.visibilityOffIcon 
                : RegistrationConstants.visibilityIcon,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
          borderSide: const BorderSide(color: RegistrationConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}