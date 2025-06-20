import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import '../../models/checklist.dart';
import '../../models/checklist_item.dart';
import '../../utils/checklist_constants.dart';
import '../../utils/checklist_helpers.dart';
import '../checklist_item_tile.dart';
import 'reject_proof_dialog.dart';

class ChecklistDetailsDialog extends StatefulWidget {
  final Checklist checklist;
  final bool isMentor;
  final String? selectedMenteeId;
  final List<Map<String, String>> mentees;
  final ValueChanged<Checklist>? onChecklistUpdated;

  const ChecklistDetailsDialog({
    super.key,
    required this.checklist,
    required this.isMentor,
    this.selectedMenteeId,
    this.mentees = const [],
    this.onChecklistUpdated,
  });

  @override
  State<ChecklistDetailsDialog> createState() => _ChecklistDetailsDialogState();
}

class _ChecklistDetailsDialogState extends State<ChecklistDetailsDialog> {
  late Checklist _checklist;
  late String? _selectedMenteeId;

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
    _selectedMenteeId = widget.selectedMenteeId ?? 'all';
  }

  void _updateChecklistItem(int index, ChecklistItem updatedItem) {
    setState(() {
      final items = List<ChecklistItem>.from(_checklist.items);
      items[index] = updatedItem;
      _checklist = _checklist.copyWith(items: items);
    });
  }

  void _saveChanges() {
    widget.onChecklistUpdated?.call(_checklist);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checklist updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = Responsive.isDesktop(context) 
        ? ChecklistConstants.maxDialogWidth 
        : 600.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChecklistConstants.dialogBorderRadius),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (widget.isMentor) _buildMenteeSelector(),
            Flexible(child: _buildItemsList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(ChecklistConstants.largePadding),
      decoration: BoxDecoration(
        color: ChecklistConstants.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ChecklistConstants.dialogBorderRadius),
          topRight: Radius.circular(ChecklistConstants.dialogBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _checklist.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _checklist.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeSelector() {
    return Padding(
      padding: const EdgeInsets.all(ChecklistConstants.defaultPadding),
      child: Row(
        children: [
          const Text(
            'Viewing for:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: ChecklistConstants.minDropdownWidth,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _selectedMenteeId == 'all' 
                  ? widget.mentees.first['id'] 
                  : _selectedMenteeId,
              items: widget.mentees
                  .where((m) => m['id'] != 'all')
                  .map((mentee) {
                return DropdownMenuItem<String>(
                  value: mentee['id']!,
                  child: Text(mentee['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMenteeId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChecklistConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _checklist.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return ChecklistItemTile(
            item: item,
            index: index,
            isMentor: widget.isMentor,
            onCompletionChanged: widget.isMentor 
                ? (value) => _updateChecklistItem(
                    index, 
                    item.copyWith(completed: value),
                  )
                : null,
            onApproveProof: widget.isMentor && item.proofStatus == ChecklistConstants.proofStatusPending
                ? () => _updateChecklistItem(
                    index,
                    item.copyWith(proofStatus: ChecklistConstants.proofStatusApproved),
                  )
                : null,
            onRejectProof: widget.isMentor && item.proofStatus == ChecklistConstants.proofStatusPending
                ? () => _showRejectProofDialog(index, item)
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(ChecklistConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ChecklistConstants.dialogBorderRadius),
          bottomRight: Radius.circular(ChecklistConstants.dialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildProgressSummary(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress: ${ChecklistHelpers.getProgressPercentage(_checklist.progress)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_checklist.completedItemsCount} of ${_checklist.totalItemsCount} tasks completed',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (widget.isMentor) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChecklistConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  void _showRejectProofDialog(int index, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => RejectProofDialog(
        onReject: (feedback) {
          _updateChecklistItem(
            index,
            item.copyWith(
              proofStatus: ChecklistConstants.proofStatusRejected,
              feedback: feedback,
            ),
          );
        },
      ),
    );
  }
}