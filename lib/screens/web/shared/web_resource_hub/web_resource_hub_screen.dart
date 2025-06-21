import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/mentor_service.dart';
import 'models/resource.dart';
import 'models/resource_category.dart';
import 'models/resource_filter.dart';
import 'utils/resource_constants.dart';
import 'utils/resource_helpers.dart';
import 'widgets/layout/resource_app_bar.dart';
import 'widgets/layout/resource_tab_bar.dart';
import 'widgets/sidebar/resource_sidebar.dart';
import 'widgets/content/general_resources_tab.dart';
import 'widgets/content/documents_tab.dart';
import 'widgets/dialogs/resource_upload_dialog.dart';
import 'widgets/dialogs/resource_edit_dialog.dart';
import 'widgets/dialogs/assign_to_mentees_dialog.dart';
import 'widgets/dialogs/delete_confirmation_dialog.dart';

class WebResourceHubScreen extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  
  const WebResourceHubScreen({
    super.key,
    this.isMentor = true,
    this.isCoordinator = false,
  });

  @override
  State<WebResourceHubScreen> createState() => _WebResourceHubScreenState();
}

class _WebResourceHubScreenState extends State<WebResourceHubScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ResourceFilter _filter = const ResourceFilter();
  Set<String> selectedDocumentIds = {};
  bool isSelectionMode = false;
  List<Resource> _resources = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadResources();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadResources() {
    // In production, this would load from Firebase
    setState(() {
      _resources = ResourceHelpers.generateMockResources();
    });
  }

  List<Resource> get _filteredResources {
    return _resources.where((resource) {
      return ResourceHelpers.matchesFilter(
        resource,
        _filter.searchQuery,
        _filter.category,
        widget.isMentor,
        widget.isCoordinator,
      );
    }).toList();
  }

  void _updateFilter({
    String? searchQuery,
    ResourceCategory? category,
  }) {
    setState(() {
      _filter = _filter.copyWith(
        searchQuery: searchQuery,
        category: category,
      );
    });
  }

  void _clearSelection() {
    setState(() {
      selectedDocumentIds.clear();
      isSelectionMode = false;
    });
  }

  void _toggleResourceSelection(Resource resource) {
    setState(() {
      if (selectedDocumentIds.contains(resource.id)) {
        selectedDocumentIds.remove(resource.id);
        if (selectedDocumentIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedDocumentIds.add(resource.id);
        isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedDocumentIds.length == _filteredResources.length) {
        selectedDocumentIds.clear();
        isSelectionMode = false;
      } else {
        selectedDocumentIds = _filteredResources.map((r) => r.id).toSet();
        isSelectionMode = true;
      }
    });
  }

  void _showAddResourceDialog() {
    showDialog(
      context: context,
      builder: (context) => ResourceUploadDialog(
        isMentor: widget.isMentor,
        isCoordinator: widget.isCoordinator,
      ),
    );
  }

  void _showEditResourceDialog(Resource resource) {
    showDialog(
      context: context,
      builder: (context) => ResourceEditDialog(
        resource: resource,
        isMentor: widget.isMentor,
        isCoordinator: widget.isCoordinator,
      ),
    );
  }

  void _showAssignToMenteesDialog(Resource resource) {
    showDialog(
      context: context,
      builder: (context) => AssignToMenteesDialog(resource: resource),
    );
  }

  void _showBulkAssignDialog() {
    // Use the first selected resource as a placeholder
    final firstResource = _resources.firstWhere((r) => selectedDocumentIds.contains(r.id));
    showDialog(
      context: context,
      builder: (context) => AssignToMenteesDialog(
        resource: firstResource,
        isBulkAssign: true,
        resourceCount: selectedDocumentIds.length,
      ),
    );
  }

  void _showDeleteConfirmation(Resource resource) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(resource: resource),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _resources.removeWhere((r) => r.id == resource.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(ResourceConstants.deleteSuccessMessage),
          ),
        );
      }
    });
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        isBulkDelete: true,
        deleteCount: selectedDocumentIds.length,
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _resources.removeWhere((r) => selectedDocumentIds.contains(r.id));
          _clearSelection();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(ResourceConstants.bulkDeleteSuccessMessage),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > ResourceConstants.wideScreenBreakpoint;
    
    return Scaffold(
      backgroundColor: ResourceConstants.backgroundColor,
      appBar: ResourceAppBar(
        isMentor: widget.isMentor,
        isCoordinator: widget.isCoordinator,
        isSelectionMode: isSelectionMode,
        selectedCount: selectedDocumentIds.length,
        searchQuery: _filter.searchQuery,
        onSearchChanged: (value) => _updateFilter(searchQuery: value),
        onClearSelection: _clearSelection,
      ),
      body: Row(
        children: [
          if (isWideScreen && widget.isCoordinator)
            ResourceSidebar(
              selectedCategory: _filter.category,
              onCategoryChanged: (category) => _updateFilter(category: category),
              onAddResource: _showAddResourceDialog,
            ),
          Expanded(
            child: Column(
              children: [
                ResourceTabBar(tabController: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      GeneralResourcesTab(
                        isCoordinator: widget.isCoordinator,
                        onAddResource: _showAddResourceDialog,
                      ),
                      DocumentsTab(
                        resources: _filteredResources,
                        selectedCategory: _filter.category,
                        selectedDocumentIds: selectedDocumentIds,
                        isSelectionMode: isSelectionMode,
                        isMentor: widget.isMentor,
                        isCoordinator: widget.isCoordinator,
                        onCategoryChanged: (category) => _updateFilter(category: category),
                        onResourceSelected: _toggleResourceSelection,
                        onSelectAll: _selectAll,
                        onClearSelection: _clearSelection,
                        onBulkDelete: _showBulkDeleteConfirmation,
                        onBulkAssign: _showBulkAssignDialog,
                        onAssignToMentees: _showAssignToMenteesDialog,
                        onEditDocument: _showEditResourceDialog,
                        onDeleteDocument: _showDeleteConfirmation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}