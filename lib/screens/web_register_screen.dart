import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'web_mentee_acknowledgment_screen.dart';
import 'email_verification_screen.dart';
import '../utils/responsive.dart';
import '../services/auth_service.dart';

class WebRegisterScreen extends StatefulWidget {
  const WebRegisterScreen({super.key});

  @override
  State<WebRegisterScreen> createState() => _WebRegisterScreenState();
}

class _WebRegisterScreenState extends State<WebRegisterScreen> {
  String? _selectedRole;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _continueToForm() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    // Navigate to the next page
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2D52).withOpacity(0.1),
              Colors.white,
              Colors.white,
              const Color(0xFF0F2D52).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // First page - Role selection
              _buildRoleSelectionPage(isDesktop, isTablet),
              
              // Second page - Role-specific registration form
              _buildRegistrationForm(isDesktop, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionPage(bool isDesktop, bool isTablet) {
    return Row(
      children: [
        // Left side decorative panel - only visible on desktop/tablet
        if (isDesktop || isTablet)
          Expanded(
            flex: isDesktop ? 4 : 3,
            child: Container(
              height: MediaQuery.of(context).size.height - 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2D52),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/My_SMP_Logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Join the Student Mentorship Program',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create your account to start your mentorship journey. Whether you\'re seeking guidance or providing it, our platform connects you with the UC Merced community.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✓ Connect with mentors and mentees',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '✓ Access exclusive resources',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '✓ Track your progress and growth',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '✓ Join a supportive community',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Right side role selection
        Expanded(
          flex: isDesktop ? 3 : (isTablet ? 4 : 1),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop || isTablet ? double.infinity : 500,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop || isTablet ? 48 : 24,
              vertical: 32
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!(isDesktop || isTablet))
                  Center(
                    child: Image.asset(
                      'assets/images/My_SMP_Logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (!(isDesktop || isTablet))
                  const SizedBox(height: 40),
                
                // Back to login button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2D52)),
                  label: const Text(
                    'Back to Login',
                    style: TextStyle(color: Color(0xFF0F2D52)),
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2D52),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your role to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'I am a...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Role selection buttons
                _buildRoleButton(
                  'Mentee',
                  Icons.school,
                  'Join as a student seeking guidance',
                  _selectedRole == 'Mentee',
                ),
                const SizedBox(height: 16),
                
                _buildRoleButton(
                  'Mentor',
                  Icons.psychology,
                  'Join as someone who provides guidance',
                  _selectedRole == 'Mentor',
                ),
                const SizedBox(height: 16),
                
                _buildRoleButton(
                  'Coordinator',
                  Icons.admin_panel_settings,
                  'Join as a program administrator',
                  _selectedRole == 'Coordinator',
                ),
                
                const SizedBox(height: 40),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _continueToForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2D52),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(bool isDesktop, bool isTablet) {
    // Return different forms based on selected role
    switch (_selectedRole) {
      case 'Mentee':
        return WebMenteeRegistrationForm(onBack: _goBack, isDesktop: isDesktop, isTablet: isTablet);
      case 'Mentor':
        return WebMentorRegistrationForm(onBack: _goBack, isDesktop: isDesktop, isTablet: isTablet);
      case 'Coordinator':
        return WebCoordinatorRegistrationForm(onBack: _goBack, isDesktop: isDesktop, isTablet: isTablet);
      default:
        return Container(); // Should never happen
    }
  }

  Widget _buildRoleButton(
    String text,
    IconData icon,
    String description,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = text;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2D52) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0F2D52),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F2D52).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF0F2D52),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F2D52),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Web Mentee Registration Form
class WebMenteeRegistrationForm extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDesktop;
  final bool isTablet;

  const WebMenteeRegistrationForm({
    super.key, 
    required this.onBack,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  State<WebMenteeRegistrationForm> createState() => _WebMenteeRegistrationFormState();
}

class _WebMenteeRegistrationFormState extends State<WebMenteeRegistrationForm> {
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

  void _register() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      // Register with name-only whitelist validation
      await _authService.registerWithNameValidation(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Show success message and navigate to email verification screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Navigate to email verification screen instead of acknowledgment
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'name-not-approved':
            errorMessage = 'Your name is not on the approved list. Please contact your coordinator.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account with this email already exists.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2D52).withOpacity(0.1),
            Colors.white,
            Colors.white,
            const Color(0xFF0F2D52).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.isDesktop ? 600 : (widget.isTablet ? 500 : double.infinity),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isDesktop || widget.isTablet ? 48 : 24,
              vertical: 32
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2D52)),
                    label: const Text(
                      'Back to Role Selection',
                      style: TextStyle(color: Color(0xFF0F2D52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Create Mentee Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2D52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill in your details to join as a mentee',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                      hintText: 'ucmerced.edu email preferred',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // UC Merced Student ID
                  TextFormField(
                    controller: _studentIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'UC Merced Student ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your student ID';
                      }
                      if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                        return 'Student ID should be 8 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Registration button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2D52),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

// Web Mentor Registration Form
class WebMentorRegistrationForm extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDesktop;
  final bool isTablet;

  const WebMentorRegistrationForm({
    super.key, 
    required this.onBack,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  State<WebMentorRegistrationForm> createState() => _WebMentorRegistrationFormState();
}

class _WebMentorRegistrationFormState extends State<WebMentorRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
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
    _departmentController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      // Register with name-only whitelist validation
      await _authService.registerWithNameValidation(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Show success message and navigate to email verification screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Navigate to email verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'name-not-approved':
            errorMessage = 'Your name is not on the approved list. Please contact your coordinator.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account with this email already exists.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2D52).withOpacity(0.1),
            Colors.white,
            Colors.white,
            const Color(0xFF0F2D52).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.isDesktop ? 600 : (widget.isTablet ? 500 : double.infinity),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isDesktop || widget.isTablet ? 48 : 24,
              vertical: 32
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2D52)),
                    label: const Text(
                      'Back to Role Selection',
                      style: TextStyle(color: Color(0xFF0F2D52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Create Mentor Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2D52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill in your details to join as a mentor',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                      hintText: 'ucmerced.edu email preferred',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Department
                  TextFormField(
                    controller: _departmentController,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your department';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Registration button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2D52),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

// Web Coordinator Registration Form
class WebCoordinatorRegistrationForm extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDesktop;
  final bool isTablet;

  const WebCoordinatorRegistrationForm({
    super.key, 
    required this.onBack,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  State<WebCoordinatorRegistrationForm> createState() => _WebCoordinatorRegistrationFormState();
}

class _WebCoordinatorRegistrationFormState extends State<WebCoordinatorRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _roleController = TextEditingController();
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
    _roleController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      // Register with name-only whitelist validation
      await _authService.registerWithNameValidation(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Show success message and navigate to email verification screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Navigate to email verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'name-not-approved':
            errorMessage = 'Your name is not on the approved list. Please contact your coordinator.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account with this email already exists.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2D52).withOpacity(0.1),
            Colors.white,
            Colors.white,
            const Color(0xFF0F2D52).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.isDesktop ? 600 : (widget.isTablet ? 500 : double.infinity),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isDesktop || widget.isTablet ? 48 : 24,
              vertical: 32
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2D52)),
                    label: const Text(
                      'Back to Role Selection',
                      style: TextStyle(color: Color(0xFF0F2D52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Create Coordinator Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2D52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Note: Coordinator accounts require approval',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill in your details to join as a coordinator',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                      hintText: 'ucmerced.edu email required',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      if (!value.endsWith('ucmerced.edu')) {
                        return 'Must use a UC Merced email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Role
                  TextFormField(
                    controller: _roleController,
                    decoration: InputDecoration(
                      labelText: 'Position/Role at UC Merced',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.work),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your position';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Registration button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2D52),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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