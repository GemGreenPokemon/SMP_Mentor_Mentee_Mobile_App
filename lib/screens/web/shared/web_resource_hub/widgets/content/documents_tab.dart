import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../models/resource_category.dart';
import '../../utils/resource_constants.dart';
import '../../utils/resource_helpers.dart';
import '../shared/document_controls.dart';
import '../shared/document_data_table.dart';

class DocumentsTab extends StatelessWidget {
  final List<Resource> resources;
  final ResourceCategory selectedCategory;
  final Set<String> selectedDocumentIds;
  final bool isSelectionMode;
  final bool isMentor;
  final bool isCoordinator;
  final ValueChanged<ResourceCategory> onCategoryChanged;
  final ValueChanged<Resource> onResourceSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onBulkDelete;
  final VoidCallback onBulkAssign;
  final ValueChanged<Resource> onAssignToMentees;
  final ValueChanged<Resource> onEditDocument;
  final ValueChanged<Resource> onDeleteDocument;

  const DocumentsTab({
    super.key,
    required this.resources,
    required this.selectedCategory,
    required this.selectedDocumentIds,
    required this.isSelectionMode,
    required this.isMentor,
    required this.isCoordinator,
    required this.onCategoryChanged,
    required this.onResourceSelected,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onBulkDelete,
    required this.onBulkAssign,
    required this.onAssignToMentees,
    required this.onEditDocument,
    required this.onDeleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ResourceConstants.largePadding),
      child: Column(
        children: [
          if (isCoordinator || isSelectionMode)
            DocumentControls(
              isSelectionMode: isSelectionMode,
              selectedCount: selectedDocumentIds.length,
              selectedCategory: selectedCategory,
              isMentor: isMentor,
              onBulkDelete: onBulkDelete,
              onBulkAssign: onBulkAssign,
              onCategoryChanged: onCategoryChanged,
            ),
          Expanded(
            child: Card(
              child: DocumentDataTable(
                resources: resources,
                selectedDocumentIds: selectedDocumentIds,
                isMentor: isMentor,
                isCoordinator: isCoordinator,
                onSelectAll: onSelectAll,
                onResourceSelected: onResourceSelected,
                onAssignToMentees: onAssignToMentees,
                onEditDocument: onEditDocument,
                onDeleteDocument: onDeleteDocument,
              ),
            ),
          ),
        ],
      ),
    );
  }
}