import 'package:flutter/material.dart';
import '../../../../../../services/auth_service.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';

class SidebarProfile extends StatelessWidget {
  final MenteeProfile? profile;

  const SidebarProfile({
    super.key,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DashboardColors.accentBlue.withOpacity(0.8),
                  DashboardColors.accentPurple.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: DashboardColors.accentBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile?.name.isNotEmpty == true 
                    ? profile!.name[0].toUpperCase() 
                    : 'M',
                style: DashboardTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: DashboardSizes.spacingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? 'Mentee',
                  style: DashboardTextStyles.body.copyWith(
                    color: DashboardColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Mentee',
                  style: DashboardTextStyles.bodySmall.copyWith(
                    color: DashboardColors.textLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: DashboardColors.textLight.withOpacity(0.7),
              size: 20,
            ),
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
            ),
            color: DashboardColors.backgroundCard,
            elevation: 8,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: DashboardSizes.iconSizeSmall,
                      color: DashboardColors.textSecondary,
                    ),
                    const SizedBox(width: DashboardSizes.spacingSmall),
                    Text(
                      'Edit Profile',
                      style: DashboardTextStyles.body,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      size: DashboardSizes.iconSizeSmall,
                      color: DashboardColors.errorRed,
                    ),
                    const SizedBox(width: DashboardSizes.spacingSmall),
                    Text(
                      'Logout',
                      style: DashboardTextStyles.body.copyWith(
                        color: DashboardColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().signOut();
                // Navigation will be handled automatically by AuthWrapper
              } else if (value == 'profile') {
                // TODO: Navigate to profile editing
              }
            },
          ),
        ],
      ),
    );
  }
}