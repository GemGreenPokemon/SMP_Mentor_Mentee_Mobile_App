import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/action_item_tile.dart';

class ActionItemsSection extends StatelessWidget {
  const ActionItemsSection({super.key});

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
              'Action Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const ActionItemTile(
              title: 'Review Mentor Applications',
              subtitle: '3 pending reviews',
              icon: Icons.person_add,
            ),
            const Divider(),
            const ActionItemTile(
              title: 'Survey Analysis Due',
              subtitle: 'End of week deadline',
              icon: Icons.assessment,
            ),
            const Divider(),
            const ActionItemTile(
              title: 'Update Program Resources',
              subtitle: 'Requested by mentors',
              icon: Icons.update,
            ),
          ],
        ),
      ),
    );
  }
}