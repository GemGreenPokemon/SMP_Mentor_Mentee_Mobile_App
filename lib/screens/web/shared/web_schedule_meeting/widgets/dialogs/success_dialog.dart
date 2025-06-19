import 'package:flutter/material.dart';
import '../../utils/date_time_helpers.dart';

class SuccessDialog extends StatelessWidget {
  final bool isMentor;
  final bool isSettingAvailability;
  final bool isCustomTimeRequest;
  final DateTime? selectedDay;
  final DateTime? selectedTime;
  final List<DateTime> selectedAvailabilitySlots;
  final Map<String, dynamic>? selectedMenteeOrMentor;
  final String title;
  final String location;
  final String repeatOption;
  final VoidCallback onDone;

  const SuccessDialog({
    super.key,
    required this.isMentor,
    required this.isSettingAvailability,
    required this.isCustomTimeRequest,
    this.selectedDay,
    this.selectedTime,
    required this.selectedAvailabilitySlots,
    this.selectedMenteeOrMentor,
    required this.title,
    required this.location,
    required this.repeatOption,
    required this.onDone,
  });
  @override
  Widget build(BuildContext context) {
    final String dialogTitle = isMentor 
      ? (isSettingAvailability ? 'Availability Set' : 'Meeting Scheduled')
      : (isCustomTimeRequest ? 'Meeting Request Sent' : 'Meeting Scheduled');
    
    final IconData dialogIcon = isMentor || !isCustomTimeRequest
      ? Icons.check_circle 
      : Icons.schedule_send;
    
    final Color dialogColor = isMentor || !isCustomTimeRequest
      ? Colors.lightBlue 
      : Colors.blue[600]!;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(dialogIcon, color: dialogColor, size: 28),
          const SizedBox(width: 8),
          Text(dialogTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMentor && isSettingAvailability) ...[
            Text(
              'Availability set for ${DateTimeHelpers.formatDate(selectedDay!)}',              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Time slots: ${selectedAvailabilitySlots.length}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedAvailabilitySlots.map((slot) => 
                Chip(
                  label: Text(
                    DateTimeHelpers.formatTime(slot),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.lightBlue.withOpacity(0.2),
                )
              ).toList(),
            ),
          ] else ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('With: ${selectedMenteeOrMentor?['name'] ?? 'Unknown'}'),            Text('Date: ${DateTimeHelpers.formatDate(selectedDay!)}'),
            Text('Time: ${DateTimeHelpers.formatTime(selectedTime!)}'),
          ],
          if (isCustomTimeRequest && !isMentor) ...[
            const SizedBox(height: 4),
            Text(
              '(Custom time - pending approval)',
              style: TextStyle(
                color: Colors.blue[600]!,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Location: $location',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (repeatOption != 'none')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Repeats: ${repeatOption.replaceAll('_', ' ')}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          if (!isMentor && isCustomTimeRequest) ...[
            const SizedBox(height: 12),
            Container(              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your mentor will be notified of this custom time request and will confirm availability.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDone();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}