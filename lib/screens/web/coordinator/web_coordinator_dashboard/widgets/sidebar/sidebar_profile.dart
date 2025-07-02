import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import '../../utils/dashboard_constants.dart';

class SidebarProfile extends StatelessWidget {
  const SidebarProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CoordinatorDashboardDimensions.paddingMedium),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: CoordinatorDashboardColors.primaryDark,
            child: Icon(
              Icons.admin_panel_settings,
              size: CoordinatorDashboardDimensions.iconSizeLarge,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: CoordinatorDashboardDimensions.paddingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  CoordinatorDashboardStrings.defaultCoordinatorName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: CoordinatorDashboardDimensions.fontSizeLarge,
                  ),
                ),
                Text(
                  CoordinatorDashboardStrings.coordinatorRole,
                  style: TextStyle(
                    color: CoordinatorDashboardColors.textDarkGrey,
                    fontSize: CoordinatorDashboardDimensions.fontSizeMedium,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Edit Profile'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().signOut();
                // Navigation will be handled automatically by AuthWrapper
              }
            },
          ),
        ],
      ),
    );
  }
}