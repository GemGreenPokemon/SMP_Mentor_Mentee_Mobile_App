import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class MentorsListCard extends StatelessWidget {
  const MentorsListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CoordinatorDashboardDimensions.paddingLarge - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Active Mentors',
                    style: TextStyle(
                      fontSize: CoordinatorDashboardDimensions.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: Refresh mentor list
                  },
                  tooltip: 'Refresh List',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Export mentor list
                  },
                  tooltip: 'Export List',
                ),
              ],
            ),
            const SizedBox(height: CoordinatorDashboardDimensions.paddingMedium),
            // Placeholder for mentor list
            const Center(
              child: Text('Mentor list to be implemented'),
            ),
          ],
        ),
      ),
    );
  }
}