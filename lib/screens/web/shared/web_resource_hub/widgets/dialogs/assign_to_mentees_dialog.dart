import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../services/mentor_service.dart';
import '../../models/resource.dart';
import '../../utils/resource_constants.dart';

class AssignToMenteesDialog extends StatefulWidget {
  final Resource resource;
  final bool isBulkAssign;
  final int resourceCount;

  const AssignToMenteesDialog({
    super.key,
    required this.resource,
    this.isBulkAssign = false,
    this.resourceCount = 1,
  });

  @override
  State<AssignToMenteesDialog> createState() => _AssignToMenteesDialogState();
}

class _AssignToMenteesDialogState extends State<AssignToMenteesDialog> {
  Map<String, bool> selectedMentees = {};
  
  @override
  void initState() {
    super.initState();
    final mentorService = Provider.of<MentorService>(context, listen: false);
    for (var mentee in mentorService.mentees) {
      String menteeName = mentee['name'];
      selectedMentees[menteeName] = !widget.isBulkAssign && 
                                    widget.resource.assignedTo.contains(menteeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context, listen: false);
    
    return AlertDialog(
      title: _buildTitle(),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isBulkAssign
                  ? 'Select mentees to assign these resources to:'
                  : 'Select mentees to assign this resource to:',
            ),
            const SizedBox(height: ResourceConstants.mediumPadding),
            ...mentorService.mentees.map((mentee) {
              String menteeName = mentee['name'];
              return CheckboxListTile(
                title: Text(menteeName),
                subtitle: Text(mentee['program']),
                value: selectedMentees[menteeName] ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    selectedMentees[menteeName] = value ?? false;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleAssign,
          child: Text(widget.isBulkAssign ? 'Assign' : 'Save Assignments'),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    if (widget.isBulkAssign) {
      return Text('Assign ${widget.resourceCount} Resources to Mentees');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Assign Resource to Mentees'),
        const SizedBox(height: 4),
        Text(
          widget.resource.title,
          style: const TextStyle(
            fontSize: ResourceConstants.bodyTextSize,
            fontWeight: FontWeight.normal,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _handleAssign() {
    List<String> assignedMentees = [];
    selectedMentees.forEach((mentee, isSelected) {
      if (isSelected) {
        assignedMentees.add(mentee);
      }
    });
    
    Navigator.pop(context);
    
    String message;
    if (widget.isBulkAssign) {
      message = 'Resources assigned to ${assignedMentees.length} mentee(s)';
    } else if (assignedMentees.isEmpty) {
      message = ResourceConstants.unassignSuccessMessage;
    } else {
      message = '${ResourceConstants.assignmentSuccessMessage} ${assignedMentees.length} mentee(s)';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}