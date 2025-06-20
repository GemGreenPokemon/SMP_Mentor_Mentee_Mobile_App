import 'package:flutter/material.dart';
import 'models/role_selection.dart';
import 'utils/registration_constants.dart';
import 'widgets/decorative/gradient_background.dart';
import 'widgets/role_selection/role_selection_page.dart';
import 'widgets/forms/mentee_registration_form.dart';
import 'widgets/forms/mentor_registration_form.dart';
import 'widgets/forms/coordinator_registration_form.dart';
import 'widgets/forms/developer_registration_form.dart';

class WebRegisterScreen extends StatefulWidget {
  const WebRegisterScreen({super.key});

  @override
  State<WebRegisterScreen> createState() => _WebRegisterScreenState();
}

class _WebRegisterScreenState extends State<WebRegisterScreen> {
  final PageController _pageController = PageController();
  UserRole? _selectedRole;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
    
    // Navigate to the next page
    _pageController.nextPage(
      duration: RegistrationConstants.pageTransitionDuration,
      curve: RegistrationConstants.pageTransitionCurve,
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: RegistrationConstants.pageTransitionDuration,
      curve: RegistrationConstants.pageTransitionCurve,
    );
  }

  Widget _buildRegistrationForm() {
    if (_selectedRole == null) {
      return Container(); // Should never happen
    }
    
    switch (_selectedRole!) {
      case UserRole.mentee:
        return MenteeRegistrationForm(onBack: _goBack);
      case UserRole.mentor:
        return MentorRegistrationForm(onBack: _goBack);
      case UserRole.coordinator:
        return CoordinatorRegistrationForm(onBack: _goBack);
      case UserRole.developer:
        return DeveloperRegistrationForm(onBack: _goBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientBackground(
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // First page - Role selection
              RoleSelectionPage(
                onRoleSelected: _onRoleSelected,
              ),
              
              // Second page - Role-specific registration form
              _buildRegistrationForm(),
            ],
          ),
        ),
      ),
    );
  }
}