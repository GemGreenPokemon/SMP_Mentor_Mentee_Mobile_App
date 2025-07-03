import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/coordinator/web_user_management/web_user_management_screen.dart';

class UserManagementContent extends StatelessWidget {
  const UserManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate directly to the new unified user management screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WebUserManagementScreen(),
        ),
      );
    });

    // Show a loading indicator while navigating
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}