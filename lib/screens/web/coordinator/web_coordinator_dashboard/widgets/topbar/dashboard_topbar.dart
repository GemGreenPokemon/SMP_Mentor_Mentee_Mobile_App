import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class DashboardTopbar extends StatelessWidget {
  final String title;

  const DashboardTopbar({
    super.key,
    required this.title,
  });

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Mentor-Mentee Match Issues'),
              subtitle: Text('3 mentees still need mentors'),
            ),
            ListTile(
              leading: Icon(Icons.assignment_late, color: Colors.orange),
              title: Text('Pending Reports'),
              subtitle: Text('5 mentors have overdue reports'),
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.blue),
              title: Text('Upcoming Program Review'),
              subtitle: Text('Scheduled for next week'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoordinatorDashboardDimensions.paddingLarge,
        vertical: CoordinatorDashboardDimensions.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(CoordinatorDashboardDimensions.cardBorderRadius),
          bottomRight: Radius.circular(CoordinatorDashboardDimensions.cardBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: CoordinatorDashboardDimensions.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Clarissa Correa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search',
          ),
          const SizedBox(width: CoordinatorDashboardDimensions.paddingSmall),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: CoordinatorDashboardDimensions.paddingSmall),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // TODO: Show help
            },
            tooltip: 'Help',
          ),
        ],
      ),
    );
  }
}