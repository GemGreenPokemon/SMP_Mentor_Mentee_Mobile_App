import 'package:flutter/material.dart';
import '../models/checklist_filter.dart';
import '../utils/checklist_constants.dart';

class MenteeSelector extends StatelessWidget {
  final ChecklistFilter filter;
  final List<Map<String, String>> mentees;
  final ValueChanged<ChecklistFilter> onFilterChanged;

  const MenteeSelector({
    super.key,
    required this.filter,
    required this.mentees,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: ChecklistConstants.menteeDropdownWidth,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Mentee',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                value: filter.menteeId ?? 'all',
                items: mentees.map((mentee) {
                  return DropdownMenuItem<String>(
                    value: mentee['id']!,
                    child: Text(mentee['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  final selectedMentee = mentees.firstWhere(
                    (m) => m['id'] == value,
                    orElse: () => {'id': 'all', 'name': 'All Mentees'},
                  );
                  
                  onFilterChanged(
                    filter.copyWith(
                      menteeId: value == 'all' ? null : value,
                      menteeName: selectedMentee['name'],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            if (filter.menteeId != null && filter.menteeId != 'all')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Viewing checklists for ${filter.menteeName}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}