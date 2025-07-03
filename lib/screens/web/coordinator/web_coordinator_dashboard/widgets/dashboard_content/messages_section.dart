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
    final mentors = dashboardData.mentors.take(2).toList();
    final mentees = dashboardData.mentees.take(2).toList();
    
    // Debug logging
    print('Messages Section - Mentors: ${mentors.length}');
    print('Messages Section - Mentees: ${mentees.length}');
    if (mentors.isNotEmpty) print('First mentor: ${mentors[0]}');
    if (mentees.isNotEmpty) print('First mentee: ${mentees[0]}');
    
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
            // Real mentor list
            if (mentors.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No mentors available',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              )
            else
              ...mentors.map((mentor) => MessageListTile(
                name: mentor['name'] ?? 'Unknown Mentor',
                description: '${mentor['year_major'] ?? ''}, ${mentor['department'] ?? 'Department'}',
                role: 'Mentor',
              )).toList(),
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
            // Real mentee list
            if (mentees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No mentees available',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              )
            else
              ...mentees.map((mentee) => MessageListTile(
                name: mentee['name'] ?? 'Unknown Mentee',
                description: '${mentee['year_major'] ?? ''}, ${mentee['department'] ?? 'Department'}',
                role: 'Mentee',
              )).toList(),
          ],
        ),
      ),
    );
  }
}