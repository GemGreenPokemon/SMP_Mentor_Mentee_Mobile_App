import 'package:flutter/material.dart';
import '../../models/role_selection.dart';
import '../../utils/registration_constants.dart';
import '../../utils/registration_helpers.dart';
import '../../../../../../utils/responsive.dart';
import '../shared/registration_button.dart';
import 'role_card.dart';
import 'role_benefits_panel.dart';

class RoleSelectionPage extends StatefulWidget {
  final Function(UserRole) onRoleSelected;
  
  const RoleSelectionPage({
    super.key,
    required this.onRoleSelected,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole? _selectedRole;

  void _continueToForm() {
    if (_selectedRole == null) {
      RegistrationHelpers.showSnackBar(
        context,
        RegistrationConstants.roleSelectionError,
      );
      return;
    }
    
    widget.onRoleSelected(_selectedRole!);
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Row(
      children: [
        // Left side decorative panel - only visible on desktop/tablet
        if (isDesktop || isTablet) RoleBenefitsPanel(isDesktop: isDesktop),
        
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
                if (!(isDesktop || isTablet)) ...[
                  Center(
                    child: Image.asset(
                      'assets/images/My_SMP_Logo.png',
                      height: RegistrationConstants.logoHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
                
                // Back to login button
                TextButton.icon(
                  onPressed: () => RegistrationHelpers.navigateToLogin(context),
                  icon: const Icon(
                    Icons.arrow_back, 
                    color: RegistrationConstants.primaryColor
                  ),
                  label: const Text(
                    'Back to Login',
                    style: TextStyle(color: RegistrationConstants.primaryColor),
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: RegistrationConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: RegistrationConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your role to get started',
                  style: TextStyle(
                    fontSize: RegistrationConstants.subtitleFontSize,
                    color: RegistrationConstants.greyColor,
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
                
                // Role selection cards
                ...UserRole.values.map((role) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RoleCard(
                    role: role,
                    isSelected: _selectedRole == role,
                    onTap: () {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                  ),
                )).toList(),
                
                const SizedBox(height: 24),
                
                // Continue button
                RegistrationButton(
                  text: 'CONTINUE',
                  onPressed: _continueToForm,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}