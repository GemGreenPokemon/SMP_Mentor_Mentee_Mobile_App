import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../utils/checklist_constants.dart';
import '../utils/checklist_helpers.dart';

class ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final int index;
  final bool isMentor;
  final ValueChanged<bool?>? onCompletionChanged;
  final VoidCallback? onApproveProof;
  final VoidCallback? onRejectProof;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isMentor,
    this.onCompletionChanged,
    this.onApproveProof,
    this.onRejectProof,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.completed,
              onChanged: isMentor ? onCompletionChanged : null,
              activeColor: ChecklistConstants.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 4),
                  _buildDescription(),
                  if (item.proof != null) ...[
                    const SizedBox(height: 8),
                    _buildProofSection(),
                  ],
                ],
              ),
            ),
            if (isMentor && item.proof != null && item.proofStatus == ChecklistConstants.proofStatusPending)
              _buildProofActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      item.title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        decoration: item.completed ? TextDecoration.lineThrough : null,
        color: item.completed ? Colors.grey : Colors.black,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      item.description,
      style: TextStyle(
        fontSize: 14,
        color: item.completed ? Colors.grey[400] : Colors.grey[600],
        decoration: item.completed ? TextDecoration.lineThrough : null,
      ),
    );
  }

  Widget _buildProofSection() {
    final statusColor = ChecklistHelpers.getProofStatusColor(item.proofStatus);
    final statusIcon = ChecklistHelpers.getProofStatusIcon(item.proofStatus);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                'Proof: ${item.proof}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: statusColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          if (item.proofStatus == ChecklistConstants.proofStatusRejected && 
              item.feedback != null) ...[
            const SizedBox(height: 4),
            Text(
              'Feedback: ${item.feedback}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProofActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: onApproveProof,
          tooltip: 'Approve',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: onRejectProof,
          tooltip: 'Reject',
        ),
      ],
    );
  }
}