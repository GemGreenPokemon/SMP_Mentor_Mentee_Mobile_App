import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/mentee_list_item.dart';

class MenteesOverview extends StatelessWidget {
  final List<Mentee> mentees;
  final VoidCallback onViewAll;
  final VoidCallback onMessageMentee;

  const MenteesOverview({
    super.key,
    required this.mentees,
    required this.onViewAll,
    required this.onMessageMentee,
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
                const Expanded(
                  child: Text(
                    DashboardStrings.yourMentees,
                    style: TextStyle(
                      fontSize: DashboardSizes.fontXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text(DashboardStrings.viewAll),
                ),
              ],
            ),
            const SizedBox(height: DashboardSizes.spacingMedium),
            ...mentees.take(3).map((mentee) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DashboardSizes.spacingSmall + 4),
                child: MenteeListItem(
                  name: mentee.name,
                  program: mentee.program,
                  progress: mentee.progress,
                  onTap: () {
                    // View mentee details
                  },
                  onMessage: onMessageMentee,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}