import 'package:flutter/material.dart';
import '../../models/coordinator_dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/activity_item.dart';

class ActivitySection extends StatelessWidget {
  final CoordinatorDashboardData dashboardData;

  const ActivitySection({
    super.key,
    required this.dashboardData,
  });

  IconData _getIconForActivity(String? type) {
    switch (type) {
      case 'meeting':
        return Icons.event_available;
      case 'registration':
        return Icons.person_add;
      case 'assignment':
        return Icons.assignment_turned_in;
      case 'resource':
        return Icons.upload_file;
      case 'survey':
        return Icons.poll;
      default:
        return Icons.update;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = dashboardData.recentActivities ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  onPressed: () {
                    // TODO: Filter action
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No recent activities',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...activities.take(4).map((activity) {
                final index = activities.indexOf(activity);
                return Column(
                  children: [
                    ActivityItem(
                      title: activity['description'] ?? 'Activity',
                      subtitle: activity['details'] ?? '',
                      time: activity['time'] ?? 'Recently',
                      icon: _getIconForActivity(activity['type']),
                    ),
                    if (index < 3 && index < activities.length - 1)
                      const Divider(),
                  ],
                );
              }).toList(),
            // Fallback to hardcoded activities if no data
            if (activities.isEmpty) ...[
              const ActivityItem(
                title: 'New Survey Response',
                subtitle: 'From: Dr. Smith (Mentor)',
                time: '10 minutes ago',
                icon: Icons.poll,
              ),
              const Divider(),
              const ActivityItem(
                title: 'Meeting Completed',
                subtitle: 'Alice Johnson & Dr. Smith',
                time: '1 hour ago',
                icon: Icons.check_circle,
              ),
              const Divider(),
              const ActivityItem(
                title: 'Resource Added',
                subtitle: 'New Mentorship Guide',
                time: '2 hours ago',
                icon: Icons.upload_file,
              ),
              const Divider(),
              const ActivityItem(
                title: 'New Mentor Application',
                subtitle: 'From: Jordan Peterson',
                time: '3 hours ago',
                icon: Icons.person_add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}