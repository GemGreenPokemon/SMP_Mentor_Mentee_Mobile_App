import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/responsive.dart';
import '../services/meeting_service.dart';
import '../services/auth_service.dart';
import '../services/dashboard_data_service.dart';
import '../models/availability.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../utils/test_mode_manager.dart';
import 'package:uuid/uuid.dart';

class WebScheduleMeetingScreen extends StatefulWidget {
  final bool isMentor;

  const WebScheduleMeetingScreen({
    super.key,
    required this.isMentor,
  });

  @override
  State<WebScheduleMeetingScreen> createState() => _WebScheduleMeetingScreenState();
}

class _WebScheduleMeetingScreenState extends State<WebScheduleMeetingScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _selectedTime;
  List<DateTime> _selectedAvailabilitySlots = []; // For setting multiple availability slots
  bool _isCustomTimeRequest = false;
  bool _isSettingAvailability = true; // For mentors: toggle between setting availability and scheduling meetings
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  Map<String, dynamic>? _selectedMenteeOrMentor;
  String _meetingType = 'in-person';
  String _repeatOption = 'none';
  
  // Database integration
  final _meetingService = MeetingService();
  final _authService = AuthService();
  final _dashboardService = DashboardDataService();
  final _uuid = const Uuid();
  List<Availability> _availabilitySlots = [];
  List<Meeting> _meetings = [];
  User? _currentUser;
  Map<String, dynamic>? _currentUserData;
  Map<DateTime, List<CalendarEvent>> _calendarEvents = {};
  bool _isLoadingData = false;
  bool _isSavingData = false;
  Set<String> _pendingOperations = {};
  
  // Real data for mentees/mentors
  List<Map<String, dynamic>> _menteesList = [];
  List<Map<String, dynamic>> _mentorsList = [];
  
  // Mock mentor availability data (will be replaced with real data)
  final Map<String, List<TimeSlot>> mentorAvailability = {
    '2024-02-14': [
      TimeSlot('2:00 PM', 'Available'),
      TimeSlot('3:00 PM', 'Pending'),
      TimeSlot('4:00 PM', 'Booked'),
    ],
    '2024-02-15': [
      TimeSlot('9:00 AM', 'Available'),
      TimeSlot('10:00 AM', 'Available'),
      TimeSlot('2:00 PM', 'Booked'),
    ],
    '2024-02-16': [
      TimeSlot('11:00 AM', 'Available'),
      TimeSlot('2:00 PM', 'Available'),
      TimeSlot('3:00 PM', 'Pending'),
    ],
  };

  @override
  void initState() {
    super.initState();
    print('DEBUG: WebScheduleMeetingScreen initState called');
    _selectedDay = _focusedDay;
    _loadCurrentUser();
    _setupRealtimeListeners();
  }
  
  void _setupRealtimeListeners() {
    // Subscribe to real-time updates
    _meetingService.availabilityStream.listen((availability) {
      if (mounted) {
        print('DEBUG: Stream update - received ${availability.length} availability slots');
        setState(() {
          _availabilitySlots = availability;
          _buildCalendarEvents();
        });
      }
    });
    
    _meetingService.meetingsStream.listen((meetings) {
      if (mounted) {
        print('DEBUG: Stream update - received ${meetings.length} meetings');
        setState(() {
          _meetings = meetings;
          _buildCalendarEvents();
        });
      }
    });
  }
  
  Future<void> _loadCurrentUser() async {
    try {
      // Get current user from Firebase Auth
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        print('DEBUG: No authenticated user');
        return;
      }
      
      // Get user data from dashboard service
      final dashboardData = widget.isMentor 
          ? await _dashboardService.getMentorDashboardData()
          : await _dashboardService.getMenteeDashboardData();
      
      setState(() {
        _currentUserData = widget.isMentor 
            ? dashboardData['mentorProfile']
            : dashboardData['menteeProfile'];
            
        // Load mentees list if user is a mentor
        if (widget.isMentor && dashboardData['mentees'] != null) {
          _menteesList = List<Map<String, dynamic>>.from(dashboardData['mentees']).map((mentee) {
            // Get the user document ID from Firestore to find their firebase_uid
            return {
              'id': mentee['id'] ?? '',
              'firebase_uid': mentee['firebase_uid'] ?? mentee['id'] ?? '', // Use id as fallback
              'name': mentee['name'] ?? 'Unknown',
              'program': mentee['program'] ?? '',
              'display': mentee['name'] ?? 'Unknown', // Just show name to avoid overflow
            };
          }).toList();
          
          print('DEBUG: Loaded ${_menteesList.length} mentees for mentor');
        }
      });
      
      print('DEBUG: Loading calendar data for: ${_currentUserData?['name']}');
      
      // Subscribe to real-time updates for this user
      _meetingService.subscribeToAvailability(firebaseUser.uid);
      _meetingService.subscribeToMeetings(firebaseUser.uid, widget.isMentor);
      
      // Initial load is now triggered just to restore state
      await _loadCalendarData();
    } catch (e) {
      print('DEBUG: Error loading current user: $e');
    }
  }
  
  Future<void> _loadCalendarData() async {
    if (_authService.currentUser == null) {
      print('DEBUG: No authenticated user found!');
      return;
    }
    
    // Preserve current selections before loading
    final preservedSelections = List<DateTime>.from(_selectedAvailabilitySlots);
    
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      final userId = _authService.currentUser!.uid;
      print('DEBUG: Loading calendar data for user: ${_currentUserData?['name']} ($userId)');
      
      // Don't load data here as the stream will provide it
      // Just set up the subscriptions
      _meetingService.subscribeToAvailability(userId);
      _meetingService.subscribeToMeetings(userId, widget.isMentor);
      
      print('DEBUG: Subscribed to real-time updates for user: $userId');
      
      setState(() {
        _isLoadingData = false;
        
        // Restore selections if they haven't been saved yet
        if (widget.isMentor && _isSettingAvailability && _selectedDay != null) {
          // Only restore selections that aren't already saved in the database
          _selectedAvailabilitySlots = preservedSelections.where((slot) {
            final timeStr = _formatTime(slot);
            return !_availabilitySlots.any((dbSlot) => 
              dbSlot.day == _formatDateForDatabase(_selectedDay!) && 
              dbSlot.slotStart == timeStr
            );
          }).toList();
        }
      });
    } catch (e) {
      print('DEBUG: Error loading calendar data: $e');
      setState(() {
        _isLoadingData = false;
        // Restore selections even on error
        if (widget.isMentor && _isSettingAvailability) {
          _selectedAvailabilitySlots = preservedSelections;
        }
      });
    }
  }
  
  void _buildCalendarEvents() {
    _calendarEvents.clear();
    print('DEBUG: Building calendar events...');
    print('DEBUG: Availability slots count: ${_availabilitySlots.length}');
    print('DEBUG: Meetings count: ${_meetings.length}');
    
    // Add availability events
    for (final slot in _availabilitySlots) {
      print('DEBUG: Processing slot with day: "${slot.day}", slotStart: "${slot.slotStart}"');
      final date = DateTime.tryParse(slot.day);
      print('DEBUG: Processing availability slot: ${slot.day} -> parsed date: $date');
      if (date != null) {
        // Normalize date to remove time component for calendar comparison
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final events = _calendarEvents[normalizedDate] ?? [];
        events.add(CalendarEvent(
          type: slot.isBooked ? 'booked' : 'available',
          time: slot.slotStart,
          status: slot.isBooked ? 'Booked' : 'Available',
        ));
        _calendarEvents[normalizedDate] = events;
        print('DEBUG: Added availability event for $normalizedDate: ${slot.slotStart} (${slot.isBooked ? "Booked" : "Available"})');
      } else {
        print('DEBUG: Failed to parse date: ${slot.day}');
      }
    }
    
    // Add meeting events
    for (final meeting in _meetings) {
      final startTime = DateTime.tryParse(meeting.startTime);
      print('DEBUG: Processing meeting: ${meeting.startTime} -> parsed time: $startTime');
      if (startTime != null) {
        final date = DateTime(startTime.year, startTime.month, startTime.day);
        final events = _calendarEvents[date] ?? [];
        events.add(CalendarEvent(
          type: 'meeting',
          time: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
          status: meeting.status == 'pending' ? 'Pending' : 'Booked',
        ));
        _calendarEvents[date] = events;
        print('DEBUG: Added meeting event for $date: ${meeting.topic} (${meeting.status})');
      } else {
        print('DEBUG: Failed to parse meeting start time: ${meeting.startTime}');
      }
    }
    
    print('DEBUG: Total calendar events: ${_calendarEvents.length}');
    _calendarEvents.forEach((date, events) {
      print('DEBUG: $date has ${events.length} events: ${events.map((e) => '${e.time}(${e.status})').join(', ')}');
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMentor 
          ? (_isSettingAvailability ? 'Set Your Availability' : 'Schedule Meeting with Mentee')
          : 'Request Meeting with Mentor'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // This prevents any back button from appearing
        actions: widget.isMentor ? [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Set Availability'),
                  icon: Icon(Icons.calendar_today),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Schedule Meeting'),
                  icon: Icon(Icons.event),
                ),
              ],
              selected: {_isSettingAvailability},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isSettingAvailability = newSelection.first;
                  // Reset selections when switching modes
                  _selectedTime = null;
                  _selectedMenteeOrMentor = null;
                  _titleController.clear();
                  _descriptionController.clear();
                  _locationController.clear();
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white.withOpacity(0.2);
                  }
                  return Colors.transparent;
                }),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
          ),
        ] : null,
      ),
      body: _isLoadingData 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading calendar data...'),
              ],
            ),
          )
        : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1200 : double.infinity,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar section
                  Expanded(
                    flex: isDesktop ? 5 : 1,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Select Date',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Refresh calendar',
                                  onPressed: _loadCalendarData,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TableCalendar<CalendarEvent>(
                              firstDay: DateTime.now(),
                              lastDay: DateTime.now().add(const Duration(days: 365)),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              eventLoader: (day) {
                                return _calendarEvents[day] ?? [];
                              },
                              selectedDayPredicate: (day) {
                                return isSameDay(_selectedDay, day);
                              },
                              onDaySelected: (selectedDay, focusedDay) {
                                if (!isSameDay(_selectedDay, selectedDay)) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                }
                              },
                              onFormatChanged: (format) {
                                if (_calendarFormat != format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                }
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              calendarStyle: const CalendarStyle(
                                selectedDecoration: BoxDecoration(
                                  color: Color(0xFF0F2D52),
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: Color(0x800F2D52),
                                  shape: BoxShape.circle,
                                ),
                                markersAlignment: Alignment.bottomCenter,
                                markersMaxCount: 3,
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: true,
                                titleCentered: true,
                                formatButtonShowsNext: false,
                                formatButtonDecoration: BoxDecoration(
                                  color: Color(0xFF0F2D52),
                                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                                ),
                                formatButtonTextStyle: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders<CalendarEvent>(
                                markerBuilder: (context, day, events) {
                                  if (events.isEmpty) return null;

                                  // Create ALL dots as indigo/blue baseline since they align correctly
                                  // Sort to ensure consistent order: Available, Pending, Booked
                                  final statusOrder = {'Available': 0, 'Pending': 1, 'Pending Request': 1, 'Booked': 2};
                                  final sortedEvents = List<CalendarEvent>.from(events)
                                    ..sort((a, b) => (statusOrder[a.status] ?? 99).compareTo(statusOrder[b.status] ?? 99));

                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.bottomCenter,
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: sortedEvents.take(3).map((event) {
                                        // Use red as baseline template, only change color
                                        Color dotColor = Colors.indigo; // Start with indigo template
                                        
                                        if (event.status == 'Available') {
                                          dotColor = Colors.lightBlue;
                                        } else if (event.status == 'Pending' || event.status == 'Pending Request') {
                                          dotColor = Colors.blue[600]!;
                                        } else if (event.status == 'Booked') {
                                          dotColor = Colors.indigo;
                                        }
                                        
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: dotColor,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Time selection
                            const Text(
                              'Select Time',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedDay != null && !_isSettingAvailability) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
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
                                          widget.isMentor ? 'Your Availability' : 'Mentor Availability',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.isMentor 
                                        ? 'Only times you have set as available are shown below. Select one to schedule a meeting with your mentee.'
                                        : 'Light blue slots show when your mentor is available. You can also request a custom time if needed.',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildLegend('Available', Colors.lightBlue),
                                        const SizedBox(width: 16),
                                        _buildLegend('Pending', Colors.blue[600]!),
                                        const SizedBox(width: 16),
                                        _buildLegend('Booked', Colors.indigo),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Custom selected times display
                            if (widget.isMentor && _isSettingAvailability && _selectedAvailabilitySlots.isNotEmpty) ...[
                              Container(
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
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedAvailabilitySlots.map((slot) {
                                        final timeStr = _formatTime(slot);
                                        final isCustom = !_generateTimeSlots().any((t) => 
                                          t.hour == slot.hour && t.minute == slot.minute
                                        );
                                        return Chip(
                                          label: Text(timeStr),
                                          deleteIcon: const Icon(Icons.close, size: 18),
                                          backgroundColor: isCustom 
                                            ? Colors.purple.withOpacity(0.1) 
                                            : Colors.lightBlue.withOpacity(0.2),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedAvailabilitySlots.removeWhere((s) => 
                                                s.hour == slot.hour && s.minute == slot.minute
                                              );
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Show message if no available slots for mentor scheduling
                            if (widget.isMentor && !_isSettingAvailability && _selectedDay != null && _getTimeSlots().isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                              ),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.isMentor && _isSettingAvailability) ...[
                                  // Custom time button
                                  ActionChip(
                                    avatar: const Icon(Icons.add_alarm, size: 18),
                                    label: const Text('Add Custom Time'),
                                    backgroundColor: Colors.purple.withOpacity(0.1),
                                    onPressed: () => _selectCustomAvailabilityTime(),
                                  ),
                                  const SizedBox(width: 16),
                                  // Multiple selection for availability
                                  ..._generateTimeSlots().map((time) {
                                    final timeStr = _formatTime(time);
                                    final isSelected = _selectedAvailabilitySlots.any(
                                      (slot) => slot.hour == time.hour && slot.minute == time.minute
                                    );
                                    
                                    // Check if this slot is already saved in the database
                                    final existingSlot = _availabilitySlots.firstWhere(
                                      (slot) => slot.day == _formatDateForDatabase(_selectedDay!) && 
                                                slot.slotStart == timeStr,
                                      orElse: () => Availability(
                                        id: '', mentorId: '', day: '', slotStart: '', isBooked: false
                                      ),
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
                                                if (_pendingOperations.contains(existingSlot.id)) ...[
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
                                              ],
                                            ),
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
                                          onSelected: existingSlot.isBooked || _pendingOperations.contains(existingSlot.id) ? null : (selected) {
                                            if (isAlreadySaved && !existingSlot.isBooked) {
                                              // Show confirmation dialog for removing availability
                                              _showRemoveAvailabilityDialog(existingSlot);
                                            } else {
                                              setState(() {
                                                if (selected && !isAlreadySaved) {
                                                  _selectedAvailabilitySlots.add(time);
                                                } else if (!selected && !isAlreadySaved) {
                                                  _selectedAvailabilitySlots.removeWhere(
                                                    (slot) => slot.hour == time.hour && slot.minute == time.minute
                                                  );
                                                }
                                              });
                                            }
                                          },
                                        ),
                                        if (isAlreadySaved && !existingSlot.isBooked)
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                              ),
                                              child: InkWell(
                                                onTap: () => _showRemoveAvailabilityDialog(existingSlot),
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
                                  }).toList(),
                                ] else ...[
                                  // Single selection for scheduling
                                  ..._getTimeSlots().map((slot) {
                                    final isSelected = _selectedTime != null && 
                                                     _formatTime(_selectedTime!) == slot.time &&
                                                     !_isCustomTimeRequest;
                                    final color = _getSlotColor(slot.status);
                                    final textColor = _getSlotTextColor(slot.status);
                                    final isAvailable = slot.status == 'Available';
                                    
                                    return Stack(
                                      children: [
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
                                                ],
                                              ],
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedColor: color,
                                          backgroundColor: color.withOpacity(0.2),
                                          onSelected: isAvailable || widget.isMentor ? (selected) {
                                            setState(() {
                                              _selectedTime = selected ? _parseTime(slot.time) : null;
                                              _isCustomTimeRequest = false;
                                            });
                                          } : null,
                                        ),
                                        // Notification badge for pending requests (mentor view)
                                        if (widget.isMentor && slot.status == 'Pending Request')
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
                                  }).toList(),
                                ],
                                if (!widget.isMentor) ...[
                                  const SizedBox(width: 16),
                                  ActionChip(
                                    avatar: const Icon(Icons.add, size: 18),
                                    label: const Text('Request Custom Time'),
                                    backgroundColor: _isCustomTimeRequest ? 
                                      Colors.purple.withOpacity(0.2) : null,
                                    onPressed: () => _selectCustomTime(),
                                  ),
                                ],
                              ],
                            ),
                            if (_isCustomTimeRequest && _selectedTime != null) ...[
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
                                      'Custom time request: ${_formatTime(_selectedTime!)}',
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
                        ),
                      ),
                    ),
                  ),
                  
                  if (isDesktop || isTablet)
                    const SizedBox(width: 24),
                  
                  // Meeting details section
                  Expanded(
                    flex: isDesktop ? 4 : 1,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isMentor && _isSettingAvailability 
                                ? 'Availability Details'
                                : 'Meeting Details',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Show different fields based on mode
                            if (widget.isMentor && _isSettingAvailability) ...[
                              // Show existing availability summary
                              if (_selectedDay != null && _availabilitySlots.any((s) => s.day == _formatDateForDatabase(_selectedDay!))) ...[
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
                                        '${_availabilitySlots.where((s) => s.day == _formatDateForDatabase(_selectedDay!)).length} time slots set for this day',
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
                                    onPressed: () {
                                      setState(() {
                                        _selectedAvailabilitySlots = List.from(_generateTimeSlots());
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Clear All'),
                                    onPressed: () {
                                      setState(() {
                                        _selectedAvailabilitySlots.clear();
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy to Other Days'),
                                    onPressed: _selectedAvailabilitySlots.isNotEmpty ? () {
                                      _showCopyAvailabilityDialog();
                                    } : null,
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
                                      'Selected slots: ${_getSelectedSlotsCount()} time slots',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              // For scheduling meetings
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Meeting Title',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.title),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Select mentee/mentor
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedMenteeOrMentor,
                                decoration: InputDecoration(
                                  labelText: widget.isMentor ? 'Select Mentee' : 'Select Mentor',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.person),
                                ),
                                isExpanded: true,
                                items: widget.isMentor 
                                  ? _menteesList.map((mentee) {
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: mentee,
                                        child: Text(
                                          mentee['display'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList()
                                  : _mentorsList.isEmpty 
                                    ? [] 
                                    : _mentorsList.map((mentor) {
                                        return DropdownMenuItem<Map<String, dynamic>>(
                                          value: mentor,
                                          child: Text(
                                            mentor['display'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMenteeOrMentor = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return widget.isMentor ? 'Please select a mentee' : 'Please select a mentor';
                                  }
                                  return null;
                                },
                              ),
                              // Show selected mentee/mentor details
                              if (_selectedMenteeOrMentor != null && _selectedMenteeOrMentor!['program'].isNotEmpty) ...[
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
                                          _selectedMenteeOrMentor!['program'],
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
                            ],
                            
                            // Only show meeting details for actual meetings, not availability
                            if (!widget.isMentor || !_isSettingAvailability) ...[
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
                                      groupValue: _meetingType,
                                      onChanged: (value) {
                                        setState(() {
                                          _meetingType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Virtual'),
                                      value: 'virtual',
                                      groupValue: _meetingType,
                                      onChanged: (value) {
                                        setState(() {
                                          _meetingType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Location
                              TextField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  labelText: _meetingType == 'in-person' ? 'Location' : 'Meeting Link',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    _meetingType == 'in-person' ? Icons.location_on : Icons.link,
                                  ),
                                  hintText: _meetingType == 'in-person' 
                                    ? 'e.g., Library Room 201' 
                                    : 'e.g., Zoom link',
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Description
                              TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Optional)',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 16),
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
                              value: _repeatOption,
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
                              onChanged: (value) {
                                setState(() {
                                  _repeatOption = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Selected date and time summary
                            if (_selectedDay != null && _selectedTime != null)
                              Container(
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
                                            '${_formatDate(_selectedDay!)} at ${_formatTime(_selectedTime!)}',
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
                              ),
                            
                            const SizedBox(height: 32),
                            
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Clear form data instead of navigating away
                                      setState(() {
                                        _selectedAvailabilitySlots.clear();
                                        _selectedTime = null;
                                        _titleController.clear();
                                        _descriptionController.clear();
                                        _locationController.clear();
                                        _selectedMenteeOrMentor = null;
                                        _isCustomTimeRequest = false;
                                      });
                                      
                                      // Show a snackbar to confirm cancellation
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Form cleared'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Clear'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSavingData ? null : _scheduleMeeting,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F2D52),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: _isSavingData 
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
                                      : Text(widget.isMentor 
                                          ? (_isSettingAvailability 
                                            ? 'Set Availability' 
                                            : 'Schedule Meeting')
                                          : (_isCustomTimeRequest 
                                            ? 'Request Custom Meeting Time' 
                                            : 'Request Meeting')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TimeSlot> _getTimeSlots() {
    if (_selectedDay == null) return [];
    
    final events = _calendarEvents[_selectedDay!] ?? [];
    
    if (widget.isMentor && _isSettingAvailability) {
      // For mentors setting availability, show all time slots
      // and mark which ones are already set as available
      final allSlots = _generateTimeSlots();
      
      return allSlots.map((time) {
        final timeStr = _formatTime(time);
        // Check if this time slot already exists in events (meaning it's already saved)
        final existingEvent = events.firstWhere(
          (event) => event.time == timeStr,
          orElse: () => CalendarEvent(type: 'available', time: timeStr, status: 'Not Set'),
        );
        
        // If it exists in events, it's already saved as available
        return TimeSlot(timeStr, existingEvent.status == 'Available' ? 'Already Set' : 'Not Set');
      }).toList();
    } else if (widget.isMentor && !_isSettingAvailability) {
      // For mentors scheduling meetings, only show their available (not booked) times
      final dayStr = _formatDateForDatabase(_selectedDay!);
      final availableSlots = _availabilitySlots.where((slot) =>
        slot.day == dayStr &&
        !slot.isBooked
      ).map((slot) => TimeSlot(slot.slotStart, 'Available')).toList();
      
      // Sort by time
      availableSlots.sort((a, b) {
        final aTime = _parseTime(a.time);
        final bTime = _parseTime(b.time);
        return aTime.compareTo(bTime);
      });
      
      return availableSlots;
    }
    
    return events.map((event) => TimeSlot(event.time, event.status)).toList();
  }

  List<DateTime> _generateTimeSlots() {
    List<DateTime> slots = [];
    final now = DateTime.now();
    
    // Generate time slots from 8 AM to 8 PM in 30-minute intervals
    for (int hour = 8; hour <= 20; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 20 && minute > 0) break; // Stop at 8:00 PM
        slots.add(DateTime(now.year, now.month, now.day, hour, minute));
      }
    }
    
    return slots;
  }

  int _getSelectedSlotsCount() {
    return _selectedAvailabilitySlots.length;
  }

  Widget _buildLegend(String label, Color color) {
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
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getSlotColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.lightBlue;
      case 'Pending':
        return Colors.blue[600]!;
      case 'Booked':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getSlotTextColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.lightBlue[700]!;
      case 'Pending':
        return Colors.blue[600]!;
      case 'Booked':
        return Colors.indigo[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  DateTime _parseTime(String timeStr) {
    // Parse time string like "2:00 PM" to DateTime
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1] == 'PM';
    
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    
    final now = _selectedDay ?? DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  void _selectCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select a custom time to request',
    );
    
    if (picked != null) {
      setState(() {
        final now = _selectedDay ?? DateTime.now();
        _selectedTime = DateTime(
          now.year, now.month, now.day, 
          picked.hour, picked.minute
        );
        _isCustomTimeRequest = true;
      });
    }
  }

  void _selectCustomAvailabilityTime() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select start time for availability',
    );
    
    if (startTime != null && _selectedDay != null) {
      // Ask for duration
      final duration = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Availability Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How long will you be available?'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 45, 60, 90, 120].map((minutes) {
                  return ChoiceChip(
                    label: Text('$minutes min'),
                    selected: false,
                    onSelected: (selected) {
                      if (selected) {
                        Navigator.pop(context, minutes);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (duration != null) {
        setState(() {
          final customTime = DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
            startTime.hour,
            startTime.minute,
          );
          
          // Check if this time already exists
          final timeStr = _formatTime(customTime);
          final alreadyExists = _availabilitySlots.any((slot) =>
            slot.day == _formatDateForDatabase(_selectedDay!) &&
            slot.slotStart == timeStr
          );
          
          if (alreadyExists) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This time slot already exists'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (!_selectedAvailabilitySlots.any((slot) => 
            slot.hour == customTime.hour && slot.minute == customTime.minute)) {
            _selectedAvailabilitySlots.add(customTime);
          }
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateForDatabase(DateTime date) {
    // Format: YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Future<String?> _findAvailabilitySlot(DateTime date, String time) async {
    final dayStr = _formatDateForDatabase(date);
    
    print('DEBUG: Looking for availability slot on $dayStr at $time');
    
    // Get mentor's availability for this day
    final availableSlots = _availabilitySlots.where((slot) => 
      slot.day == dayStr && 
      slot.slotStart == time &&
      !slot.isBooked
    ).toList();
    
    if (availableSlots.isNotEmpty) {
      print('DEBUG: Found available slot: ${availableSlots.first.id}');
      return availableSlots.first.id; // This will be in format "docId_slot_0"
    }
    
    print('DEBUG: No available slot found for $dayStr at $time');
    return null;
  }
  
  String _createISODateTime(DateTime date, DateTime time) {
    // Combine date and time into a single DateTime and format as ISO
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return combined.toIso8601String();
  }
  
  void _showCopyAvailabilityDialog() {
    final selectedDays = <DateTime>[];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    final date = _selectedDay!.add(Duration(days: index + 1));
                    final isSelected = selectedDays.contains(date);
                    return FilterChip(
                      label: Text(_formatDate(date).split(',')[0]), // Show day name
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
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
                  final slots = _selectedAvailabilitySlots.map((time) {
                    return Availability(
                      id: _uuid.v4(),
                      mentorId: _authService.currentUser!.uid,
                      day: _formatDateForDatabase(date),
                      slotStart: _formatTime(time),
                      slotEnd: null,
                      isBooked: false,
                    );
                  }).toList();
                  
                  await _meetingService.createAvailability(slots);
                }
                
                // Refresh calendar
                await _loadCalendarData();
                
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
        ),
      ),
    );
  }

  void _showRemoveAvailabilityDialog(Availability slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${_formatDate(DateTime.parse(slot.day))}'),
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
            onPressed: () async {
              Navigator.pop(context);
              await _removeAvailabilitySlot(slot);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAvailabilitySlot(Availability slot) async {
    setState(() {
      _pendingOperations.add(slot.id);
    });

    try {
      // Use the new removeAvailabilitySlot method
      final success = await _meetingService.removeAvailabilitySlot(
        _authService.currentUser!.uid,
        slot.day,
        slot.slotStart,
      );

      if (success) {
        // Refresh calendar data
        await _loadCalendarData();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability slot removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove availability slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing slot: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _pendingOperations.remove(slot.id);
      });
    }
  }

  void _scheduleMeeting() async {
    // Different validation for availability vs meeting
    if (widget.isMentor && _isSettingAvailability) {
      // Validate availability setting
      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }
      
      if (_selectedAvailabilitySlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one time slot')),
        );
        return;
      }
    } else {
      // Validate meeting scheduling
      if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a meeting title')),
        );
        return;
      }
      
      if (_selectedMenteeOrMentor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isMentor 
                ? 'Please select a mentee' 
                : 'Please select a mentor'
            ),
          ),
        );
        return;
      }
      
      if (_selectedDay == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }
    }
    
    if (!widget.isMentor || !_isSettingAvailability) {
      if (_locationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _meetingType == 'in-person' 
                ? 'Please enter a location' 
                : 'Please enter a meeting link'
            ),
          ),
        );
        return;
      }
    }
    
    setState(() {
      _isSavingData = true;
    });
    
    try {
      if (widget.isMentor && _isSettingAvailability) {
        // Set availability
        final slots = _selectedAvailabilitySlots.map((time) {
          return Availability(
            id: _uuid.v4(),
            mentorId: _authService.currentUser!.uid,
            day: _formatDateForDatabase(_selectedDay!),
            slotStart: _formatTime(time),
            slotEnd: null, // 30 minute slots by default
            isBooked: false,
          );
        }).toList();
        
        await _meetingService.createAvailability(slots);
      } else {
        // Schedule meeting
        String mentorId;
        String menteeId;
        
        if (widget.isMentor) {
          // Mentor is scheduling - use current user as mentor and selected mentee
          mentorId = _authService.currentUser!.uid;
          menteeId = _selectedMenteeOrMentor!['firebase_uid'] ?? _selectedMenteeOrMentor!['id'];
          
          // Find availability slot for this time
          final availabilityId = await _findAvailabilitySlot(_selectedDay!, _formatTime(_selectedTime!));
          
          if (availabilityId == null && !_isSettingAvailability) {
            // This time is not in mentor's availability
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a time from your available slots'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {
              _isSavingData = false;
            });
            return;
          }
          
          // Create meeting with availability ID
          final meeting = Meeting(
            id: _uuid.v4(),
            mentorId: mentorId,
            menteeId: menteeId,
            startTime: _createISODateTime(_selectedDay!, _selectedTime!),
            endTime: _createISODateTime(_selectedDay!, _selectedTime!.add(const Duration(minutes: 30))), // 30 min meeting
            topic: _titleController.text,
            location: _locationController.text,
            status: 'confirmed', // Since mentor is scheduling, it's auto-confirmed
            availabilityId: availabilityId, // This links to the availability slot
          );
          
          await _meetingService.createMeeting(meeting);
        } else {
          // Mentee is scheduling - use selected mentor and current user as mentee
          mentorId = _selectedMenteeOrMentor!['firebase_uid'] ?? _selectedMenteeOrMentor!['id'];
          menteeId = _authService.currentUser!.uid;
          
          if (_isCustomTimeRequest) {
            // Request custom meeting time
            await _meetingService.requestCustomMeeting(
              mentorId: mentorId,
              menteeId: menteeId,
              startTime: _createISODateTime(_selectedDay!, _selectedTime!),
              endTime: _createISODateTime(_selectedDay!, _selectedTime!.add(const Duration(minutes: 30))),
              topic: _titleController.text,
              location: _locationController.text,
            );
          } else {
            // Create regular meeting request
            final meeting = Meeting(
              id: _uuid.v4(),
              mentorId: mentorId,
              menteeId: menteeId,
              startTime: _createISODateTime(_selectedDay!, _selectedTime!),
              endTime: _createISODateTime(_selectedDay!, _selectedTime!.add(const Duration(minutes: 30))),
              topic: _titleController.text,
              location: _locationController.text,
              status: 'pending', // Mentee requests need mentor approval
            );
            
            await _meetingService.createMeeting(meeting);
          }
        }
      }
      
      // Refresh calendar data
      await _loadCalendarData();
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSavingData = false;
      });
      return;
    } finally {
      setState(() {
        _isSavingData = false;
      });
    }
    
    // Show success dialog
    final String dialogTitle = widget.isMentor 
      ? (_isSettingAvailability ? 'Availability Set' : 'Meeting Scheduled')
      : (_isCustomTimeRequest ? 'Meeting Request Sent' : 'Meeting Scheduled');
    
    final IconData dialogIcon = widget.isMentor || !_isCustomTimeRequest
      ? Icons.check_circle 
      : Icons.schedule_send;
    
    final Color dialogColor = widget.isMentor || !_isCustomTimeRequest
      ? Colors.lightBlue 
      : Colors.blue[600]!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            if (widget.isMentor && _isSettingAvailability) ...[
              Text(
                'Availability set for ${_formatDate(_selectedDay!)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Time slots: ${_selectedAvailabilitySlots.length}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedAvailabilitySlots.map((slot) => 
                  Chip(
                    label: Text(
                      _formatTime(slot),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.lightBlue.withOpacity(0.2),
                  )
                ).toList(),
              ),
            ] else ...[
              Text(
                _titleController.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('With: ${_selectedMenteeOrMentor?['name'] ?? 'Unknown'}'),
              Text('Date: ${_formatDate(_selectedDay!)}'),
              Text('Time: ${_formatTime(_selectedTime!)}'),
            ],
            if (_isCustomTimeRequest && !widget.isMentor) ...[
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
              'Location: ${_locationController.text}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (_repeatOption != 'none')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Repeats: ${_repeatOption.replaceAll('_', ' ')}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            if (!widget.isMentor && _isCustomTimeRequest) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
              Navigator.pop(context); // Close the success dialog only
              // Reset form and refresh data
              setState(() {
                _selectedAvailabilitySlots.clear();
                _selectedTime = null;
                _titleController.clear();
                _descriptionController.clear();
                _locationController.clear();
                _selectedMenteeOrMentor = null;
                _isCustomTimeRequest = false;
              });
              _loadCalendarData(); // Refresh the calendar
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class TimeSlot {
  final String time;
  final String status;
  
  TimeSlot(this.time, this.status);
}

class CalendarEvent {
  final String type;
  final String time;
  final String status;
  
  CalendarEvent({
    required this.type,
    required this.time, 
    required this.status,
  });
}