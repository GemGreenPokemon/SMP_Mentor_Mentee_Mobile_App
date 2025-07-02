import 'package:flutter/material.dart';
import '../../models/coordinator_dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/message_list_tile.dart';

class MessagesSection extends StatelessWidget {
  final CoordinatorDashboardData dashboardData;

  const MessagesSection({
    super.key,
    required this.dashboardData,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Direct Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Message'),
                  onPressed: () {
                    // TODO: New message action
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Mentors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Mock list of mentors
            const MessageListTile(
              name: 'Sarah Martinez',
              description: '3rd Year, Computer Science Major',
              role: 'Mentor',
            ),
            const MessageListTile(
              name: 'John Davis',
              description: '4th Year, Biology Major',
              role: 'Mentor',
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Mentees',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Mock list of mentees
            const MessageListTile(
              name: 'Alice Johnson',
              description: '1st Year, Biology Major',
              role: 'Mentee',
            ),
            const MessageListTile(
              name: 'Bob Wilson',
              description: '2nd Year, Psychology Major',
              role: 'Mentee',
            ),
          ],
        ),
      ),
    );
  }
}