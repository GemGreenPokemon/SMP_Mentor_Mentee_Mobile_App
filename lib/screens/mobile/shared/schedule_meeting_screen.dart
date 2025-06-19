import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../utils/test_mode_manager.dart';
import '../../../services/local_database_service.dart';
import '../../../models/availability.dart';
import '../../../models/meeting.dart';
import '../../../models/user.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  final bool isMentor;
  const ScheduleMeetingScreen({super.key, required this.isMentor});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  String? selectedAvailabilityId;
  String selectedLocation = 'KL 109';
  bool isRecurring = false;
  int recurringWeeks = 4;
  
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  User? _currentUser;
  User? _otherUser; // Mentor for mentees, or selected mentee for mentors
  List<Availability> _availabilities = [];
  List<Meeting> _allMeetings = []; // All meeting requests (pending, accepted, rejected)
  Map<String, User> _menteeMap = {}; // Map of mentee IDs to User objects
  bool _isLoading = true;
  
  // Calendar events for visual indicators
  Map<DateTime, List<CalendarEvent>> _calendarEvents = {};

  // Mock data for mentor's available time slots and status
  final Map<String, List<MentorTimeSlot>> mentorAvailability = {
    '2024-02-14': [
      MentorTimeSlot('2:00 PM', 'Available'),
      MentorTimeSlot('3:00 PM', 'Pending Request'),
      MentorTimeSlot('4:00 PM', 'Booked'),
    ],
    '2024-02-15': [
      MentorTimeSlot('9:00 AM', 'Available'),
      MentorTimeSlot('10:00 AM', 'Available'),
      MentorTimeSlot('2:00 PM', 'Booked'),
    ],
    '2024-02-16': [
      MentorTimeSlot('11:00 AM', 'Available'),
      MentorTimeSlot('2:00 PM', 'Available'),
      MentorTimeSlot('3:00 PM', 'Pending Request'),
    ],
    '2024-02-17': [
      MentorTimeSlot('10:00 AM', 'Available'),
      MentorTimeSlot('11:00 AM', 'Available'),
      MentorTimeSlot('2:00 PM', 'Available'),
      MentorTimeSlot('3:00 PM', 'Available'),
    ],
    '2024-02-18': [
      MentorTimeSlot('1:00 PM', 'Available'),
      MentorTimeSlot('2:00 PM', 'Available'),
      MentorTimeSlot('3:00 PM', 'Available'),
      MentorTimeSlot('4:00 PM', 'Available'),
    ],
    '2024-02-20': [
      MentorTimeSlot('9:00 AM', 'Available'),
      MentorTimeSlot('10:00 AM', 'Available'),
      MentorTimeSlot('2:00 PM', 'Available'),
      MentorTimeSlot('3:00 PM', 'Pending Request'),
      MentorTimeSlot('4:00 PM', 'Available'),
    ],
  };

  // Mock data for available locations
  final List<String> availableLocations = [
    'KL 109',
    'KL 110',
    'KL 202',
    'COB 267',
    'Library Study Room',
  ];

  // For adding custom location input
  TextEditingController _customLocationController = TextEditingController();
  bool _addingLocation = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: ScheduleMeetingScreen initState called - isMentor: ${widget.isMentor}');
    _loadData();
  }

  Future<void> _loadData() async {
    print('DEBUG: _loadData called, TestMode: ${TestModeManager.isTestMode}');
    if (TestModeManager.isTestMode) {
      try {
        // Get current user from test mode based on role
        _currentUser = widget.isMentor 
            ? TestModeManager.currentTestMentor 
            : TestModeManager.currentTestMentee;
        print('DEBUG: Current user (${widget.isMentor ? 'Mentor' : 'Mentee'}): ${_currentUser?.name} (${_currentUser?.id})');
        
        if (_currentUser != null) {
          if (widget.isMentor) {
            // Mentor viewing their own availability (both available and booked)
            _availabilities = await _localDb.getAvailabilityByMentor(_currentUser!.id);
            print('DEBUG: Loaded ${_availabilities.length} availability slots for mentor ${_currentUser!.id}');
            
            // Log each availability slot's details
            for (final avail in _availabilities) {
              print('DEBUG: Availability - id: ${avail.id}, day: ${avail.day}, slotStart: ${avail.slotStart}, isBooked: ${avail.isBooked}, menteeId: ${avail.menteeId}');
            }
            
            // Load all meeting requests (pending, accepted, rejected)
            _allMeetings = await _localDb.getMeetingsByMentor(_currentUser!.id);
            print('DEBUG: Loaded ${_allMeetings.length} meetings for mentor ${_currentUser!.id}');
            
            // Log each meeting's details
            for (final meeting in _allMeetings) {
              print('DEBUG: Meeting - id: ${meeting.id}, availabilityId: ${meeting.availabilityId}, status: ${meeting.status}, topic: ${meeting.topic}, location: ${meeting.location}');
            }
            
            // Load mentee information for all meetings
            for (final meeting in _allMeetings) {
              final mentee = await _localDb.getUserById(meeting.menteeId);
              if (mentee != null) {
                _menteeMap[meeting.menteeId] = mentee;
                print('DEBUG: Loaded mentee: ${mentee.name} for meeting ${meeting.id}');
              }
            }
            
            // Also load mentees who have booked availability slots
            for (final slot in _availabilities) {
              if (slot.isBooked && slot.menteeId != null && !_menteeMap.containsKey(slot.menteeId)) {
                final mentee = await _localDb.getUserById(slot.menteeId!);
                if (mentee != null) {
                  _menteeMap[slot.menteeId!] = mentee;
                  print('DEBUG: Loaded mentee: ${mentee.name} for availability slot ${slot.id}');
                }
              }
            }
          } else {
            // Mentee viewing mentor's availability
            // Find the mentor for this mentee
            final mentorships = await _localDb.getMentorshipsByMentee(_currentUser!.id);
            if (mentorships.isNotEmpty) {
              final mentorId = mentorships.first.mentorId;
              _otherUser = await _localDb.getUser(mentorId);
              if (_otherUser != null) {
                // Get ALL slots (available and booked) to show mentee's own bookings
                _availabilities = await _localDb.getAvailabilityByMentor(mentorId);
                print('DEBUG: Loaded ${_availabilities.length} total slots for mentor ${mentorId}');
                
                // Load mentee's own meetings to show status
                _allMeetings = await _localDb.getMeetingsByMentee(_currentUser!.id);
                print('DEBUG: Loaded ${_allMeetings.length} meetings for mentee ${_currentUser!.id}');
                
                // Log each meeting's details
                for (final meeting in _allMeetings) {
                  print('DEBUG: Mentee Meeting - id: ${meeting.id}, status: ${meeting.status}, topic: ${meeting.topic}, startTime: ${meeting.startTime}');
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading availability data: $e');
      }
    }
    
    setState(() {
      _isLoading = false;
    });
    
    // Build calendar events for visual indicators
    _buildCalendarEvents();
  }

  List<MentorTimeSlot> getAvailableTimeSlots() {
    final dateKey = selectedDate.toString().split(' ')[0];
    
    // If in test mode and we have loaded availability data
    if (TestModeManager.isTestMode && _availabilities.isNotEmpty) {
      // Filter availabilities for the selected date
      final slotsForDate = _availabilities.where((avail) => avail.day == dateKey).toList();
      
      return slotsForDate.map((avail) {
        String status = 'Available';
        String? menteeName;
        Meeting? meetingForSlot;
        
        // Check if there's a meeting for this slot
        final meeting = _allMeetings.firstWhere(
          (m) => m.availabilityId == avail.id,
          orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
        );
        
        if (meeting.id.isNotEmpty) {
          meetingForSlot = meeting;
          // Skip cancelled meetings - treat slot as available
          if (meeting.status == 'cancelled') {
            status = 'Available';
          } else {
            // For mentee view, show their own meeting status
            if (!widget.isMentor && meeting.menteeId == _currentUser?.id) {
              if (meeting.status == 'pending') {
                status = 'Your Request (Pending)';
              } else if (meeting.status == 'accepted') {
                status = 'Your Meeting (Confirmed)';
              } else if (meeting.status == 'rejected') {
                status = 'Your Request (Rejected)';
              }
            } else {
              // For mentor view or other mentees' bookings
              if (meeting.status == 'pending') {
                status = 'Pending Request';
              } else if (meeting.status == 'accepted') {
                status = 'Booked';
              } else {
                status = 'Booked';
              }
              menteeName = widget.isMentor ? _menteeMap[meeting.menteeId]?.name : null;
            }
          }
        } else if (avail.isBooked) {
          // Slot is booked but not by current mentee
          status = widget.isMentor ? 'Booked' : 'Unavailable';
          if (avail.menteeId != null && widget.isMentor) {
            menteeName = _menteeMap[avail.menteeId]?.name;
          }
        }
        
        return MentorTimeSlot(
          avail.slotStart, 
          status,
          availabilityId: avail.id,
          menteeName: menteeName,
          meeting: meetingForSlot,
        );
      }).toList();
    }
    
    // Fallback to hardcoded data if not in test mode
    if (widget.isMentor) {
      mentorAvailability.putIfAbsent(dateKey, () => [
        MentorTimeSlot('9:00 AM', 'Available'),
        MentorTimeSlot('10:00 AM', 'Available'),
        MentorTimeSlot('11:00 AM', 'Available'),
        MentorTimeSlot('2:00 PM', 'Available'),
        MentorTimeSlot('3:00 PM', 'Available'),
        MentorTimeSlot('4:00 PM', 'Available'),
      ]);
    }
    return mentorAvailability[dateKey] ?? [];
  }

  Color getTimeSlotColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green.withOpacity(0.1);
      case 'Pending Request':
        return Colors.blue[600]!.withOpacity(0.1);
      case 'Booked':
        return Colors.red.withOpacity(0.1);
      case 'Your Request (Pending)':
        return Colors.blue[600]!.withOpacity(0.1);
      case 'Your Meeting (Confirmed)':
        return Colors.green.withOpacity(0.2);
      case 'Your Request (Rejected)':
        return Colors.red.withOpacity(0.1);
      case 'Unavailable':
        return Colors.grey.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color getTimeSlotTextColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Pending Request':
        return Colors.blue[600]!;
      case 'Booked':
        return Colors.red;
      case 'Your Request (Pending)':
        return Colors.blue[600]!;
      case 'Your Meeting (Confirmed)':
        return Colors.green[700]!;
      case 'Your Request (Rejected)':
        return Colors.red[700]!;
      case 'Unavailable':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMentor ? 'Set Availability' : 'Request Meeting'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
          if (widget.isMentor && TestModeManager.isTestMode)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Set your available time slots. Green slots are open for meetings. Red slots indicate times with scheduled meetings.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildLegendItem('Open', Colors.lightBlue),
                        const SizedBox(width: 16),
                        _buildLegendItem('Pending', Colors.blue[600]!),
                        const SizedBox(width: 16),
                        _buildLegendItem('Confirmed', Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (!widget.isMentor)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            TestModeManager.isTestMode && _otherUser != null
                              ? 'Your mentor (${_otherUser!.name}) will need to approve your meeting request.'
                              : 'Your mentor (Sarah Martinez) will need to approve your meeting request.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildLegendItem('Available', Colors.lightBlue),
                        _buildLegendItem('Your Pending', Colors.blue[600]!),
                        _buildLegendItem('Your Confirmed', Colors.green),
                        _buildLegendItem('Unavailable', Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Calendar Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TableCalendar<CalendarEvent>(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: selectedDate,
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (day) {
                      final key = DateTime(day.year, day.month, day.day);
                      return _calendarEvents[key] ?? [];
                    },
                    selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(selectedDate, selectedDay)) {
                        setState(() {
                          selectedDate = selectedDay;
                          selectedTime = null;
                        });
                      }
                      final key = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                      final events = _calendarEvents[key] ?? [];
                      if (events.isNotEmpty) _showDaySchedulePopup(selectedDay, events);
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0x802196F3),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markersAlignment: Alignment.bottomCenter,
                    ),
                    calendarBuilders: CalendarBuilders<CalendarEvent>(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;

                        // BLUE THEME: Different shades of blue
                        List<Widget> dots = [];
                        
                        for (int i = 0; i < events.length && i < 3; i++) {
                          final event = events[i];
                          Color? dotColor;
                          
                          if (event.status == 'Available') {
                            dotColor = Colors.lightBlue; // Light blue for available
                          } else if (event.status == 'Pending' || event.status == 'Pending Request' || event.status == 'Your Request (Pending)') {
                            dotColor = Colors.blue[600]; // Blue for pending
                          } else if (event.status == 'Booked' || event.status == 'Your Meeting (Confirmed)') {
                            dotColor = event.status.contains('Your') ? Colors.green : Colors.indigo; // Green for own confirmed, indigo for others
                          } else if (event.status == 'Your Request (Rejected)') {
                            dotColor = Colors.red; // Red for rejected
                          } else if (event.status == 'Unavailable') {
                            dotColor = Colors.grey; // Grey for unavailable
                          }
                          
                          if (dotColor != null) {
                            if (dots.isNotEmpty) {
                              dots.add(SizedBox(width: 2));
                            }
                            
                            // Use EXACT same Container structure as legend
                            dots.add(
                              Container(
                                width: 6, // Smaller than legend (12) but same structure
                                height: 6,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }
                        }
                        
                        if (dots.isEmpty) return null;
                        
                        return Positioned(
                          bottom: 1,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dots,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recurring Meeting Options (Only for Mentors)
          if (widget.isMentor) 
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurring Meeting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Make this a weekly recurring meeting'),
                      value: isRecurring,
                      onChanged: (value) {
                        setState(() {
                          isRecurring = value;
                        });
                      },
                    ),
                    if (isRecurring) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Number of weeks: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: recurringWeeks,
                            items: [4, 8, 12, 16].map((weeks) {
                              return DropdownMenuItem(
                                value: weeks,
                                child: Text('$weeks weeks'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  recurringWeeks = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          
          // Pending Requests Card (Only for Mentors)
          if (widget.isMentor && _allMeetings.where((m) => m.status == 'pending').isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Meeting Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_allMeetings.where((m) => m.status == 'pending').length > 3)
                          TextButton(
                            onPressed: () => _showAllPendingRequestsDialog(),
                            child: Text(
                              'View More (${_allMeetings.where((m) => m.status == 'pending').length - 3})',
                              style: TextStyle(
                                color: Colors.blue[600]!,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._allMeetings.where((m) => m.status == 'pending').take(3).map((meeting) {
                      final mentee = _menteeMap[meeting.menteeId];
                      final startTime = DateTime.tryParse(meeting.startTime);
                      return Card(
                        color: Colors.blue[100],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[600]!,
                            child: Text(
                              mentee?.name.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(mentee?.name ?? 'Unknown Mentee'),
                          subtitle: Text(
                            '${startTime != null ? _formatDate(startTime) : 'Unknown date'} at ${meeting.location ?? 'TBD'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _handleMeetingRequest(meeting, true),
                                tooltip: 'Approve',
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _handleMeetingRequest(meeting, false),
                                tooltip: 'Reject',
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          
          // Upcoming Accepted Meetings Card (Only for Mentors)
          if (widget.isMentor && _allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Upcoming Confirmed Meetings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).take(3).map((meeting) {
                      final mentee = _menteeMap[meeting.menteeId];
                      final startTime = DateTime.tryParse(meeting.startTime);
                      return Card(
                        color: Colors.green[50],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              mentee?.name.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(mentee?.name ?? 'Unknown Mentee'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${startTime != null ? _formatDate(startTime) : 'Unknown date'} at ${_formatMeetingTime(meeting)}',
                              ),
                              if (meeting.location != null)
                                Text(
                                  'Location: ${meeting.location}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () => _showCancelMeetingDialog(meeting),
                            tooltip: 'Cancel Meeting',
                          ),
                        ),
                      );
                    }).toList(),
                    if (_allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).length > 3) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => _showAllUpcomingMeetingsDialog(),
                          child: Text(
                            'View All (${_allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).length})',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          
          // Upcoming Confirmed Meetings Card (For Mentees)
          if (!widget.isMentor && _allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Upcoming Meetings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).take(3).map((meeting) {
                      final startTime = DateTime.tryParse(meeting.startTime);
                      return Card(
                        color: Colors.green[50],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            meeting.topic ?? 'Meeting with Mentor',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${startTime != null ? _formatDate(startTime) : 'Unknown date'} at ${_formatMeetingTime(meeting)}',
                              ),
                              if (meeting.location != null)
                                Text(
                                  'Location: ${meeting.location}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (_otherUser != null)
                                Text(
                                  'With: ${_otherUser!.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () => _showCancelMeetingDialog(meeting),
                            tooltip: 'Cancel Meeting',
                          ),
                        ),
                      );
                    }).toList(),
                    if (_allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).length > 3) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => _showAllUpcomingMeetingsDialogMentee(),
                          child: Text(
                            'View All (${_allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).length})',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Time Slots Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isMentor ? 'Set Available Times' : 'Select Time',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!widget.isMentor && getAvailableTimeSlots().isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Your mentor has no available time slots for this date.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: getAvailableTimeSlots().map((slot) {
                      final isSelected = slot.time == selectedTime;
                      final isAvailable = slot.status == 'Available';
                      return FilterChip(
                        selected: isSelected,
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(slot.time),
                                if (!widget.isMentor) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: getTimeSlotTextColor(slot.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ] else if (slot.status != 'Available') ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    slot.status == 'Pending Request' ? Icons.hourglass_empty : Icons.check_circle,
                                    size: 16,
                                    color: getTimeSlotTextColor(slot.status),
                                  ),
                                ],
                              ],
                            ),
                            if (widget.isMentor && slot.menteeName != null) ...[
                              Text(
                                slot.menteeName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ] else if (!widget.isMentor && slot.status.startsWith('Your')) ...[
                              Text(
                                slot.status.contains('Pending') ? 'Pending' : 
                                slot.status.contains('Confirmed') ? 'Confirmed' : 'Rejected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: getTimeSlotTextColor(slot.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        backgroundColor: getTimeSlotColor(slot.status),
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        onSelected: widget.isMentor || isAvailable ? (selected) {
                          setState(() {
                            selectedTime = selected ? slot.time : null;
                            selectedAvailabilityId = selected ? slot.availabilityId : null;
                          });
                        } : null,
                        disabledColor: getTimeSlotColor(slot.status),
                      );
                    }).toList(),
                  ),
                  if (!widget.isMentor) ...[
                    ElevatedButton.icon(
                      onPressed: _addCustomTime,
                      icon: const Icon(Icons.add),
                      label: const Text('Propose Custom Time'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.isMentor) ...[
                    ElevatedButton.icon(
                      onPressed: _addCustomTime,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Time'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: availableLocations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLocation = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_addingLocation) ...[
                    TextField(
                      controller: _customLocationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Custom Location',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _addingLocation = !_addingLocation),
                        child: Text(_addingLocation ? 'Cancel' : 'Add Location'),
                      ),
                      if (_addingLocation) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCustomLocation,
                          child: const Text('Save Location'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedTime == null
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(widget.isMentor 
                                ? 'Confirm Availability' 
                                : 'Confirm Meeting Request'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.isMentor && isRecurring) ...[
                                    const Text(
                                      'This will set up weekly recurring meetings for:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...getRecurringDates().map((date) => 
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('• ${date.toString().split(' ')[0]}'),
                                      ),
                                    ),
                                    const Divider(),
                                  ] else ...[
                                    Text('Date: ${selectedDate.toString().split(' ')[0]}'),
                                  ],
                                  const SizedBox(height: 8),
                                  Text('Time: $selectedTime'),
                                  const SizedBox(height: 8),
                                  Text('Location: $selectedLocation'),
                                  if (!widget.isMentor) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Your request will be sent to your mentor for approval.',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (TestModeManager.isTestMode) {
                                      try {
                                        if (widget.isMentor) {
                                          // Mentor setting availability
                                          if (isRecurring) {
                                            // Create availability for multiple weeks
                                            for (final date in getRecurringDates()) {
                                              final availability = Availability(
                                                id: _localDb.generateId(),
                                                mentorId: _currentUser!.id,
                                                day: date.toString().split(' ')[0],
                                                slotStart: selectedTime!,
                                                isBooked: false,
                                                updatedAt: DateTime.now(),
                                              );
                                              await _localDb.createAvailability(availability);
                                            }
                                          } else {
                                            // Create single availability
                                            final availability = Availability(
                                              id: _localDb.generateId(),
                                              mentorId: _currentUser!.id,
                                              day: selectedDate.toString().split(' ')[0],
                                              slotStart: selectedTime!,
                                              isBooked: false,
                                              updatedAt: DateTime.now(),
                                            );
                                            await _localDb.createAvailability(availability);
                                          }
                                        } else {
                                          // Mentee requesting meeting
                                          if (selectedAvailabilityId != null && _otherUser != null) {
                                            // Create meeting
                                            final meeting = Meeting(
                                              id: _localDb.generateId(),
                                              mentorId: _otherUser!.id,
                                              menteeId: _currentUser!.id,
                                              startTime: '${selectedDate.toString().split(' ')[0]} $selectedTime',
                                              endTime: '', // Will be set later
                                              topic: 'Regular Meeting',
                                              location: selectedLocation,
                                              status: 'pending',
                                              availabilityId: selectedAvailabilityId,
                                              createdAt: DateTime.now(),
                                            );
                                            await _localDb.createMeeting(meeting);
                                            
                                            // Book the availability slot
                                            await _localDb.bookAvailabilitySlot(selectedAvailabilityId!, _currentUser!.id);
                                          }
                                        }
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(widget.isMentor 
                                              ? 'Availability set successfully!' 
                                              : 'Meeting request sent successfully!'),
                                          ),
                                        );
                                      } catch (e) {
                                        debugPrint('Error saving to database: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Error saving. Please try again.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Return to previous screen
                                  },
                                  child: Text(widget.isMentor 
                                    ? 'Confirm' 
                                    : 'Send Request'),
                                ),
                              ],
                            ),
                          );
                        },
                  child: Text(widget.isMentor ? 'Set Availability' : 'Request Meeting'),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  /// Handle approve/reject meeting request
  Future<void> _handleMeetingRequest(Meeting meeting, bool approve) async {
    try {
      if (approve) {
        // Update meeting status to accepted
        final updatedMeeting = meeting.copyWith(status: 'accepted');
        await _localDb.updateMeeting(updatedMeeting);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting request approved!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update meeting status to rejected and unbook the availability slot
        final updatedMeeting = meeting.copyWith(status: 'rejected');
        await _localDb.updateMeeting(updatedMeeting);
        
        if (meeting.availabilityId != null) {
          await _localDb.unbookAvailabilitySlot(meeting.availabilityId!);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meeting request rejected'),
            backgroundColor: Colors.blue[600],
          ),
        );
      }
      
      // Reload data
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
  
  /// Format meeting time
  String _formatMeetingTime(Meeting meeting) {
    try {
      final startTime = DateTime.tryParse(meeting.startTime);
      final endTime = meeting.endTime != null ? DateTime.tryParse(meeting.endTime!) : null;
      
      if (startTime == null) return 'TBD';
      
      String formatTime(DateTime time) {
        final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
      
      final startFormatted = formatTime(startTime);
      if (endTime != null) {
        final endFormatted = formatTime(endTime);
        return '$startFormatted - $endFormatted';
      }
      
      return startFormatted;
    } catch (e) {
      return 'TBD';
    }
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

  List<DateTime> getRecurringDates() {
    List<DateTime> dates = [selectedDate];
    for (int i = 1; i < recurringWeeks; i++) {
      dates.add(selectedDate.add(Duration(days: 7 * i)));
    }
    return dates;
  }

  // Show time picker to add a custom time slot
  Future<void> _addCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final key = selectedDate.toString().split(' ')[0];
      
      if (TestModeManager.isTestMode && widget.isMentor && _currentUser != null) {
        try {
          // Create new availability in database
          final availability = Availability(
            id: _localDb.generateId(),
            mentorId: _currentUser!.id,
            day: key,
            slotStart: picked.format(context),
            isBooked: false,
            updatedAt: DateTime.now(),
          );
          await _localDb.createAvailability(availability);
          
          // Reload availabilities
          await _loadData();
        } catch (e) {
          debugPrint('Error adding custom time: $e');
        }
      } else {
        // Fallback to in-memory storage
        setState(() {
          mentorAvailability.putIfAbsent(key, () => []);
          mentorAvailability[key]!
              .add(MentorTimeSlot(picked.format(context), 'Available'));
        });
      }
    }
  }

  // Save new custom location
  void _addCustomLocation() {
    final newLoc = _customLocationController.text.trim();
    if (newLoc.isNotEmpty) {
      setState(() {
        availableLocations.add(newLoc);
        selectedLocation = newLoc;
        _addingLocation = false;
        _customLocationController.clear();
      });
    }
  }
  
  // Build calendar events for visual indicators
  void _buildCalendarEvents() {
    _calendarEvents.clear();
    print('DEBUG: Building calendar events for schedule screen...');
    print('DEBUG: Availability slots count: ${_availabilities.length}');
    print('DEBUG: All meetings count: ${_allMeetings.length}');
    
    // Add availability events
    for (final slot in _availabilities) {
      final date = DateTime.tryParse(slot.day);
      if (date != null) {
        // Normalize date to remove time component for calendar comparison
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final events = _calendarEvents[normalizedDate] ?? [];
        
        String status = 'Available';
        
        // Check if there's a meeting for this slot
        final meeting = _allMeetings.firstWhere(
          (m) => m.availabilityId == slot.id,
          orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
        );
        
        if (meeting.id.isNotEmpty) {
          // Skip cancelled meetings - treat slot as available
          if (meeting.status == 'cancelled') {
            status = 'Available';
          } else {
            // For mentee view, show their own meeting status
            if (!widget.isMentor && meeting.menteeId == _currentUser?.id) {
              if (meeting.status == 'pending') {
                status = 'Your Request (Pending)';
              } else if (meeting.status == 'accepted') {
                status = 'Your Meeting (Confirmed)';
              } else if (meeting.status == 'rejected') {
                status = 'Your Request (Rejected)';
              }
            } else {
              // For mentor view or other mentees' bookings
              if (meeting.status == 'pending') {
                status = 'Pending Request';
              } else if (meeting.status == 'accepted') {
                status = 'Booked';
              } else {
                status = 'Booked';
              }
            }
          }
        } else if (slot.isBooked) {
          // Slot is booked but not by current mentee
          status = widget.isMentor ? 'Booked' : 'Unavailable';
        }
        
        events.add(CalendarEvent(
          type: 'availability',
          time: slot.slotStart,
          status: status,
          availabilityId: slot.id,
          meetingId: meeting.id.isNotEmpty ? meeting.id : null,
        ));
        _calendarEvents[normalizedDate] = events;
        print('DEBUG: Added availability event for $normalizedDate: ${slot.slotStart} ($status) with availabilityId: ${slot.id}');
      }
    }
    
    print('DEBUG: Total calendar events: ${_calendarEvents.length}');
    _calendarEvents.forEach((date, events) {
      print('DEBUG: $date has ${events.length} events: ${events.map((e) => '${e.time}(${e.status})').join(', ')}');
    });
  }
  
  // Show popup with day's schedule details
  void _showDaySchedulePopup(DateTime selectedDay, List<CalendarEvent> dayEvents) {
    final dateFormatter = "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}";
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = weekdays[selectedDay.weekday - 1];
    
    print('DEBUG: Showing popup for $dateFormatter with ${dayEvents.length} events');
    for (final event in dayEvents) {
      print('DEBUG: Event - time: ${event.time}, status: ${event.status}, type: ${event.type}');
    }
    
    // Group events by status for better organization
    final availableSlots = dayEvents.where((e) => e.status == 'Available').toList();
    final pendingSlots = dayEvents.where((e) => e.status == 'Pending Request').toList();
    final bookedSlots = dayEvents.where((e) => e.status == 'Booked').toList();
    
    print('DEBUG: Grouped - Available: ${availableSlots.length}, Pending: ${pendingSlots.length}, Booked: ${bookedSlots.length}');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                dateFormatter,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableSlots.isNotEmpty) ...[
                  _buildScheduleSection(
                    'Available Time Slots',
                    availableSlots,
                    Colors.lightBlue,
                    Icons.check_circle_outline,
                    selectedDay,
                  ),
                  const SizedBox(height: 16),
                ],
                if (pendingSlots.isNotEmpty) ...[
                  _buildScheduleSection(
                    'Pending Requests',
                    pendingSlots,
                    Colors.blue[600]!,
                    Icons.schedule,
                    selectedDay,
                  ),
                  const SizedBox(height: 16),
                ],
                if (bookedSlots.isNotEmpty) ...[
                  _buildScheduleSection(
                    'Confirmed Meetings',
                    bookedSlots,
                    Colors.indigo,
                    Icons.event,
                    selectedDay,
                  ),
                ],
                if (dayEvents.isEmpty) 
                  const Text(
                    'No events scheduled for this day.',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (widget.isMentor && availableSlots.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Could add functionality to quickly book a slot here
                },
                child: const Text('Manage Slots'),
              ),
          ],
        );
      },
    );
  }
  
  // Helper method to build schedule sections
  Widget _buildScheduleSection(String title, List<CalendarEvent> events, Color color, IconData icon, DateTime selectedDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...events.map((event) => _buildEventTile(event, color, selectedDay)),
      ],
    );
  }
  
  // Helper method to build individual event tiles
  Widget _buildEventTile(CalendarEvent event, Color color, DateTime selectedDay) {
    // Find additional details for this event
    String? menteeInfo;
    String? meetingTopic;
    String? meetingLocation;
    
    print('DEBUG: Building event tile for time: ${event.time}, status: ${event.status}, availabilityId: ${event.availabilityId}');
    print('DEBUG: Available _availabilities count: ${_availabilities.length}');
    print('DEBUG: Available _allMeetings count: ${_allMeetings.length}');
    
    // Use the availabilityId from the event if available
    if (event.availabilityId != null && event.availabilityId!.isNotEmpty) {
      // Find the availability slot by ID
      final availabilitySlot = _availabilities.firstWhere(
        (slot) => slot.id == event.availabilityId,
        orElse: () => Availability(id: '', mentorId: '', day: '', slotStart: '', isBooked: false, updatedAt: DateTime.now()),
      );
      
      print('DEBUG: Found availability slot by ID: id=${availabilitySlot.id}, slotStart=${availabilitySlot.slotStart}, isBooked=${availabilitySlot.isBooked}');
      
      if (availabilitySlot.id.isNotEmpty) {
      print('DEBUG: Looking for meeting with availabilityId: ${availabilitySlot.id}');
      print('DEBUG: All meetings availabilityIds: ${_allMeetings.map((m) => '${m.id}:${m.availabilityId}').join(', ')}');
      
      // Always look for associated meeting, regardless of event status
      final meeting = _allMeetings.firstWhere(
        (meeting) => meeting.availabilityId == availabilitySlot.id,
        orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
      );
      
      print('DEBUG: Found meeting: id=${meeting.id}, topic=${meeting.topic}, location=${meeting.location}');
      
      if (meeting.id.isNotEmpty) {
        final mentee = _menteeMap[meeting.menteeId];
        menteeInfo = mentee?.name ?? 'Unknown Mentee';
        meetingTopic = meeting.topic;
        meetingLocation = meeting.location;
        print('DEBUG: Set details - mentee: $menteeInfo, topic: $meetingTopic, location: $meetingLocation');
      } else if (availabilitySlot.menteeId != null) {
        final mentee = _menteeMap[availabilitySlot.menteeId];
        menteeInfo = mentee?.name ?? 'Unknown Mentee';
        print('DEBUG: Using availability slot menteeId: ${availabilitySlot.menteeId}, mentee: $menteeInfo');
      } else {
        print('DEBUG: No meeting found and no menteeId in availability slot');
      }
      }
    } else {
      print('DEBUG: No availabilityId in event, trying to find by day and time');
      // Fallback: try to find by matching day and time
      final dateString = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
      final availabilitySlot = _availabilities.firstWhere(
        (slot) => slot.day == dateString && slot.slotStart == event.time,
        orElse: () => Availability(id: '', mentorId: '', day: '', slotStart: '', isBooked: false, updatedAt: DateTime.now()),
      );
      
      if (availabilitySlot.id.isNotEmpty) {
        print('DEBUG: Found availability slot by day/time: id=${availabilitySlot.id}');
        // Look for associated meeting
        final meeting = _allMeetings.firstWhere(
          (meeting) => meeting.availabilityId == availabilitySlot.id,
          orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
        );
        
        if (meeting.id.isNotEmpty) {
          final mentee = _menteeMap[meeting.menteeId];
          menteeInfo = mentee?.name ?? 'Unknown Mentee';
          meetingTopic = meeting.topic;
          meetingLocation = meeting.location;
          print('DEBUG: Set details from fallback - mentee: $menteeInfo, topic: $meetingTopic, location: $meetingLocation');
        } else if (availabilitySlot.menteeId != null) {
          final mentee = _menteeMap[availabilitySlot.menteeId];
          menteeInfo = mentee?.name ?? 'Unknown Mentee';
        }
      } else {
        print('DEBUG: No availability slot found for date: $dateString and time: ${event.time}');
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (menteeInfo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        menteeInfo,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (meetingTopic != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.topic, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meetingTopic,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (meetingLocation != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meetingLocation,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom vector dot to bypass color rendering issues
  Widget _createVectorDot(Color color) {
    return CustomPaint(
      size: Size(6, 6),
      painter: _DotPainter(color),
    );
  }
  
  // Show popup dialog with all pending meeting requests
  void _showAllPendingRequestsDialog() {
    final pendingMeetings = _allMeetings.where((m) => m.status == 'pending').toList();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue[600]!),
              const SizedBox(width: 8),
              const Text('All Pending Requests'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pendingMeetings.isNotEmpty) ...[
                  Text(
                    '${pendingMeetings.length} pending meeting request${pendingMeetings.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: pendingMeetings.length,
                      itemBuilder: (context, index) {
                        final meeting = pendingMeetings[index];
                        final mentee = _menteeMap[meeting.menteeId];
                        final startTime = DateTime.tryParse(meeting.startTime);
                        
                        return Card(
                          color: Colors.blue[100],
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[600]!,
                              child: Text(
                                mentee?.name.substring(0, 1).toUpperCase() ?? '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(mentee?.name ?? 'Unknown Mentee'),
                            subtitle: Text(
                              '${startTime != null ? _formatDate(startTime) : 'Unknown date'} at ${meeting.location ?? 'TBD'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () async {
                                    Navigator.of(context).pop(); // Close dialog first
                                    await _handleMeetingRequest(meeting, true);
                                  },
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () async {
                                    Navigator.of(context).pop(); // Close dialog first
                                    await _handleMeetingRequest(meeting, false);
                                  },
                                  tooltip: 'Reject',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No pending requests found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  /// Check if a meeting is in the future
  bool _isFutureMeeting(Meeting meeting) {
    final startTime = DateTime.tryParse(meeting.startTime);
    if (startTime == null) return false;
    return startTime.isAfter(DateTime.now());
  }
  
  /// Show cancel meeting confirmation dialog
  void _showCancelMeetingDialog(Meeting meeting) {
    final mentee = _menteeMap[meeting.menteeId];
    final startTime = DateTime.tryParse(meeting.startTime);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Cancel Meeting?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this meeting?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Mentee: ${mentee?.name ?? "Unknown"}'),
              if (startTime != null)
                Text('Date: ${_formatDate(startTime)}'),
              Text('Time: ${_formatMeetingTime(meeting)}'),
              if (meeting.location != null)
                Text('Location: ${meeting.location}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The mentee will be notified of the cancellation.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Meeting'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _cancelMeeting(meeting);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Meeting'),
            ),
          ],
        );
      },
    );
  }
  
  /// Cancel a meeting
  Future<void> _cancelMeeting(Meeting meeting) async {
    try {
      final success = await _localDb.cancelMeeting(meeting.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Reload data to refresh the UI
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel meeting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Show all upcoming meetings dialog
  void _showAllUpcomingMeetingsDialog() {
    final upcomingMeetings = _allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).toList();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.event_available, color: Colors.green),
              const SizedBox(width: 8),
              const Text('All Upcoming Meetings'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${upcomingMeetings.length} upcoming meeting${upcomingMeetings.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: upcomingMeetings.length,
                    itemBuilder: (context, index) {
                      final meeting = upcomingMeetings[index];
                      final mentee = _menteeMap[meeting.menteeId];
                      final startTime = DateTime.tryParse(meeting.startTime);
                      
                      return Card(
                        color: Colors.green[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              mentee?.name.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(mentee?.name ?? 'Unknown Mentee'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${startTime != null ? _formatDate(startTime) : 'Unknown date'} at ${_formatMeetingTime(meeting)}',
                              ),
                              if (meeting.location != null)
                                Text(
                                  'Location: ${meeting.location}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close this dialog first
                              _showCancelMeetingDialog(meeting);
                            },
                            tooltip: 'Cancel Meeting',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  /// Show all upcoming meetings dialog for mentees
  void _showAllUpcomingMeetingsDialogMentee() {
    final upcomingMeetings = _allMeetings.where((m) => m.status == 'accepted' && _isFutureMeeting(m)).toList();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.event_available, color: Colors.green),
              const SizedBox(width: 8),
              const Text('All Your Upcoming Meetings'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${upcomingMeetings.length} upcoming meeting${upcomingMeetings.length == 1 ? '' : 's'} with your mentor',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: upcomingMeetings.length,
                    itemBuilder: (context, index) {
                      final meeting = upcomingMeetings[index];
                      final startTime = DateTime.tryParse(meeting.startTime);
                      
                      return Card(
                        color: Colors.green[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            meeting.topic ?? 'Meeting with Mentor',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${startTime != null ? _formatDate(startTime) : 'Unknown date'} at ${_formatMeetingTime(meeting)}',
                              ),
                              if (meeting.location != null)
                                Text(
                                  'Location: ${meeting.location}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (_otherUser != null)
                                Text(
                                  'With: ${_otherUser!.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close this dialog first
                              _showCancelMeetingDialog(meeting);
                            },
                            tooltip: 'Cancel Meeting',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for perfectly aligned dots
class _DotPainter extends CustomPainter {
  final Color color;
  
  _DotPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Draw perfect circle at exact center
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MentorTimeSlot {
  final String time;
  final String status; // 'Available', 'Pending Request', or 'Booked'
  final String? availabilityId;
  final String? menteeName;
  final Meeting? meeting;

  MentorTimeSlot(this.time, this.status, {this.availabilityId, this.menteeName, this.meeting});
}

class CalendarEvent {
  final String type;
  final String time;
  final String status;
  final String? availabilityId;
  final String? meetingId;
  
  CalendarEvent({
    required this.type,
    required this.time, 
    required this.status,
    this.availabilityId,
    this.meetingId,
  });
} 