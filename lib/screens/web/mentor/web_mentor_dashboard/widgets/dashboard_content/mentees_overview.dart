import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/mentee_list_item.dart';
import '../shared/dashboard_card_container.dart';

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
    return DashboardCardContainer(
      title: DashboardStrings.yourMentees,
      actions: [
        DashboardCardAction(
          label: DashboardStrings.viewAll,
          onPressed: onViewAll,
          icon: Icons.arrow_forward,
        ),
      ],
      minHeight: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mentees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DashboardSizes.spacingXLarge),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: DashboardSizes.spacingMedium),
                  Text(
                    'No mentees assigned yet',
                    style: TextStyle(
                      fontSize: DashboardSizes.fontLarge,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
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
    );
  }
}