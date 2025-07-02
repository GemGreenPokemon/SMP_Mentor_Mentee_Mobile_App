import 'package:flutter/material.dart';
import '../../models/coordinator_dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/event_card.dart';

class EventsSection extends StatelessWidget {
  final CoordinatorDashboardData dashboardData;

  const EventsSection({
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
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const EventCard(
              title: 'Mentor Training Workshop',
              time: 'Tomorrow, 2:00 PM',
              attendance: '24 Registered',
              registrationProgress: 0.8,
            ),
            const SizedBox(height: 12),
            const EventCard(
              title: 'Group Mentoring Session',
              time: 'Friday, 3:00 PM',
              attendance: '18 Registered',
              registrationProgress: 0.6,
            ),
            const SizedBox(height: 12),
            const EventCard(
              title: 'End of Year Celebration',
              time: 'May 30, 5:00 PM',
              attendance: '42 Registered',
              registrationProgress: 0.7,
            ),
          ],
        ),
      ),
    );
  }
}