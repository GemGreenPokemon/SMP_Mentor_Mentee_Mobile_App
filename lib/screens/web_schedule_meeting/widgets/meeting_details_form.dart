import 'package:flutter/material.dart';
import '../utils/date_time_helpers.dart';
import '../../../models/availability.dart';

class MeetingDetailsForm extends StatelessWidget {
  final bool isMentor;
  final bool isSettingAvailability;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final Map<String, dynamic>? selectedMenteeOrMentor;
  final List<Map<String, dynamic>> menteesList;
  final List<Map<String, dynamic>> mentorsList;
  final String meetingType;
  final String repeatOption;
  final DateTime? selectedDay;
  final DateTime? selectedTime;
  final List<Availability> availabilitySlots;
  final int selectedSlotsCount;
  final bool isSavingData;
  final Function(Map<String, dynamic>?) onMenteeOrMentorChanged;
  final Function(String) onMeetingTypeChanged;
  final Function(String) onRepeatOptionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onCopyToOtherDays;
  final VoidCallback onClear;
  final VoidCallback onSchedule;

  const MeetingDetailsForm({
    super.key,
    required this.isMentor,
    required this.isSettingAvailability,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.selectedMenteeOrMentor,
    required this.menteesList,
    required this.mentorsList,
    required this.meetingType,
    required this.repeatOption,
    required this.selectedDay,
    required this.selectedTime,
    required this.availabilitySlots,
    required this.selectedSlotsCount,
    required this.isSavingData,
    required this.onMenteeOrMentorChanged,
    required this.onMeetingTypeChanged,
    required this.onRepeatOptionChanged,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onCopyToOtherDays,
    required this.onClear,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMentor && isSettingAvailability 
                ? 'Availability Details'
                : 'Meeting Details',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Show different fields based on mode
            if (isMentor && isSettingAvailability) ...[
              _buildAvailabilitySection(),
            ] else ...[
              _buildMeetingSection(),
            ],
            
            // Repeat options
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: repeatOption,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'biweekly', child: Text('Every 2 weeks')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) => onRepeatOptionChanged(value!),
            ),
            const SizedBox(height: 24),
            
            // Selected date and time summary
            if (selectedDay != null && selectedTime != null)
              _buildScheduleSummary(),
            
            const SizedBox(height: 32),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      children: [
        // Show existing availability summary
        if (selectedDay != null && availabilitySlots.any((s) => s.day == DateTimeHelpers.formatDateForDatabase(selectedDay!))) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Current Availability',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${availabilitySlots.where((s) => s.day == DateTimeHelpers.formatDateForDatabase(selectedDay!)).length} time slots set for this day',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
        // Batch operations for availability
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.select_all, size: 16),
              label: const Text('Select All'),
              onPressed: onSelectAll,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear All'),
              onPressed: onClearAll,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy to Other Days'),
              onPressed: selectedSlotsCount > 0 ? onCopyToOtherDays : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // For setting availability
        Container(
          padding: const EdgeInsets.all(16),
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
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Set your available time slots for mentees to book meetings',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Selected slots: $selectedSlotsCount time slots',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMeetingSection() {
    return Column(
      children: [
        // For scheduling meetings
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Meeting Title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),
        
        // Select mentee/mentor
        DropdownButtonFormField<Map<String, dynamic>>(
          value: selectedMenteeOrMentor,
          decoration: InputDecoration(
            labelText: isMentor ? 'Select Mentee' : 'Select Mentor',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person),
          ),
          isExpanded: true,
          items: isMentor 
            ? menteesList.map((mentee) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: mentee,
                  child: Text(
                    mentee['display'],
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList()
            : mentorsList.isEmpty 
              ? [] 
              : mentorsList.map((mentor) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: mentor,
                    child: Text(
                      mentor['display'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          onChanged: onMenteeOrMentorChanged,
          validator: (value) {
            if (value == null) {
              return isMentor ? 'Please select a mentee' : 'Please select a mentor';
            }
            return null;
          },
        ),
        // Show selected mentee/mentor details
        if (selectedMenteeOrMentor != null && selectedMenteeOrMentor!['program'].isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedMenteeOrMentor!['program'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        
        // Meeting type
        const Text(
          'Meeting Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('In-Person'),
                value: 'in-person',
                groupValue: meetingType,
                onChanged: (value) => onMeetingTypeChanged(value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Virtual'),
                value: 'virtual',
                groupValue: meetingType,
                onChanged: (value) => onMeetingTypeChanged(value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Location
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: meetingType == 'in-person' ? 'Location' : 'Meeting Link',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              meetingType == 'in-person' ? Icons.location_on : Icons.link,
            ),
            hintText: meetingType == 'in-person' 
              ? 'e.g., Library Room 201' 
              : 'e.g., Zoom link',
          ),
        ),
        const SizedBox(height: 16),
        
        // Description
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScheduleSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled for:',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${DateTimeHelpers.formatDate(selectedDay!)} at ${DateTimeHelpers.formatTime(selectedTime!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isSavingData ? null : onSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isSavingData 
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              : Text(_getButtonText()),
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    if (isMentor) {
      return isSettingAvailability ? 'Set Availability' : 'Schedule Meeting';
    } else {
      return 'Request Meeting';
    }
  }
}
