import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';
import 'sidebar_header.dart';
import 'sidebar_profile.dart';
import 'sidebar_menu_item.dart';
import 'sidebar_footer.dart';

class DashboardSidebar extends StatelessWidget {
  final Animation<double> animation;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final MentorProfile? mentorProfile;

  const DashboardSidebar({
    super.key,
    required this.animation,
    required this.selectedIndex,
    required this.onItemSelected,
    this.mentorProfile,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(DashboardSizes.sidebarAnimationOffset * (1 - animation.value), 0),
          child: Container(
            width: DashboardSizes.sidebarWidth,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DashboardColors.primaryDark,
                  DashboardColors.primaryDarkSecondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SidebarHeader(),
                SidebarProfile(profile: mentorProfile),
                const SizedBox(height: DashboardSizes.spacingLarge),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: DashboardSizes.spacingSmall + 4),
                    itemCount: SidebarItems.items.length,
                    itemBuilder: (context, index) {
                      final item = SidebarItems.items[index];
                      return SidebarMenuItem(
                        item: item,
                        isSelected: selectedIndex == index,
                        onTap: () => onItemSelected(index),
                      );
                    },
                  ),
                ),
                const SidebarFooter(),
              ],
            ),
          ),
        );
      },
    );
  }
}