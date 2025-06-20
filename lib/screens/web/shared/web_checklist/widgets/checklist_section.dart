import 'package:flutter/material.dart';
import '../models/checklist.dart';
import '../utils/checklist_constants.dart';
import 'checklist_grid.dart';
import 'empty_state.dart';

class ChecklistSection extends StatelessWidget {
  final String title;
  final List<Checklist> checklists;
  final bool isMentor;
  final Function(Checklist) onChecklistTap;
  final Function(Checklist)? onEdit;
  final Function(Checklist)? onDuplicate;
  final Function(Checklist)? onDelete;
  final VoidCallback? onCreateNew;
  final String emptyStateTitle;
  final String emptyStateSubtitle;

  const ChecklistSection({
    super.key,
    required this.title,
    required this.checklists,
    required this.isMentor,
    required this.onChecklistTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onCreateNew,
    this.emptyStateTitle = 'No checklists found',
    this.emptyStateSubtitle = 'Get started by creating your first checklist.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (checklists.isEmpty)
          EmptyState(
            title: emptyStateTitle,
            subtitle: emptyStateSubtitle,
            onActionPressed: onCreateNew,
            actionLabel: onCreateNew != null ? 'Create Checklist' : null,
          )
        else
          ChecklistGrid(
            checklists: checklists,
            isMentor: isMentor,
            onChecklistTap: onChecklistTap,
            onEdit: onEdit,
            onDuplicate: onDuplicate,
            onDelete: onDelete,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: ChecklistConstants.sectionTitleStyle,
        ),
        Text(
          '${checklists.length} checklist${checklists.length != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}