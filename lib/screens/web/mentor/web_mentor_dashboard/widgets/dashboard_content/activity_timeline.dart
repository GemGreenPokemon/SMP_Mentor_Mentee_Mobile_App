import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/activity_item.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DashboardSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(DashboardSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              DashboardStrings.recentActivity,
              style: TextStyle(
                fontSize: DashboardSizes.fontXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DashboardSizes.spacingMedium),
            const ActivityItem(
              text: 'Scheduled meeting with Alice Johnson',
              time: '2 hours ago',
              icon: Icons.event_available,
              color: Colors.blue,
            ),
            const Divider(),
            const ActivityItem(
              text: 'Completed Progress Report for Carlos Rodriguez',
              time: 'Yesterday',
              icon: Icons.check_circle,
              color: DashboardColors.statusGreen,
            ),
            const Divider(),
            const ActivityItem(
              text: 'Added new resources to the Resource Hub',
              time: '2 days ago',
              icon: Icons.folder_open,
              color: DashboardColors.statusAmber,
            ),
            const Divider(),
            const ActivityItem(
              text: 'Checked in for meeting with Bob Wilson',
              time: '4 days ago',
              icon: Icons.login,
              color: DashboardColors.statusPurple,
            ),
          ],
        ),
      ),
    );
  }
}