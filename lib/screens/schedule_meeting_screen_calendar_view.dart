import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:smp_mentor_mentee_mobile_app/models/availability.dart';
import 'package:smp_mentor_mentee_mobile_app/models/meeting.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/local_database_service.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/test_mode_manager.dart';

class ScheduleMeetingScreenCalendarView extends StatefulWidget {
  final bool isMentor;
  
  const ScheduleMeetingScreenCalendarView({Key? key, required this.isMentor}) : super(key: key);
  
  @override
  _ScheduleMeetingScreenCalendarViewState createState() => _ScheduleMeetingScreenCalendarViewState();
}

class _ScheduleMeetingScreenCalendarViewState extends State<ScheduleMeetingScreenCalendarView> {
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  User? _currentUser;
  List<Availability> _availabilities = [];
  List<Meeting> _meetings = [];
  EventController<CalendarEventData> eventController = EventController<CalendarEventData>();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    await TestModeManager.initialize();
    _currentUser = TestModeManager.currentTestUser;
    
    if (_currentUser != null) {
      _availabilities = await _localDb.getAvailabilityByMentor(_currentUser!.id);
      _meetings = widget.isMentor 
          ? await _localDb.getMeetingsByMentor(_currentUser!.id)
          : await _localDb.getMeetingsByMentee(_currentUser!.id);
      
      _buildCalendarEvents();
    }
  }
  
  void _buildCalendarEvents() {
    // Clear existing events
    eventController.events.clear();
    
    // Add availability events
    for (final slot in _availabilities) {
      final date = DateTime.tryParse(slot.day);
      if (date != null) {
        // Parse time from slot.slotStart
        final timeParts = slot.slotStart.split(' ');
        final hourMinute = timeParts[0].split(':');
        var hour = int.parse(hourMinute[0]);
        final minute = int.parse(hourMinute[1]);
        final isPM = timeParts.length > 1 && timeParts[1] == 'PM';
        
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        
        final startTime = DateTime(date.year, date.month, date.day, hour, minute);
        final endTime = startTime.add(Duration(minutes: 30));
        
        eventController.add(
          CalendarEventData(
            date: startTime,
            endDate: endTime,
            startTime: startTime,
            endTime: endTime,
            title: slot.isBooked ? 'Booked' : 'Available',
            description: slot.isBooked ? 'Booked' : 'Available',
            color: slot.isBooked ? Colors.indigo : Colors.lightBlue,
          ),
        );
      }
    }
    
    // Add meeting events
    for (final meeting in _meetings) {
      final startTime = DateTime.tryParse(meeting.startTime);
      if (startTime != null) {
        final endTime = meeting.endTime != null ? DateTime.tryParse(meeting.endTime!) : null;
        final finalEndTime = endTime ?? startTime.add(Duration(minutes: 30));
        
        eventController.add(
          CalendarEventData(
            date: startTime,
            endDate: finalEndTime,
            startTime: startTime,
            endTime: finalEndTime,
            title: meeting.topic ?? 'Meeting',
            description: meeting.status ?? 'scheduled',
            color: meeting.status == 'pending' ? Colors.blue : Colors.indigo,
          ),
        );
      }
    }
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMentor ? 'Schedule Meeting - Mentor' : 'Schedule Meeting - Mentee'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: CalendarControllerProvider(
        controller: eventController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Legend
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Legend',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem('Available', Colors.lightBlue),
                          const SizedBox(width: 16),
                          _buildLegendItem('Pending', Colors.blue),
                          const SizedBox(width: 16),
                          _buildLegendItem('Booked', Colors.indigo),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Calendar View
              Expanded(
                child: Card(
                  child: MonthView<CalendarEventData>(
                    controller: eventController,
                    cellAspectRatio: 1,
                    onPageChange: (date, pageIndex) {
                      print("Page changed to $date");
                    },
                    onCellTap: (events, date) {
                      // Handle cell tap
                      if (events.isNotEmpty) {
                        _showDayEvents(date, events);
                      }
                    },
                    // Use custom day builder to add dots
                    cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
                      // Custom cell builder for better control
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          color: isToday ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isInMonth ? Colors.black : Colors.grey,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (events.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: events.take(3).map((event) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: event.color,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  void _showDayEvents(DateTime date, List<CalendarEventData> events) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Events on ${date.day}/${date.month}/${date.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: events.map((event) => ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(event.title),
            subtitle: Text(event.description ?? ''),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}