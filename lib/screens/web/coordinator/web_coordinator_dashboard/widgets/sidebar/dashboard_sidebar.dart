import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_settings/web_settings_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_newsletter/web_newsletter_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/shared/announcement_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_resource_hub/web_resource_hub_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/shared/progress_reports_screen.dart';
import '../../utils/dashboard_constants.dart';
import 'sidebar_header.dart';
import 'sidebar_profile.dart';
import 'sidebar_menu_item.dart';

class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  void _handleNavigation(BuildContext context, int index) {
    onItemSelected(index);
    
    // Handle navigation based on selection
    switch (index) {
      case 9: // Settings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebSettingsScreen(isMentor: false),
          ),
        );
        break;
      case 7: // Newsletter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebNewsletterScreen(isMentor: false, isCoordinator: true),
          ),
        );
        break;
      case 6: // Announcements
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnnouncementScreen(isCoordinator: true),
          ),
        );
        break;
      case 5: // Resources
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebResourceHubScreen(isCoordinator: true),
          ),
        );
        break;
      case 4: // Reports
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProgressReportsScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CoordinatorDashboardDimensions.sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CoordinatorDashboardColors.primaryDark,
            CoordinatorDashboardColors.primaryDark.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SidebarHeader(),
          const SidebarProfile(),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 12,
              ),
              itemCount: CoordinatorDashboardStrings.sidebarItems.length,
              itemBuilder: (context, index) {
                // Add separator before certain items
                if (index == 4 || index == 9) {
                  return Column(
                    children: [
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                      SidebarMenuItem(
                        title: CoordinatorDashboardStrings.sidebarItems[index],
                        icon: CoordinatorDashboardIcons.sidebarIcons[index],
                        isSelected: selectedIndex == index,
                        onTap: () => _handleNavigation(context, index),
                      ),
                    ],
                  );
                }
                return SidebarMenuItem(
                  title: CoordinatorDashboardStrings.sidebarItems[index],
                  icon: CoordinatorDashboardIcons.sidebarIcons[index],
                  isSelected: selectedIndex == index,
                  onTap: () => _handleNavigation(context, index),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              '© 2024 SMP',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}