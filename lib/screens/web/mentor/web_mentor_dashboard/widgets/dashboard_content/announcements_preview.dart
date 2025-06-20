import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
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
    return Card(
      elevation: DashboardSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(DashboardSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  DashboardStrings.announcements,
                  style: TextStyle(
                    fontSize: DashboardSizes.fontXLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text(DashboardStrings.viewAll),
                ),
              ],
            ),
            const SizedBox(height: DashboardSizes.spacingMedium),
            ...announcements.take(2).map((announcement) => AnnouncementItem(
                  title: announcement.title,
                  content: announcement.content,
                  time: announcement.time,
                  priority: announcement.priority,
                )),
          ],
        ),
      ),
    );
  }
}