import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:smp_mentor_mentee_mobile_app/models/availability.dart';
import 'package:smp_mentor_mentee_mobile_app/services/meeting/meeting_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import '../../utils/date_time_helpers.dart';

class CopyAvailabilityDialog extends StatefulWidget {
  final DateTime selectedDay;
  final List<DateTime> selectedAvailabilitySlots;
  final MeetingService meetingService;
  final AuthService authService;
  final VoidCallback onComplete;

  const CopyAvailabilityDialog({
    super.key,
    required this.selectedDay,
    required this.selectedAvailabilitySlots,
    required this.meetingService,
    required this.authService,
    required this.onComplete,
  });

  @override
  State<CopyAvailabilityDialog> createState() => _CopyAvailabilityDialogState();
}

class _CopyAvailabilityDialogState extends State<CopyAvailabilityDialog> {
  final selectedDays = <DateTime>[];
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Copy Availability to Other Days'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select days to copy your availability to:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final date = widget.selectedDay.add(Duration(days: index + 1));
                final isSelected = selectedDays.contains(date);
                return FilterChip(
                  label: Text(DateTimeHelpers.formatDate(date).split(',')[0]), // Show day name
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(date);
                      } else {
                        selectedDays.remove(date);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedDays.isNotEmpty ? () async {
            Navigator.pop(context);
            // Copy availability to selected days
            for (final date in selectedDays) {
              final slots = widget.selectedAvailabilitySlots.map((time) {
                return Availability(
                  id: _uuid.v4(),
                  mentorId: widget.authService.currentUser!.uid,
                  day: DateTimeHelpers.formatDateForDatabase(date),
                  slotStart: DateTimeHelpers.formatTime(time),
                  slotEnd: null,
                  isBooked: false,
                );
              }).toList();
              
              await widget.meetingService.createAvailability(slots);
            }
            
            // Refresh calendar
            widget.onComplete();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Availability copied to ${selectedDays.length} days'),
                backgroundColor: Colors.green,
              ),
            );
          } : null,
          child: const Text('Copy'),
        ),
      ],
    );
  }
}
