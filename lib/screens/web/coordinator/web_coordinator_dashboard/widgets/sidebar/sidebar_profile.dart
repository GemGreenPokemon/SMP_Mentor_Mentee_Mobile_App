import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import '../../utils/dashboard_constants.dart';

class SidebarProfile extends StatelessWidget {
  final Map<String, dynamic>? coordinatorProfile;
  
  const SidebarProfile({
    super.key,
    this.coordinatorProfile,
  });

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
                Text(
                  coordinatorProfile?['name'] ?? 'Coordinator',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: CoordinatorDashboardDimensions.fontSizeLarge,
                    color: Colors.white,
                  ),
                ),
                Text(
                  CoordinatorDashboardStrings.coordinatorRole,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: CoordinatorDashboardDimensions.fontSizeMedium,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white.withOpacity(0.7),
            ),
            color: CoordinatorDashboardColors.primaryLight,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.white)),
                  ],
                ),
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