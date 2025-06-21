import 'package:flutter/material.dart';
import '../../utils/resource_constants.dart';
import '../../widgets/dialogs/resource_upload_dialog.dart';
import '../../widgets/dialogs/resource_management_dialog.dart';
import '../../../web_settings/web_settings_screen.dart';

class ResourceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isMentor;
  final bool isCoordinator;
  final bool isSelectionMode;
  final int selectedCount;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSelection;

  const ResourceAppBar({
    super.key,
    required this.isMentor,
    required this.isCoordinator,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSelection,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Text('Resource Hub'),
          if (isSelectionMode) ...[
            const SizedBox(width: ResourceConstants.mediumPadding),
            Chip(
              label: Text('$selectedCount selected'),
              onDeleted: onClearSelection,
            ),
          ],
        ],
      ),
      actions: [
        // Search bar
        Container(
          width: ResourceConstants.searchBarWidth,
          margin: const EdgeInsets.symmetric(
            vertical: ResourceConstants.smallPadding,
            horizontal: ResourceConstants.smallPadding,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search resources...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ResourceConstants.cardBorderRadius),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ResourceConstants.mediumPadding,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        if (isMentor || isCoordinator) ...[
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: ResourceConstants.uploadTooltip,
            onPressed: () => _showUploadDialog(context),
          ),
          if (isCoordinator)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: ResourceConstants.manageTooltip,
              onPressed: () => _showResourceManagementDialog(context),
            ),
        ],
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: ResourceConstants.settingsTooltip,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebSettingsScreen(isMentor: isMentor),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResourceUploadDialog(
        isMentor: isMentor,
        isCoordinator: isCoordinator,
      ),
    );
  }

  void _showResourceManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ResourceManagementDialog(),
    );
  }
}