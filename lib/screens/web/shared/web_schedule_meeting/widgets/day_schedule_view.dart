import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../models/time_slot.dart';
import 'package:smp_mentor_mentee_mobile_app/models/meeting.dart';
import 'package:smp_mentor_mentee_mobile_app/models/availability.dart';
import '../utils/date_time_helpers.dart';

class DayScheduleView extends StatelessWidget {
  final DateTime? selectedDay;
  final Map<DateTime, List<CalendarEvent>> calendarEvents;
  final List<Meeting> meetings;
  final List<Map<String, dynamic>> menteesList;
  final bool isMentor;
  final bool isSettingAvailability;
  final List<Availability> availabilitySlots;
  final Function(DateTime?) onTimeSelected;
  final Function(Availability) onRemoveAvailability;

  const DayScheduleView({
    super.key,
    required this.selectedDay,
    required this.calendarEvents,
    required this.meetings,
    required this.menteesList,
    required this.isMentor,
    required this.isSettingAvailability,
    required this.availabilitySlots,
    required this.onTimeSelected,
    required this.onRemoveAvailability,
  });
  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule for ${DateTimeHelpers.formatDate(selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),                Text(
                  '${calendarEvents[DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day)]?.length ?? 0} events',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDaySchedule(),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule() {
    final normalizedDay = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day);
    final events = calendarEvents[normalizedDay] ?? [];
    
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No events scheduled',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (isMentor && !isSettingAvailability) ...[
                const SizedBox(height: 8),
                Text(
                  'Set your availability to allow mentees to book meetings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    // Group events by type
    final meetingEvents = events.where((e) => e.type == 'meeting').toList();
    final availableSlots = events.where((e) => e.type == 'available' || e.type == 'booked').toList();
    
    // Sort by time
    meetingEvents.sort((a, b) => DateTimeHelpers.parseTime(a.time, selectedDay).compareTo(DateTimeHelpers.parseTime(b.time, selectedDay)));
    availableSlots.sort((a, b) => DateTimeHelpers.parseTime(a.time, selectedDay).compareTo(DateTimeHelpers.parseTime(b.time, selectedDay)));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meetings section
        if (meetingEvents.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Scheduled Meetings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],          ),
          const SizedBox(height: 12),
          ...meetingEvents.map((event) => _buildEventCard(event, true)),
          const SizedBox(height: 24),
        ],
        
        // Availability slots section
        if (availableSlots.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Availability Slots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...availableSlots.map((event) => _buildEventCard(event, false)),
        ],
      ],    );
  }
  
  Widget _buildEventCard(CalendarEvent event, bool isMeeting) {
    Color cardColor;
    IconData icon;
    String subtitle = '';
    
    if (isMeeting) {
      cardColor = Colors.indigo;
      icon = Icons.videocam;
      // Find the actual meeting details
      final meetingTime = DateTimeHelpers.parseTime(event.time, selectedDay);
      final meeting = meetings.firstWhere(
        (m) {
          final mTime = DateTime.tryParse(m.startTime);
          return mTime != null && 
                 mTime.hour == meetingTime.hour && 
                 mTime.minute == meetingTime.minute;
        },
        orElse: () => Meeting(
          id: '',
          mentorId: '',
          menteeId: '',
          startTime: '',
          topic: 'Meeting',
          status: event.status.toLowerCase(),
        ),
      );
      
      if (meeting.topic != null) {        subtitle = meeting.topic!;
      }
      
      // Add mentee name if available
      if (isMentor && meeting.menteeId.isNotEmpty) {
        final mentee = menteesList.firstWhere(
          (m) => m['id'] == meeting.menteeId || m['firebase_uid'] == meeting.menteeId,
          orElse: () => {'name': meeting.menteeId},
        );
        subtitle += '\nWith: ${mentee['name']}';
      }
    } else {
      switch (event.status) {
        case 'Available':
          cardColor = Colors.lightBlue;
          icon = Icons.access_time;
          subtitle = 'Open for booking';
          break;
        case 'Booked':
          cardColor = Colors.indigo;
          icon = Icons.lock;
          subtitle = 'Time slot booked';
          break;
        case 'Pending':
          cardColor = Colors.blue[600]!;
          icon = Icons.hourglass_empty;
          subtitle = 'Pending approval';
          break;
        default:
          cardColor = Colors.grey;
          icon = Icons.event;      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle tap - could show meeting details or allow editing
            if (!isMeeting && event.status == 'Available' && !isMentor) {
              // Mentee can select this time
              onTimeSelected(DateTimeHelpers.parseTime(event.time, selectedDay));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.time,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cardColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cardColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMeeting && event.status == 'Available' && isMentor) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Remove this slot',                    onPressed: () {
                      onRemoveAvailability(
                        availabilitySlots.firstWhere(
                          (slot) => slot.slotStart == event.time && slot.day == DateTimeHelpers.formatDateForDatabase(selectedDay!),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}