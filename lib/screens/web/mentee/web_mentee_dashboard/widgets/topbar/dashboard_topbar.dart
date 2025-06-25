import 'package:flutter/material.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';
import '../../controllers/dashboard_refresh_controller.dart';
import 'topbar_action_button.dart';

class DashboardTopbar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onSearch;
  final VoidCallback? onContactMentor;
  final MenteeDashboardRefreshController? refreshController;

  const DashboardTopbar({
    super.key,
    required this.selectedIndex,
    this.onSearch,
    this.onContactMentor,
    this.refreshController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DashboardSizes.topbarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardSizes.spacingLarge,
        vertical: DashboardSizes.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: DashboardColors.backgroundCard,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(DashboardSizes.cardBorderRadius),
          bottomRight: Radius.circular(DashboardSizes.cardBorderRadius),
        ),
        boxShadow: DashboardShadows.topbarShadow,
      ),
      child: Row(
        children: [
          // Page title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  SidebarItems.items[selectedIndex].title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.primaryDark,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                Text(
                  _getPageDescription(selectedIndex),
                  style: const TextStyle(
                    fontSize: 13,
                    color: DashboardColors.textDarkGrey,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              // Refresh indicator (only on dashboard)
              if (refreshController != null && selectedIndex == 0)
                ListenableBuilder(
                  listenable: refreshController!,
                  builder: (context, _) {
                    if (refreshController!.state.isRefreshing) {
                      return Container(
                        margin: const EdgeInsets.only(right: DashboardSizes.spacingMedium),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DashboardColors.accentBlue,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              // Search button
              TopbarActionButton(
                icon: Icons.search,
                tooltip: 'Search',
                onPressed: onSearch ?? () {},
              ),
              const SizedBox(width: DashboardSizes.spacingSmall),
              // Notifications
              Stack(
                children: [
                  TopbarActionButton(
                    icon: Icons.notifications_outlined,
                    tooltip: 'Notifications',
                    onPressed: () {
                      // TODO: Show notifications panel
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DashboardColors.accentRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DashboardColors.backgroundCard,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DashboardSizes.spacingSmall),
              // Contact mentor
              if (onContactMentor != null) ...[
                TopbarActionButton(
                  icon: Icons.message_outlined,
                  tooltip: 'Message Mentor',
                  onPressed: onContactMentor!,
                  isPrimary: true,
                ),
                const SizedBox(width: DashboardSizes.spacingSmall),
              ],
              // Help
              TopbarActionButton(
                icon: Icons.help_outline,
                tooltip: 'Help',
                onPressed: () {
                  // TODO: Show help
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageDescription(int index) {
    switch (index) {
      case 0:
        return 'Welcome back! Here\'s your overview';
      case 1:
        return 'Manage your meetings and availability';
      case 2:
        return 'Access learning materials and documents';
      case 3:
        return 'Track your progress and tasks';
      case 4:
        return 'Review your meeting notes';
      case 5:
        return 'Stay updated with newsletters';
      case 6:
        return 'Important announcements and updates';
      case 7:
        return 'Manage your account and preferences';
      default:
        return '';
    }
  }
}