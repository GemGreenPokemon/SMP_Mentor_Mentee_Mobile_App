import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../services/auth_service.dart';
import '../../../../../../utils/responsive.dart';
import '../../../web_email_verification/web_email_verification_screen.dart';
import '../../models/registration_data.dart';
import '../../utils/registration_constants.dart';
import '../../utils/registration_validators.dart';
import '../../utils/registration_helpers.dart';
import '../fields/registration_text_field.dart';
import '../fields/registration_password_field.dart';

class UnifiedRegistrationForm extends StatefulWidget {
  const UnifiedRegistrationForm({super.key});

  @override
  State<UnifiedRegistrationForm> createState() => _UnifiedRegistrationFormState();
}

class _UnifiedRegistrationFormState extends State<UnifiedRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _studentIdController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isRegistering = false;
  
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _autofillMenteeData() {
    setState(() {
      _nameController.text = 'Dasarathi Narayanan';
      _emailController.text = 'dnarayanan@ucmerced.edu';
      _passwordController.text = '123456';
      _confirmPasswordController.text = '123456';
      _studentIdController.text = '12345678';
    });
    
    if (mounted) {
      RegistrationHelpers.showSnackBar(
        context,
        'Form autofilled with Dasarathi Narayanan\'s data',
        backgroundColor: Colors.orange,
      );
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      // Register with whitelist validation
      // The backend will determine the user's role from the database
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
        
        Navigator.pushReplacement(
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
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Create Account',
            style: RegistrationConstants.titleStyle,
          ),
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Fill in your details to join the mentorship program',
            style: RegistrationConstants.subtitleStyle.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Autofill button (only in debug mode)
          if (kDebugMode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Developer Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _autofillMenteeData,
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text('Autofill Mentee: Dasarathi Narayanan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[700]!),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          
          // Full Name
          RegistrationTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: RegistrationConstants.nameIcon,
            validator: RegistrationValidators.validateName,
          ),
          const SizedBox(height: RegistrationConstants.fieldSpacing),
          
          // Email
          RegistrationTextField(
            controller: _emailController,
            label: 'Email',
            icon: RegistrationConstants.emailIcon,
            keyboardType: TextInputType.emailAddress,
            hintText: 'ucmerced.edu email preferred',
            validator: RegistrationValidators.validateEmail,
          ),
          const SizedBox(height: RegistrationConstants.fieldSpacing),
          
          // Student ID (optional)
          RegistrationTextField(
            controller: _studentIdController,
            label: 'Student ID (optional)',
            icon: RegistrationConstants.studentIdIcon,
            keyboardType: TextInputType.number,
            validator: null, // Optional field
            hintText: '8-digit student ID',
          ),
          const SizedBox(height: RegistrationConstants.fieldSpacing),
          
          // Password
          RegistrationPasswordField(
            controller: _passwordController,
            label: 'Password',
            isPasswordVisible: _isPasswordVisible,
            onToggleVisibility: _togglePasswordVisibility,
            validator: RegistrationValidators.validatePassword,
          ),
          const SizedBox(height: RegistrationConstants.fieldSpacing),
          
          // Confirm Password
          RegistrationPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            isPasswordVisible: _isConfirmPasswordVisible,
            onToggleVisibility: _toggleConfirmPasswordVisibility,
            validator: (value) => RegistrationValidators.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
          ),
          const SizedBox(height: 40),
          
          // Register button
          SizedBox(
            width: double.infinity,
            height: RegistrationConstants.buttonHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: RegistrationConstants.buttonGradientColors,
                ),
                borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: RegistrationConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RegistrationConstants.borderRadius),
                  ),
                ),
                child: _isRegistering
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Login link
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: RegistrationConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}