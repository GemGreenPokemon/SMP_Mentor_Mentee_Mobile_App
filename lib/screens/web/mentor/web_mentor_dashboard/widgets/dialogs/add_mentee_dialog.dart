import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class AddMenteeDialog extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddMentee;

  const AddMenteeDialog({
    super.key,
    required this.onAddMentee,
  });

  static void show(BuildContext context, Function(Map<String, dynamic>) onAddMentee) {
    showDialog(
      context: context,
      builder: (context) => AddMenteeDialog(onAddMentee: onAddMentee),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(DashboardStrings.availableMentees),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenteeOption(
              context,
              'Michael Brown',
              '1st Year, Computer Science',
            ),
            const Divider(),
            _buildMenteeOption(
              context,
              'Lisa Chen',
              '2nd Year, Biology',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(DashboardStrings.close),
        ),
      ],
    );
  }

  Widget _buildMenteeOption(BuildContext context, String name, String program) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(name),
      subtitle: Text(program),
      trailing: ElevatedButton(
        onPressed: () {
          onAddMentee({
            'name': name,
            'program': program,
            'lastMeeting': DashboardStrings.notMetYet,
            'progress': 0.0,
            'assignedBy': 'You',
            'goals': [],
            'upcomingMeetings': [],
            'actionItems': [],
          });
          Navigator.pop(context);
          DashboardHelpers.showSuccessSnackBar(
            context,
            'New mentee added successfully!',
          );
        },
        child: const Text(DashboardStrings.select),
      ),
    );
  }
}