import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class PendingMentorsCard extends StatelessWidget {
  const PendingMentorsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CoordinatorDashboardDimensions.paddingLarge - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Mentor Applications',
              style: TextStyle(
                fontSize: CoordinatorDashboardDimensions.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: CoordinatorDashboardDimensions.paddingMedium),
            // Placeholder for pending mentors
            const Center(
              child: Text('Pending mentor applications to be implemented'),
            ),
          ],
        ),
      ),
    );
  }
}