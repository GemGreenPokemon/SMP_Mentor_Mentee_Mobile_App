import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          CoordinatorDashboardStrings.quickActions,
          style: TextStyle(
            fontSize: CoordinatorDashboardDimensions.fontSizeXXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: CoordinatorDashboardDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: CoordinatorDashboardStrings.manageEvents,
                icon: Icons.event,
                onTap: () {
                  Navigator.pushNamed(context, '/manage-events');
                },
              ),
            ),
            const SizedBox(width: CoordinatorDashboardDimensions.paddingMedium),
            Expanded(
              child: QuickActionCard(
                title: CoordinatorDashboardStrings.qualtrics,
                icon: Icons.analytics,
                onTap: () {
                  Navigator.pushNamed(context, '/qualtrics');
                },
              ),
            ),
            const SizedBox(width: CoordinatorDashboardDimensions.paddingMedium),
            Expanded(
              child: QuickActionCard(
                title: CoordinatorDashboardStrings.resources,
                icon: Icons.folder_shared,
                onTap: () {
                  Navigator.pushNamed(context, '/resource-hub');
                },
              ),
            ),
            const SizedBox(width: CoordinatorDashboardDimensions.paddingMedium),
            Expanded(
              child: QuickActionCard(
                title: CoordinatorDashboardStrings.announcements,
                icon: Icons.campaign,
                onTap: () {
                  Navigator.pushNamed(context, '/announcements');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}