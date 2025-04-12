import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../utils/responsive.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
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
    // In development mode, only check if a role is selected
    if (_devMode) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to implement responsive design
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
          child: Center(
            child: SingleChildScrollView(
              child: Row(
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
                              'Student Mentorship Program',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Access your SMP dashboard to manage mentorship activities, track progress, and stay connected with your mentors and mentees.',
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
                                    '✓ Access resources and materials',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '✓ Schedule and manage meetings',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '✓ Track mentorship progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '✓ Complete tasks and assignments',
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
                  
                  // Right side login form
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
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2D52),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to continue to your dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.email),
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
                                
                                // Password field
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
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF0F2D52),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Role selection label
                                const Text(
                                  'Login as a...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Role selection container - horizontal on desktop, vertical on mobile
                                Container(
                                  width: double.infinity,
                                  child: isDesktop || isTablet
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: _buildRoleButton(
                                                context,
                                                'Mentee',
                                                Icons.school,
                                                _selectedRole == 'Mentee',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildRoleButton(
                                                context,
                                                'Mentor',
                                                Icons.psychology,
                                                _selectedRole == 'Mentor',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildRoleButton(
                                                context,
                                                'Coordinator',
                                                Icons.admin_panel_settings,
                                                _selectedRole == 'Coordinator',
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
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
                                          ],
                                        ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F2D52),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
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
                                    child: const Text(
                                      "Don't have an account? Register",
                                      style: TextStyle(
                                        color: Color(0xFF0F2D52),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String text,
    IconData icon,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = text;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2D52) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF0F2D52),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F2D52).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF0F2D52),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F2D52),
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