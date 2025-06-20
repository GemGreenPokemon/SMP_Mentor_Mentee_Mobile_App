import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class MenteesSearchBar extends StatelessWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onFilterChanged;
  final VoidCallback onAddMentee;

  const MenteesSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onAddMentee,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DashboardSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: DashboardStrings.searchMentees,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DashboardSizes.spacingMedium,
                    vertical: DashboardSizes.spacingSmall + 4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DashboardSizes.spacingMedium),
            DropdownButton<String>(
              value: 'All',
              items: const [
                DropdownMenuItem(value: 'All', child: Text(DashboardStrings.allMentees)),
                DropdownMenuItem(value: 'Active', child: Text(DashboardStrings.active)),
                DropdownMenuItem(value: 'Inactive', child: Text(DashboardStrings.inactive)),
              ],
              onChanged: onFilterChanged,
            ),
            const SizedBox(width: DashboardSizes.spacingMedium),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text(DashboardStrings.addMentee),
              onPressed: onAddMentee,
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}