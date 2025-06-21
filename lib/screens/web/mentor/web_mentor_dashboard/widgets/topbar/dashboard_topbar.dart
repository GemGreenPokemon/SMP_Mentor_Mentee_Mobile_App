import 'package:flutter/material.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';
import '../dialogs/notifications_panel.dart';
import 'topbar_action_button.dart';

class DashboardTopbar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onSearch;
  final VoidCallback onContactCoordinator;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final DateTime? lastRefresh;

  const DashboardTopbar({
    super.key,
    required this.selectedIndex,
    required this.onSearch,
    required this.onContactCoordinator,
    this.onRefresh,
    this.isRefreshing = false,
    this.lastRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DashboardSizes.spacingXLarge,
        20,
        DashboardSizes.spacingXLarge,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: DashboardDurations.fadeAnimation,
                  child: Text(
                    SidebarItems.titles[selectedIndex],
                    key: ValueKey(selectedIndex),
                    style: const TextStyle(
                      fontSize: DashboardSizes.fontTitle,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SidebarItems.getPageDescription(selectedIndex),
                  style: TextStyle(
                    fontSize: DashboardSizes.fontMedium,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
            decoration: BoxDecoration(
              color: DashboardColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                TopbarActionButton(
                  icon: Icons.search,
                  tooltip: DashboardStrings.search,
                  onPressed: onSearch,
                ),
                const SizedBox(width: 4),
                if (onRefresh != null) ...[
                  if (isRefreshing)
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DashboardColors.primaryDark,
                          ),
                        ),
                      ),
                    )
                  else
                    TopbarActionButton(
                      icon: Icons.refresh,
                      tooltip: 'Refresh Dashboard',
                      onPressed: onRefresh!,
                    ),
                  const SizedBox(width: 4),
                ],
                TopbarActionButton(
                  icon: Icons.support_agent,
                  tooltip: DashboardStrings.coordinator,
                  onPressed: onContactCoordinator,
                ),
                const SizedBox(width: 4),
                Stack(
                  children: [
                    TopbarActionButton(
                      icon: Icons.notifications_outlined,
                      tooltip: DashboardStrings.notifications,
                      onPressed: () => NotificationsPanel.show(context),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DashboardColors.statusRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}