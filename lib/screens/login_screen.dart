import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../utils/developer_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  
  // Development mode flag - set to true to bypass validation
  final bool _devMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    DeveloperSession.isActive = false;
    // In development mode, only check if a role is selected
    if (_devMode) {
      if (_selectedRole == 'Developer') {
        DeveloperSession.isActive = true;
      }
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
        return;
      }
      
      // Navigate based on selected role
      _navigateToDashboard();
      return;
    }
    
    // Normal validation for production
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    _navigateToDashboard();
  }
  
  void _navigateToDashboard() {
    // Navigate to the appropriate screen based on role
    switch (_selectedRole) {
      case 'Mentee':
        Navigator.pushReplacementNamed(context, '/mentee');
        break;
      case 'Mentor':
        Navigator.pushReplacementNamed(context, '/mentor');
        break;
      case 'Coordinator':
        Navigator.pushReplacementNamed(context, '/coordinator');
        break;
      case 'Developer':
        Navigator.pushReplacementNamed(context, '/dev');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // App Logo
                SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/My_SMP_Logo.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
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
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
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
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password flow
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Role selection text
                        const Center(
                          child: Text(
                            'Login as a...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Role Selection Buttons
                        _buildRoleButton(
                          context,
                          'Mentee',
                          Icons.school,
                          _selectedRole == 'Mentee',
                        ),
                        const SizedBox(height: 12),
                        _buildRoleButton(
                          context,
                          'Mentor',
                          Icons.psychology,
                          _selectedRole == 'Mentor',
                        ),
                        const SizedBox(height: 12),
                        _buildRoleButton(
                          context,
                          'Coordinator',
                          Icons.admin_panel_settings,
                          _selectedRole == 'Coordinator',
                        ),
                        if (_devMode) ...[
                          const SizedBox(height: 12),
                          _buildRoleButton(
                            context,
                            'Developer',
                            Icons.developer_mode,
                            _selectedRole == 'Developer',
                          ),
                        ],
                        
                        const SizedBox(height: 30),
                        
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005487),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Register link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text("Don't have an account? Register"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String text,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = text;
        });
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005487) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF005487),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF005487),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF005487),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 