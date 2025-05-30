import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/test_mode_manager.dart';
import '../services/local_database_service.dart';
import '../models/availability.dart';
import '../models/meeting.dart';
import '../models/user.dart';

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
        // Get current user from test mode
        _currentUser = TestModeManager.currentTestUser;
        print('DEBUG: Current user: ${_currentUser?.name} (${_currentUser?.id})');
        
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
                // Get only available (non-booked) slots
                _availabilities = await _localDb.getAvailableSlots(mentorId);
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
        
        // Check if there's a meeting for this slot (regardless of isBooked status)
        final meeting = _allMeetings.firstWhere(
          (m) => m.availabilityId == avail.id,
          orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
        );
        
        if (meeting.id.isNotEmpty) {
          // Base status on meeting status, not availability isBooked flag
          if (meeting.status == 'pending') {
            status = 'Pending Request';
          } else if (meeting.status == 'accepted') {
            status = 'Booked';
          } else {
            status = 'Booked'; // Default for other statuses
          }
          menteeName = _menteeMap[meeting.menteeId]?.name;
        } else if (avail.isBooked) {
          // Only use isBooked if no meeting found (legacy case)
          status = 'Booked';
          if (avail.menteeId != null) {
            menteeName = _menteeMap[avail.menteeId]?.name;
          }
        }
        
        return MentorTimeSlot(
          avail.slotStart, 
          status,
          availabilityId: avail.id,
          menteeName: menteeName,
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
        return Colors.orange.withOpacity(0.1);
      case 'Booked':
        return Colors.red.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color getTimeSlotTextColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Pending Request':
        return Colors.orange;
      case 'Booked':
        return Colors.red;
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
      body: ListView(
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
                        _buildLegendItem('Open', Colors.green),
                        const SizedBox(width: 16),
                        _buildLegendItem('Pending', Colors.orange),
                        const SizedBox(width: 16),
                        _buildLegendItem('Confirmed', Colors.red),
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
                    Row(
                      children: [
                        _buildLegendItem('Available', Colors.green),
                        const SizedBox(width: 16),
                        _buildLegendItem('Pending', Colors.orange),
                        const SizedBox(width: 16),
                        _buildLegendItem('Booked', Colors.red),
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
                  TableCalendar<CalendarEvent>(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: selectedDate,
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (day) {
                      return _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];
                    },
                    selectedDayPredicate: (day) {
                      return isSameDay(selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(selectedDate, selectedDay)) {
                        setState(() {
                          selectedDate = selectedDay;
                          selectedTime = null;
                        });
                      }
                      
                      // Show popup if this date has events
                      final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                      final dayEvents = _calendarEvents[normalizedDay];
                      if (dayEvents != null && dayEvents.isNotEmpty) {
                        _showDaySchedulePopup(selectedDay, dayEvents);
                      }
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<CalendarEvent>(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: events.take(3).map((event) {
                              Color dotColor;
                              switch (event.status) {
                                case 'Available':
                                  dotColor = Colors.green;
                                  break;
                                case 'Pending Request':
                                  dotColor = Colors.orange;
                                  break;
                                case 'Booked':
                                  dotColor = Colors.red;
                                  break;
                                default:
                                  dotColor = Colors.blue;
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          );
                        }
                        return const SizedBox.shrink();
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
                    const Text(
                      'Pending Meeting Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._allMeetings.where((m) => m.status == 'pending').map((meeting) {
                      final mentee = _menteeMap[meeting.menteeId];
                      final startTime = DateTime.tryParse(meeting.startTime);
                      return Card(
                        color: Colors.orange[50],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('Meeting request rejected'),
            backgroundColor: Colors.orange,
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
        
        // Check if there's a meeting for this slot (regardless of isBooked status)
        final meeting = _allMeetings.firstWhere(
          (m) => m.availabilityId == slot.id,
          orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
        );
        
        if (meeting.id.isNotEmpty) {
          // Base status on meeting status, not availability isBooked flag
          if (meeting.status == 'pending') {
            status = 'Pending Request';
          } else if (meeting.status == 'accepted') {
            status = 'Booked';
          } else {
            status = 'Booked'; // Default for other statuses
          }
        } else if (slot.isBooked) {
          // Only use isBooked if no meeting found (legacy case)
          status = 'Booked';
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
                    Colors.green,
                    Icons.check_circle_outline,
                    selectedDay,
                  ),
                  const SizedBox(height: 16),
                ],
                if (pendingSlots.isNotEmpty) ...[
                  _buildScheduleSection(
                    'Pending Requests',
                    pendingSlots,
                    Colors.orange,
                    Icons.schedule,
                    selectedDay,
                  ),
                  const SizedBox(height: 16),
                ],
                if (bookedSlots.isNotEmpty) ...[
                  _buildScheduleSection(
                    'Confirmed Meetings',
                    bookedSlots,
                    Colors.red,
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
}

class MentorTimeSlot {
  final String time;
  final String status; // 'Available', 'Pending Request', or 'Booked'
  final String? availabilityId;
  final String? menteeName;

  MentorTimeSlot(this.time, this.status, {this.availabilityId, this.menteeName});
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