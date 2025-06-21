import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../utils/resource_constants.dart';
import '../../utils/resource_helpers.dart';

class DocumentDataTable extends StatelessWidget {
  final List<Resource> resources;
  final Set<String> selectedDocumentIds;
  final bool isMentor;
  final bool isCoordinator;
  final VoidCallback onSelectAll;
  final ValueChanged<Resource> onResourceSelected;
  final ValueChanged<Resource> onAssignToMentees;
  final ValueChanged<Resource> onEditDocument;
  final ValueChanged<Resource> onDeleteDocument;

  const DocumentDataTable({
    super.key,
    required this.resources,
    required this.selectedDocumentIds,
    required this.isMentor,
    required this.isCoordinator,
    required this.onSelectAll,
    required this.onResourceSelected,
    required this.onAssignToMentees,
    required this.onEditDocument,
    required this.onDeleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        dataRowMinHeight: ResourceConstants.dataRowMinHeight,
        dataRowMaxHeight: ResourceConstants.dataRowMaxHeight,
        columns: _buildColumns(),
        rows: resources.map((resource) => _buildDataRow(context, resource)).toList(),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      if (isCoordinator || isMentor)
        DataColumn(
          label: Checkbox(
            value: selectedDocumentIds.length == resources.length && 
                   resources.isNotEmpty,
            onChanged: (value) => onSelectAll(),
          ),
        ),
      const DataColumn(label: Text('Title')),
      const DataColumn(label: Text('Description')),
      const DataColumn(label: Text('Type')),
      const DataColumn(label: Text('Category')),
      const DataColumn(label: Text('Date Added')),
      if (isMentor || isCoordinator)
        const DataColumn(label: Text('Assigned To')),
      const DataColumn(label: Text('Actions')),
    ];
  }

  DataRow _buildDataRow(BuildContext context, Resource resource) {
    final isSelected = selectedDocumentIds.contains(resource.id);
    
    return DataRow(
      selected: isSelected,
      onSelectChanged: (isCoordinator || isMentor) 
          ? (value) => onResourceSelected(resource)
          : null,
      cells: [
        if (isCoordinator || isMentor)
          DataCell(
            Checkbox(
              value: isSelected,
              onChanged: (value) => onResourceSelected(resource),
            ),
          ),
        DataCell(_buildTitleCell(resource)),
        DataCell(_buildDescriptionCell(resource)),
        DataCell(_buildTypeChip(resource)),
        DataCell(Text(resource.category)),
        DataCell(Text(ResourceHelpers.formatDate(resource.dateAdded))),
        if (isMentor || isCoordinator)
          DataCell(_buildAssignedToCell(resource)),
        DataCell(_buildActionsCell(context, resource)),
      ],
    );
  }

  Widget _buildTitleCell(Resource resource) {
    return Row(
      children: [
        Icon(
          ResourceHelpers.getFileIcon(resource.type),
          size: ResourceConstants.iconSizeSmall,
          color: ResourceHelpers.getFileColor(resource.type),
        ),
        const SizedBox(width: ResourceConstants.smallPadding),
        Text(
          resource.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDescriptionCell(Resource resource) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Text(
        resource.description,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTypeChip(Resource resource) {
    return Chip(
      label: Text(
        resource.type.value,
        style: const TextStyle(fontSize: ResourceConstants.captionTextSize),
      ),
      backgroundColor: ResourceHelpers.getFileColor(resource.type).withOpacity(0.2),
    );
  }

  Widget _buildAssignedToCell(Resource resource) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: resource.assignedTo.isEmpty
          ? const Text('-')
          : Wrap(
              spacing: ResourceConstants.tinyPadding,
              runSpacing: ResourceConstants.tinyPadding,
              clipBehavior: Clip.hardEdge,
              children: resource.assignedTo.map((mentee) {
                return SizedBox(
                  height: ResourceConstants.chipHeight,
                  child: Chip(
                    label: Text(
                      mentee,
                      style: const TextStyle(fontSize: ResourceConstants.smallTextSize),
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: Colors.green[100],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ResourceConstants.smallPadding,
                      vertical: 0,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildActionsCell(BuildContext context, Resource resource) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.download, size: ResourceConstants.iconSizeSmall),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${ResourceConstants.downloadingMessage} ${resource.title}...'),
              ),
            );
          },
        ),
        if (isMentor)
          IconButton(
            icon: const Icon(Icons.person_add, size: ResourceConstants.iconSizeSmall),
            onPressed: () => onAssignToMentees(resource),
          ),
        if (isCoordinator) ...[
          IconButton(
            icon: const Icon(Icons.edit, size: ResourceConstants.iconSizeSmall),
            onPressed: () => onEditDocument(resource),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: ResourceConstants.iconSizeSmall, color: Colors.red),
            onPressed: () => onDeleteDocument(resource),
          ),
        ],
      ],
    );
  }
}