import 'package:flutter/material.dart';
import '../../utils/resource_constants.dart';
import '../dialogs/category_management_dialog.dart';

class CoordinatorControls extends StatelessWidget {
  final VoidCallback onAddResource;

  const CoordinatorControls({
    super.key,
    required this.onAddResource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ResourceConstants.mediumPadding),
      margin: const EdgeInsets.only(bottom: ResourceConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResourceConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Resource'),
            onPressed: onAddResource,
          ),
          const SizedBox(width: ResourceConstants.mediumPadding),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder),
            label: const Text('Manage Categories'),
            onPressed: () => _showManageCategoriesDialog(context),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }
}