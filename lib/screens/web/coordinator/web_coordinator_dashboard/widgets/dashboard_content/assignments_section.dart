import 'package:flutter/material.dart';
import '../../models/coordinator_dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/assignment_item.dart';

class AssignmentsSection extends StatelessWidget {
  final CoordinatorDashboardData dashboardData;

  const AssignmentsSection({
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
                  'Mentor-Mentee Assignments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All'),
                  onPressed: () {
                    // TODO: View all assignments
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Recent Assignments
            const AssignmentItem(
              mentorName: 'Sarah Martinez',
              menteeName: 'Alice Johnson',
              assignmentDate: '2 days ago',
              isCoordinatorAssigned: true,
            ),
            const Divider(),
            const AssignmentItem(
              mentorName: 'John Davis',
              menteeName: 'Bob Wilson',
              assignmentDate: '1 week ago',
              isCoordinatorAssigned: false,
            ),
            const Divider(),
            const AssignmentItem(
              mentorName: 'Maria Rodriguez',
              menteeName: 'David Lee',
              assignmentDate: '3 days ago',
              isCoordinatorAssigned: true,
            ),
          ],
        ),
      ),
    );
  }
}