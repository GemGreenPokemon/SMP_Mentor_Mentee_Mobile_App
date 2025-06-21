import 'package:flutter/material.dart';
import '../../utils/resource_helpers.dart';
import '../../utils/resource_constants.dart';

class CategoryManagementDialog extends StatelessWidget {
  const CategoryManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ResourceHelpers.getCategories();

    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(categories[index]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: ResourceConstants.iconSizeSmall),
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement edit category
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: ResourceConstants.iconSizeSmall,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement delete category
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implement add category
          },
        ),
      ],
    );
  }
}