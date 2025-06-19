import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/models/availability.dart';
import '../../utils/date_time_helpers.dart';

class RemoveAvailabilityDialog extends StatelessWidget {
  final Availability slot;
  final VoidCallback onConfirm;

  const RemoveAvailabilityDialog({
    super.key,
    required this.slot,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Remove Availability'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to remove this availability slot?'),
          const SizedBox(height: 12),          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateTimeHelpers.formatDate(DateTime.parse(slot.day))}'),
                Text('Time: ${slot.slotStart}'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}