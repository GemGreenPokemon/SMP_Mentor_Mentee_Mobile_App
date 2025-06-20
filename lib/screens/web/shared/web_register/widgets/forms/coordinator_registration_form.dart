import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../services/auth_service.dart';
import '../../../../../../utils/responsive.dart';
import '../../../web_email_verification/web_email_verification_screen.dart';
import '../../models/registration_data.dart';
import '../../utils/registration_constants.dart';
import '../../utils/registration_validators.dart';
import '../../utils/registration_helpers.dart';
import '../shared/registration_header.dart';
import '../shared/registration_button.dart';
import '../shared/password_field.dart';
import '../shared/form_field_wrapper.dart';
import '../decorative/gradient_background.dart';

class CoordinatorRegistrationForm extends StatefulWidget {
  final VoidCallback onBack;
  
  const CoordinatorRegistrationForm({
    super.key,
    required this.onBack,
  });

  @override
  State<CoordinatorRegistrationForm> createState() => _CoordinatorRegistrationFormState();
}

class _CoordinatorRegistrationFormState extends State<CoordinatorRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isRegistering = false;
  
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      await _authService.registerWithNameValidation(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        RegistrationHelpers.showSnackBar(
          context,
          RegistrationConstants.registrationSuccessMessage,
          backgroundColor: RegistrationConstants.greenColor,
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorMessage = RegistrationValidators.getFirebaseErrorMessage(e.code);
        RegistrationHelpers.showSnackBar(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        RegistrationHelpers.showSnackBar(
          context,
          'An unexpected error occurred: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    
    return GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: RegistrationHelpers.getMaxFormWidth(isDesktop, isTablet),
            ),
            padding: RegistrationHelpers.getFormPadding(isDesktop, isTablet),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistrationHeader(
                    title: 'Create Coordinator Account',
                    subtitle: 'Fill in your details to join as a coordinator',
                    onBack: widget.onBack,
                    backButtonText: 'Back to Role Selection',
                  ),
                  const SizedBox(height: 8),
                  
                  // Approval notice
                  const Text(
                    RegistrationConstants.coordinatorApprovalNote,
                    style: TextStyle(
                      fontSize: 14,
                      color: RegistrationConstants.redColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Full Name
                  FormFieldWrapper(
                    controller: _nameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person,
                    validator: RegistrationValidators.validateName,
                  ),
                  const SizedBox(height: RegistrationConstants.fieldSpacing),
                  
                  // Email
                  FormFieldWrapper(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'ucmerced.edu email required',
                    validator: RegistrationValidators.validateCoordinatorEmail,
                  ),
                  const SizedBox(height: RegistrationConstants.fieldSpacing),
                  
                  // Position/Role
                  FormFieldWrapper(
                    controller: _roleController,
                    labelText: 'Position/Role at UC Merced',
                    prefixIcon: Icons.work,
                    validator: RegistrationValidators.validateRole,
                  ),
                  const SizedBox(height: RegistrationConstants.fieldSpacing),
                  
                  // Password
                  PasswordField(
                    controller: _passwordController,
                    labelText: 'Password',
                    validator: RegistrationValidators.validatePassword,
                  ),
                  const SizedBox(height: RegistrationConstants.fieldSpacing),
                  
                  // Confirm Password
                  PasswordField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_outline,
                    validator: (value) => RegistrationValidators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Registration button
                  RegistrationButton(
                    text: 'CREATE ACCOUNT',
                    onPressed: _register,
                    isLoading: _isRegistering,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}