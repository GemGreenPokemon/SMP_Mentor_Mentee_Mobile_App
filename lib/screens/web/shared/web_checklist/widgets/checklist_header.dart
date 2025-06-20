import 'package:flutter/material.dart';
import '../utils/checklist_constants.dart';

class ChecklistHeader extends StatelessWidget {
  final bool isMentor;
  final VoidCallback? onCreateChecklist;

  const ChecklistHeader({
    super.key,
    required this.isMentor,
    this.onCreateChecklist,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Checklists'),
      backgroundColor: ChecklistConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (isMentor && onCreateChecklist != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Custom Checklist'),
              onPressed: onCreateChecklist,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ChecklistConstants.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}