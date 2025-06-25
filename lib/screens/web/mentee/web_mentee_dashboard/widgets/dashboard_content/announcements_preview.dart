import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';
import '../shared/dashboard_card_container.dart';
import '../shared/empty_state.dart';
import '../cards/announcement_item.dart';

class AnnouncementsPreview extends StatelessWidget {
  final List<Announcement> announcements;
  final VoidCallback onViewAll;

  const AnnouncementsPreview({
    super.key,
    required this.announcements,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Announcements',
                style: DashboardTextStyles.h4,
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: DashboardTextStyles.button.copyWith(
                    color: DashboardColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          if (announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DashboardSizes.spacingXLarge),
              child: Center(
                child: Text(
                  'No announcements at this time',
                  style: TextStyle(
                    color: DashboardColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...announcements.take(3).map((announcement) {
              final index = announcements.indexOf(announcement);
              return Column(
                children: [
                  if (index > 0) 
                    const Divider(
                      height: DashboardSizes.spacingLarge,
                      color: DashboardColors.borderLight,
                    ),
                  AnnouncementItem(announcement: announcement),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }
}