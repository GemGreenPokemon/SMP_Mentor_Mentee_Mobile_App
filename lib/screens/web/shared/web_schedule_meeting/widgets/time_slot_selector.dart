import 'package:flutter/material.dart';
import '../models/time_slot.dart';
import 'package:smp_mentor_mentee_mobile_app/models/availability.dart';
import '../utils/date_time_helpers.dart';

class TimeSlotSelector extends StatelessWidget {
  final bool isMentor;
  final bool isSettingAvailability;
  final DateTime? selectedDay;
  final DateTime? selectedTime;
  final List<DateTime> selectedAvailabilitySlots;
  final List<TimeSlot> timeSlots;
  final List<Availability> availabilitySlots;
  final bool isCustomTimeRequest;
  final Set<String> pendingOperations;
  final Function(DateTime?) onTimeSelected;
  final Function(DateTime) onAvailabilitySlotToggle;
  final Function(Availability) onRemoveAvailability;
  final VoidCallback onCustomTimePressed;
  final VoidCallback onCustomAvailabilityTimePressed;

  const TimeSlotSelector({
    super.key,
    required this.isMentor,
    required this.isSettingAvailability,
    required this.selectedDay,
    required this.selectedTime,
    required this.selectedAvailabilitySlots,
    required this.timeSlots,
    required this.availabilitySlots,    required this.isCustomTimeRequest,
    required this.pendingOperations,
    required this.onTimeSelected,
    required this.onAvailabilitySlotToggle,
    required this.onRemoveAvailability,
    required this.onCustomTimePressed,
    required this.onCustomAvailabilityTimePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedDay != null && !isSettingAvailability) ...[
          _buildAvailabilityInfo(),
          const SizedBox(height: 16),
        ],
        if (isMentor && isSettingAvailability && selectedAvailabilitySlots.isNotEmpty) ...[
          _buildSelectedSlotsDisplay(),
        ],
        if (isMentor && !isSettingAvailability && selectedDay != null && timeSlots.isEmpty) ...[          _buildNoSlotsWarning(),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (isMentor && isSettingAvailability) ...[
              // Custom time button
              ActionChip(
                avatar: const Icon(Icons.add_alarm, size: 18),
                label: const Text('Add Custom Time'),
                backgroundColor: Colors.purple.withOpacity(0.1),
                onPressed: onCustomAvailabilityTimePressed,
              ),
              const SizedBox(width: 16),
              // Multiple selection for availability
              ..._buildAvailabilityChips(),
            ] else ...[
              // Single selection for scheduling
              ..._buildSchedulingChips(),
            ],
            if (!isMentor) ...[
              const SizedBox(width: 16),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Request Custom Time'),
                backgroundColor: isCustomTimeRequest ? 
                  Colors.purple.withOpacity(0.2) : null,
                onPressed: onCustomTimePressed,
              ),
            ],          ],
        ),
        if (isCustomTimeRequest && selectedTime != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Custom time request: ${DateTimeHelpers.formatTime(selectedTime!)}',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilityInfo() {
    return Container(      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                isMentor ? 'Your Availability' : 'Mentor Availability',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isMentor 
              ? 'Only times you have set as available are shown below. Select one to schedule a meeting with your mentee.'
              : 'Light blue slots show when your mentor is available. You can also request a custom time if needed.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(            children: [
              _buildLegend('Available', Colors.lightBlue),
              const SizedBox(width: 16),
              _buildLegend('Pending', Colors.blue[600]!),
              const SizedBox(width: 16),
              _buildLegend('Booked', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSlotsDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Time Slots:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedAvailabilitySlots.map((slot) {
              final timeStr = DateTimeHelpers.formatTime(slot);
              final isCustom = !DateTimeHelpers.generateTimeSlots().any((t) => 
                t.hour == slot.hour && t.minute == slot.minute
              );
              return Chip(
                label: Text(timeStr),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: isCustom 
                  ? Colors.purple.withOpacity(0.1) 
                  : Colors.lightBlue.withOpacity(0.2),
                onDeleted: () => onAvailabilitySlotToggle(slot),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No available time slots for this day. Please set your availability first or select a different day.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAvailabilityChips() {
    return DateTimeHelpers.generateTimeSlots().map((time) {
      final timeStr = DateTimeHelpers.formatTime(time);
      final isSelected = selectedAvailabilitySlots.any(
        (slot) => slot.hour == time.hour && slot.minute == time.minute
      );
      
      // Check if this slot is already saved in the database
      final existingSlot = availabilitySlots.firstWhere(
        (slot) => slot.day == DateTimeHelpers.formatDateForDatabase(selectedDay!) && 
                  slot.slotStart == timeStr,
        orElse: () => Availability(
          id: '', mentorId: '', day: '', slotStart: '', isBooked: false        ),
      );
      final isAlreadySaved = existingSlot.id.isNotEmpty;
      
      return Stack(
        children: [
          FilterChip(
            label: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      timeStr,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pendingOperations.contains(existingSlot.id)) ...[
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ] else if (isAlreadySaved) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.check_circle, size: 14, 
                         color: existingSlot.isBooked ? Colors.red : Colors.green),
                  ],
                ],              ),
            ),
            showCheckmark: false,
            selected: isSelected || isAlreadySaved,
            selectedColor: isAlreadySaved 
                ? (existingSlot.isBooked ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3))
                : Colors.lightBlue,
            backgroundColor: isAlreadySaved 
                ? (existingSlot.isBooked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                : null,
            tooltip: isAlreadySaved 
                ? (existingSlot.isBooked ? 'Already booked' : 'Click to remove availability')
                : null,
            onSelected: existingSlot.isBooked || pendingOperations.contains(existingSlot.id) ? null : (selected) {
              if (isAlreadySaved && !existingSlot.isBooked) {
                // Show confirmation dialog for removing availability
                onRemoveAvailability(existingSlot);
              } else {
                if (selected && !isAlreadySaved) {
                  onAvailabilitySlotToggle(time);
                } else if (!selected && !isAlreadySaved) {
                  onAvailabilitySlotToggle(time);
                }
              }
            },
          ),
          if (isAlreadySaved && !existingSlot.isBooked)
            Positioned(
              top: -4,
              right: -4,              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: InkWell(
                  onTap: () => onRemoveAvailability(existingSlot),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSchedulingChips() {
    return timeSlots.map((slot) {
      final isSelected = selectedTime != null && 
                       DateTimeHelpers.formatTime(selectedTime!) == slot.time &&
                       !isCustomTimeRequest;
      final color = DateTimeHelpers.getSlotColor(slot.status);
      final textColor = DateTimeHelpers.getSlotTextColor(slot.status);
      final isAvailable = slot.status == 'Available';
      
      return Stack(        children: [
          ChoiceChip(
            label: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      slot.time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (slot.status == 'Pending' || slot.status == 'Pending Request') ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.hourglass_empty,
                      size: 14,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ],
                  if (slot.status == 'Booked') ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ],                ],
              ),
            ),
            selected: isSelected,
            selectedColor: color,
            backgroundColor: color.withOpacity(0.2),
            onSelected: isAvailable || isMentor ? (selected) {
              onTimeSelected(selected ? DateTimeHelpers.parseTime(slot.time, selectedDay) : null);
            } : null,
          ),
          // Notification badge for pending requests (mentor view)
          if (isMentor && slot.status == 'Pending Request')
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
    }).toList();
  }

  Widget _buildLegend(String label, Color color) {
    return Row(      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}