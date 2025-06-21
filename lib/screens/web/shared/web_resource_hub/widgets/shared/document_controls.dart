import 'package:flutter/material.dart';
import '../../models/resource_category.dart';
import '../../utils/resource_constants.dart';

class DocumentControls extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final ResourceCategory selectedCategory;
  final bool isMentor;
  final VoidCallback onBulkDelete;
  final VoidCallback onBulkAssign;
  final ValueChanged<ResourceCategory> onCategoryChanged;

  const DocumentControls({
    super.key,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.selectedCategory,
    required this.isMentor,
    required this.onBulkDelete,
    required this.onBulkAssign,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ResourceConstants.mediumPadding),
      margin: const EdgeInsets.only(bottom: ResourceConstants.mediumPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResourceConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          if (isSelectionMode) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: Text('Delete ($selectedCount)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: onBulkDelete,
            ),
            const SizedBox(width: ResourceConstants.mediumPadding),
            if (isMentor)
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: Text('Assign to Mentees ($selectedCount)'),
                onPressed: onBulkAssign,
              ),
          ],
          const Spacer(),
          DropdownButton<ResourceCategory>(
            value: selectedCategory,
            items: ResourceCategory.values.map((category) {
              return DropdownMenuItem<ResourceCategory>(
                value: category,
                child: Text(category.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onCategoryChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}