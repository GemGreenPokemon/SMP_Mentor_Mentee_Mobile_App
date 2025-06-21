import 'package:flutter/material.dart';
import '../../utils/resource_constants.dart';
import 'resource_upload_dialog.dart';
import 'category_management_dialog.dart';

class ResourceManagementDialog extends StatelessWidget {
  const ResourceManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resource Management'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(
              context,
              icon: Icons.add_circle,
              iconColor: Colors.green,
              title: 'Add New Resource',
              onTap: () {
                Navigator.pop(context);
                _showAddResourceDialog(context);
              },
            ),
            const Divider(),
            _buildOption(
              context,
              icon: Icons.category,
              iconColor: Colors.blue,
              title: 'Manage Categories',
              onTap: () {
                Navigator.pop(context);
                _showManageCategoriesDialog(context);
              },
            ),
            const Divider(),
            _buildOption(
              context,
              icon: Icons.analytics,
              iconColor: Colors.purple,
              title: 'Resource Usage Analytics',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(ResourceConstants.analyticsComingSoonMessage),
                  ),
                );
              },
            ),
            const Divider(),
            _buildOption(
              context,
              icon: Icons.history,
              iconColor: Colors.orange,
              title: 'Resource History',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(ResourceConstants.historyComingSoonMessage),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showAddResourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ResourceUploadDialog(
        isMentor: false,
        isCoordinator: true,
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