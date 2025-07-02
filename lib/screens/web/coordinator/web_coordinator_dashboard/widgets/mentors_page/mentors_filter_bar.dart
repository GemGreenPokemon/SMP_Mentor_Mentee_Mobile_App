import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class MentorsFilterBar extends StatelessWidget {
  const MentorsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search mentors...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CoordinatorDashboardDimensions.cardBorderRadius),
                borderSide: BorderSide(
                  color: CoordinatorDashboardColors.textSecondary.withOpacity(0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: CoordinatorDashboardDimensions.paddingMedium),
        DropdownButton<String>(
          hint: const Text('Department'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Departments')),
            DropdownMenuItem(value: 'cs', child: Text('Computer Science')),
            DropdownMenuItem(value: 'bio', child: Text('Biology')),
            DropdownMenuItem(value: 'psych', child: Text('Psychology')),
          ],
          onChanged: (value) {
            // TODO: Filter by department
          },
        ),
        const SizedBox(width: CoordinatorDashboardDimensions.paddingMedium),
        DropdownButton<String>(
          hint: const Text('Status'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
          ],
          onChanged: (value) {
            // TODO: Filter by status
          },
        ),
        const SizedBox(width: CoordinatorDashboardDimensions.paddingMedium),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Mentor'),
          onPressed: () {
            // TODO: Add new mentor
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CoordinatorDashboardColors.primaryDark,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}