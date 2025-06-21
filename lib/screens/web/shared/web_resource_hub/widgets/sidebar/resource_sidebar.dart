import 'package:flutter/material.dart';
import '../../models/resource_category.dart';
import '../../utils/resource_constants.dart';
import '../dialogs/category_management_dialog.dart';

class ResourceSidebar extends StatelessWidget {
  final ResourceCategory selectedCategory;
  final ValueChanged<ResourceCategory> onCategoryChanged;
  final VoidCallback onAddResource;

  const ResourceSidebar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onAddResource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResourceConstants.sidebarWidth,
      color: ResourceConstants.sidebarBackground,
      child: Column(
        children: [
          _buildQuickActions(context),
          const Divider(),
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(ResourceConstants.mediumPadding),
          child: Text(
            ResourceConstants.quickActionsTitle,
            style: TextStyle(
              fontSize: ResourceConstants.titleTextSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add_circle, color: Colors.green),
          title: const Text('Add Resource'),
          onTap: onAddResource,
        ),
        ListTile(
          leading: const Icon(Icons.category, color: Colors.blue),
          title: const Text('Manage Categories'),
          onTap: () => _showManageCategoriesDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.analytics, color: Colors.purple),
          title: const Text('Usage Analytics'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(ResourceConstants.analyticsComingSoonMessage),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(ResourceConstants.mediumPadding),
          child: Text(
            ResourceConstants.filterByCategoryTitle,
            style: TextStyle(
              fontSize: ResourceConstants.subtitleTextSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...ResourceCategory.values.map((category) {
          return RadioListTile<ResourceCategory>(
            title: Text(category.displayName),
            value: category,
            groupValue: selectedCategory,
            onChanged: (value) {
              if (value != null) {
                onCategoryChanged(value);
              }
            },
          );
        }).toList(),
      ],
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }
}