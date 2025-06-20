import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';

class AuthOverlay extends StatelessWidget {
  final VoidCallback onAuthSuccess;
  final VoidCallback onCancel;

  const AuthOverlay({
    super.key,
    required this.onAuthSuccess,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: AuthOverlayContent(
              onAuthSuccess: onAuthSuccess,
              onCancel: onCancel,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthOverlayContent extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final VoidCallback onCancel;
  
  const AuthOverlayContent({
    super.key,
    required this.onAuthSuccess,
    required this.onCancel,
  });
  
  @override
  State<AuthOverlayContent> createState() => _AuthOverlayContentState();
}

class _AuthOverlayContentState extends State<AuthOverlayContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _loginSuccess = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      final isSuperAdmin = await _authService.isSuperAdmin();
      
      if (!isSuperAdmin) {
        throw Exception('Super admin permissions required');
      }
      
      setState(() {
        _loginSuccess = true;
        _isLoading = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      widget.onAuthSuccess();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loginSuccess) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Login Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Loading settings...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.admin_panel_settings,
          size: 64,
          color: Color(0xFF0F2D52),
        ),
        const SizedBox(height: 24),
        const Text(
          'Admin Login Required',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2D52),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Super admin credentials required to access settings',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading ? null : widget.onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ],
    );
  }
}