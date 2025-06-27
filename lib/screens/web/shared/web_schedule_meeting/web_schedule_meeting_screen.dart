import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import 'package:smp_mentor_mentee_mobile_app/services/meeting/meeting_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/dashboard_data_service.dart';
import 'package:smp_mentor_mentee_mobile_app/models/availability.dart';
import 'package:smp_mentor_mentee_mobile_app/models/meeting.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:uuid/uuid.dart';

// Import widgets
import 'widgets/calendar_section.dart';
import 'widgets/time_slot_selector.dart';
import 'widgets/meeting_details_form.dart';
import 'widgets/day_schedule_view.dart';
import 'widgets/dialogs/copy_availability_dialog.dart';
import 'widgets/dialogs/remove_availability_dialog.dart';
import 'widgets/dialogs/success_dialog.dart';

// Import models and utils
import 'models/calendar_event.dart';
import 'models/time_slot.dart';
import 'utils/date_time_helpers.dart';
import 'utils/scheduling_constants.dart';

class WebScheduleMeetingScreen extends StatefulWidget {
  final bool isMentor;

  const WebScheduleMeetingScreen({    super.key,
    required this.isMentor,
  });

  @override
  State<WebScheduleMeetingScreen> createState() => _WebScheduleMeetingScreenState();
}

class _WebScheduleMeetingScreenState extends State<WebScheduleMeetingScreen> {
  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _selectedTime;
  List<DateTime> _selectedAvailabilitySlots = [];
  bool _isCustomTimeRequest = false;
  bool _isSettingAvailability = true;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  Map<String, dynamic>? _selectedMenteeOrMentor;
  String _meetingType = 'in-person';
  String _repeatOption = 'none';
  
  // Services
  final _meetingService = MeetingService();
  final _authService = AuthService();
  final _dashboardService = DashboardDataService();
  final _uuid = const Uuid();  
  // Data state
  List<Availability> _availabilitySlots = [];
  List<Meeting> _meetings = [];
  User? _currentUser;
  Map<String, dynamic>? _currentUserData;
  Map<DateTime, List<CalendarEvent>> _calendarEvents = {};
  bool _isLoadingData = false;
  bool _isSavingData = false;
  Set<String> _pendingOperations = {};
  List<Map<String, dynamic>> _menteesList = [];
  List<Map<String, dynamic>> _mentorsList = [];

  @override
  void initState() {
    super.initState();
    print('\n🚀 === WEB SCHEDULE MEETING SCREEN INIT ===${'=' * 50}');
    print('🚀 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🚀 Is Mentor: ${widget.isMentor}');
    print('🚀 Auth Service User: ${_authService.currentUser?.uid}');
    
    _selectedDay = _focusedDay;
    print('🚀 Selected day initialized: $_selectedDay');
    
    print('🚀 Calling _loadCurrentUser()...');
    _loadCurrentUser();
    
    print('🚀 Calling _setupRealtimeListeners()...');
    _setupRealtimeListeners();
    
    print('🚀 === INIT STATE COMPLETE ===${'=' * 50}\n');  }
  
  void _setupRealtimeListeners() {
    print('\n🌐 === SETUP REALTIME LISTENERS START ===${'=' * 50}');
    print('🌐 Timestamp: ${DateTime.now().toIso8601String()}');
    
    // Subscribe to real-time updates
    print('🌐 Setting up availability stream listener...');
    _meetingService.availabilityStream.listen((availability) {
      print('\n📍 === AVAILABILITY STREAM UPDATE ===${'=' * 50}');
      print('📍 Timestamp: ${DateTime.now().toIso8601String()}');
      print('📍 Mounted: $mounted');
      print('📍 Received ${availability.length} availability slots');
      
      if (mounted) {
        for (var i = 0; i < availability.length; i++) {
          final slot = availability[i];
          print('  ${i + 1}. Slot: ${slot.day} at ${slot.slotStart} - ${slot.isBooked ? "BOOKED" : "AVAILABLE"}');
        }
        
        print('📍 Calling setState to update availability...');
        setState(() {
          _availabilitySlots = availability;
          print('  - Availability slots updated: ${_availabilitySlots.length} slots');
          _buildCalendarEvents();
        });
      } else {
        print('📍 ⚠️ Widget not mounted, skipping update');
      }
      print('📍 === AVAILABILITY UPDATE END ===${'=' * 50}\n');
    });    
    print('🌐 Setting up meetings stream listener...');
    _meetingService.meetingsStream.listen((meetings) {
      print('\n📅 === MEETINGS STREAM UPDATE ===${'=' * 50}');
      print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
      print('📅 Mounted: $mounted');
      print('📅 Received ${meetings.length} meetings');
      
      if (mounted) {
        for (var i = 0; i < meetings.length; i++) {
          final meeting = meetings[i];
          print('  ${i + 1}. Meeting ${meeting.id}:');
          print('     - Topic: "${meeting.topic}"');
          print('     - Status: ${meeting.status}');
          print('     - Start: ${meeting.startTime}');
          print('     - Mentor: ${meeting.mentorId}');
          print('     - Mentee: ${meeting.menteeId}');
        }
        
        print('📅 Calling setState to update meetings...');
        setState(() {
          _meetings = meetings;
          print('  - Meetings updated: ${_meetings.length} meetings');
          _buildCalendarEvents();
        });
      } else {
        print('📅 ⚠️ Widget not mounted, skipping update');
      }
      print('📅 === MEETINGS UPDATE END ===${'=' * 50}\n');
    });
    
    print('🌐 === SETUP REALTIME LISTENERS END ===${'=' * 50}\n');  }
  
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
            return {
              'id': mentee['id'] ?? '',
              'firebase_uid': mentee['firebase_uid'] ?? '',
              'name': mentee['name'] ?? 'Unknown',
              'program': mentee['program'] ?? '',
              'display': mentee['name'] ?? 'Unknown',
            };          }).toList();
          
          print('DEBUG: Loaded ${_menteesList.length} mentees for mentor');
          for (var mentee in _menteesList) {
            print('DEBUG: Mentee loaded - id: ${mentee['id']}, name: ${mentee['name']}, firebase_uid: ${mentee['firebase_uid']}');
          }
        }
      });
      
      print('DEBUG: Loading calendar data for: ${_currentUserData?['name']}');
      
      // Subscribe to real-time updates for this user
      _meetingService.subscribeToAvailability(firebaseUser.uid);
      _meetingService.subscribeToMeetings(firebaseUser.uid);
      
      // Initial load is now triggered just to restore state
      await _loadCalendarData();
    } catch (e) {
      print('DEBUG: Error loading current user: $e');
    }
  }
  
  Future<void> _loadCalendarData() async {
    print('\n📆 === LOAD CALENDAR DATA START ===${'=' * 50}');
    print('📆 Timestamp: ${DateTime.now().toIso8601String()}');
    
    if (_authService.currentUser == null) {
      print('📆 ❌ No authenticated user found!');
      print('📆 === LOAD CALENDAR DATA END (NO USER) ===${'=' * 50}\n');
      return;
    }    
    final userId = _authService.currentUser!.uid;
    final userEmail = _authService.currentUser!.email;
    
    print('📆 Current user info:');
    print('  - Firebase UID: $userId');
    print('  - Email: $userEmail');
    print('  - Display name: ${_authService.currentUser!.displayName}');
    print('  - User data name: ${_currentUserData?['name']}');
    print('  - User data ID: ${_currentUserData?['id']}');
    print('  - Is Mentor: ${widget.isMentor}');
    
    // Preserve current selections before loading
    final preservedSelections = List<DateTime>.from(_selectedAvailabilitySlots);
    print('📆 Preserved ${preservedSelections.length} availability selections');
    
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      print('\n📆 Setting up subscriptions...');
      
      // Don't load data here as the stream will provide it
      // Just set up the subscriptions
      print('📆 Calling subscribeToAvailability with userId: $userId');
      _meetingService.subscribeToAvailability(userId);
      
      print('📆 Calling subscribeToMeetings with userId: $userId');
      _meetingService.subscribeToMeetings(userId);
            print('📆 ✅ Subscriptions setup complete');
      
      setState(() {
        _isLoadingData = false;
        
        // Restore selections if they haven't been saved yet
        if (widget.isMentor && _isSettingAvailability && _selectedDay != null) {
          // Only restore selections that aren't already saved in the database
          _selectedAvailabilitySlots = preservedSelections.where((slot) {
            final timeStr = DateTimeHelpers.formatTime(slot);
            return !_availabilitySlots.any((dbSlot) => 
              dbSlot.day == DateTimeHelpers.formatDateForDatabase(_selectedDay!) && 
              dbSlot.slotStart == timeStr
            );
          }).toList();
          print('📆 Restored ${_selectedAvailabilitySlots.length} unsaved selections');
        }
      });
    } catch (e) {
      print('📆 ❌ Error loading calendar data: $e');
      print('  - Error type: ${e.runtimeType}');
      setState(() {
        _isLoadingData = false;
        // Restore selections even on error
        if (widget.isMentor && _isSettingAvailability) {
          _selectedAvailabilitySlots = preservedSelections;
        }
      });
    }
    
    print('📆 === LOAD CALENDAR DATA END ===${'=' * 50}\n');
  }  
  void _buildCalendarEvents() {
    print('\n🎯 === BUILD CALENDAR EVENTS START ===${'=' * 50}');
    print('🎯 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🎯 Current state:');
    print('  - Availability slots: ${_availabilitySlots.length}');
    print('  - Meetings: ${_meetings.length}');
    print('  - Previous calendar events: ${_calendarEvents.length} days');
    
    _calendarEvents.clear();
    print('🎯 Calendar events cleared');
    
    // Debug meetings in detail
    if (_meetings.isNotEmpty) {
      print('\n🎯 MEETINGS DETAILS:');
      for (var i = 0; i < _meetings.length; i++) {
        final meeting = _meetings[i];
        print('  ${i + 1}. Meeting ${meeting.id}:');
        print('     - Topic: "${meeting.topic}"');
        print('     - Status: ${meeting.status}');
        print('     - Start Time: ${meeting.startTime}');
        print('     - End Time: ${meeting.endTime}');
        print('     - Location: ${meeting.location}');
        print('     - Mentor ID: ${meeting.mentorId}');
        print('     - Mentee ID: ${meeting.menteeId}');
        print('     - Availability ID: ${meeting.availabilityId}');
      }
    } else {
      print('\n🎯 ⚠️ NO MEETINGS TO DISPLAY');
    }
        // First, build a map of meetings by date and time for quick lookup
    final Map<String, Meeting> meetingsByDateTime = {};
    for (final meeting in _meetings) {
      final startTime = DateTime.tryParse(meeting.startTime);
      if (startTime != null) {
        final hour = startTime.hour > 12 ? startTime.hour - 12 : (startTime.hour == 0 ? 12 : startTime.hour);
        final period = startTime.hour >= 12 ? 'PM' : 'AM';
        final timeStr = '${hour}:${startTime.minute.toString().padLeft(2, '0')} $period';
        final dateKey = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
        meetingsByDateTime['$dateKey|$timeStr'] = meeting;
      }
    }
    
    // Add availability events
    print('\n🎯 PROCESSING AVAILABILITY SLOTS:');
    for (var i = 0; i < _availabilitySlots.length; i++) {
      final slot = _availabilitySlots[i];
      print('  ${i + 1}. Slot: day="${slot.day}", time="${slot.slotStart}", booked=${slot.isBooked}');
      
      final date = DateTime.tryParse(slot.day);
      if (date != null) {
        // Check if there's a meeting at this time
        final dateKey = slot.day; // Already in YYYY-MM-DD format
        final meetingKey = '$dateKey|${slot.slotStart}';
        final hasConflictingMeeting = meetingsByDateTime.containsKey(meetingKey);
        
        // Normalize date to remove time component for calendar comparison
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final events = _calendarEvents[normalizedDate] ?? [];        
        // Mark as booked if there's a meeting or if already booked
        final isBooked = slot.isBooked || hasConflictingMeeting;
        
        events.add(CalendarEvent(
          type: isBooked ? 'booked' : 'available',
          time: slot.slotStart,
          status: isBooked ? 'Booked' : 'Available',
        ));
        _calendarEvents[normalizedDate] = events;
        print('     ✅ Added to $normalizedDate${hasConflictingMeeting ? " (has meeting)" : ""}');
      } else {
        print('     ❌ Failed to parse date: ${slot.day}');
      }
    }
    
    // Add meeting events
    print('\n🎯 PROCESSING MEETINGS:');
    for (var i = 0; i < _meetings.length; i++) {
      final meeting = _meetings[i];
      print('  ${i + 1}. Meeting: startTime="${meeting.startTime}"');
      
      final startTime = DateTime.tryParse(meeting.startTime);
      if (startTime != null) {
        final date = DateTime(startTime.year, startTime.month, startTime.day);
        final events = _calendarEvents[date] ?? [];
        
        // Format time to match availability format (e.g., "3:00 PM")
        final hour = startTime.hour > 12 ? startTime.hour - 12 : (startTime.hour == 0 ? 12 : startTime.hour);
        final period = startTime.hour >= 12 ? 'PM' : 'AM';        final timeStr = '${hour}:${startTime.minute.toString().padLeft(2, '0')} $period';
        
        // Map meeting status to calendar status
        String calendarStatus;
        if (meeting.status == 'pending') {
          calendarStatus = 'Pending';
        } else if (meeting.status == 'confirmed' || meeting.status == 'accepted') {
          calendarStatus = 'Booked';
        } else if (meeting.status == 'cancelled') {
          print('     ⚠️ Skipping cancelled meeting');
          continue; // Skip cancelled meetings
        } else {
          calendarStatus = 'Booked'; // Default for other statuses
        }
        
        events.add(CalendarEvent(
          type: 'meeting',
          time: timeStr,
          status: calendarStatus,
        ));
        _calendarEvents[date] = events;
        print('     ✅ Added to $date: "${meeting.topic}" at $timeStr (${calendarStatus})');
      } else {
        print('     ❌ Failed to parse start time: ${meeting.startTime}');
      }
    }
    
    // Final summary
    print('\n🎯 CALENDAR EVENTS SUMMARY:');
    print('  - Total days with events: ${_calendarEvents.length}');
        final sortedDates = _calendarEvents.keys.toList()..sort();
    for (final date in sortedDates) {
      final events = _calendarEvents[date]!;
      print('  - ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}: ${events.length} events');
      for (final event in events) {
        print('    • ${event.time} - ${event.status} (${event.type})');
      }
    }
    
    print('🎯 === BUILD CALENDAR EVENTS END ===${'=' * 50}\n');
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
      appBar: _buildAppBar(),
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
                  child: Column(
                    children: [
                      // Main row with calendar and meeting details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calendar section
                          Expanded(
                            flex: isDesktop ? 5 : 1,
                            child: CalendarSection(
                              focusedDay: _focusedDay,
                              selectedDay: _selectedDay,
                              calendarFormat: _calendarFormat,
                              calendarEvents: _calendarEvents,                              onDaySelected: (selectedDay, focusedDay) {
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
                              onRefresh: _loadCalendarData,
                            ),
                          ),
                          
                          if (isDesktop || isTablet)
                            const SizedBox(width: 24),
                          
                          // Meeting details section
                          Expanded(
                            flex: isDesktop ? 4 : 1,
                            child: Column(
                              children: [
                                // Time slot selector
                                TimeSlotSelector(
                                  isMentor: widget.isMentor,
                                  isSettingAvailability: _isSettingAvailability,
                                  selectedDay: _selectedDay,
                                  selectedTime: _selectedTime,
                                  selectedAvailabilitySlots: _selectedAvailabilitySlots,
                                  timeSlots: _getTimeSlots(),
                                  availabilitySlots: _availabilitySlots,
                                  isCustomTimeRequest: _isCustomTimeRequest,
                                  pendingOperations: _pendingOperations,
                                  onTimeSelected: (time) {
                                    setState(() {
                                      _selectedTime = time;
                                      _isCustomTimeRequest = false;
                                    });
                                  },
                                  onAvailabilitySlotToggle: (time) {
                                    setState(() {
                                      if (_selectedAvailabilitySlots.any((slot) => 
                                        slot.hour == time.hour && slot.minute == time.minute)) {
                                        _selectedAvailabilitySlots.removeWhere((slot) => 
                                          slot.hour == time.hour && slot.minute == time.minute);
                                      } else {
                                        _selectedAvailabilitySlots.add(time);
                                      }
                                    });
                                  },
                                  onRemoveAvailability: _showRemoveAvailabilityDialog,
                                  onCustomTimePressed: _selectCustomTime,
                                  onCustomAvailabilityTimePressed: _selectCustomAvailabilityTime,
                                ),
                                const SizedBox(height: 24),
                                // Meeting details form
                                MeetingDetailsForm(
                                  isMentor: widget.isMentor,
                                  isSettingAvailability: _isSettingAvailability,
                                  titleController: _titleController,
                                  descriptionController: _descriptionController,
                                  locationController: _locationController,
                                  selectedMenteeOrMentor: _selectedMenteeOrMentor,
                                  menteesList: _menteesList,
                                  mentorsList: _mentorsList,
                                  meetingType: _meetingType,
                                  repeatOption: _repeatOption,
                                  selectedDay: _selectedDay,
                                  selectedTime: _selectedTime,
                                  availabilitySlots: _availabilitySlots,
                                  selectedSlotsCount: _selectedAvailabilitySlots.length,
                                  isSavingData: _isSavingData,                                  onMenteeOrMentorChanged: (value) {
                                    setState(() {
                                      _selectedMenteeOrMentor = value;
                                    });
                                  },
                                  onMeetingTypeChanged: (value) {
                                    setState(() {
                                      _meetingType = value;
                                    });
                                  },
                                  onRepeatOptionChanged: (value) {
                                    setState(() {
                                      _repeatOption = value;
                                    });
                                  },
                                  onSelectAll: () {
                                    setState(() {
                                      _selectedAvailabilitySlots = List.from(DateTimeHelpers.generateTimeSlots());
                                    });
                                  },
                                  onClearAll: () {
                                    setState(() {
                                      _selectedAvailabilitySlots.clear();
                                    });
                                  },
                                  onCopyToOtherDays: _showCopyAvailabilityDialog,
                                  onClear: () {
                                    setState(() {
                                      _selectedAvailabilitySlots.clear();
                                      _selectedTime = null;                                      _titleController.clear();
                                      _descriptionController.clear();
                                      _locationController.clear();
                                      _selectedMenteeOrMentor = null;
                                      _isCustomTimeRequest = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Form cleared'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  onSchedule: _scheduleMeeting,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Daily events section below calendar
                      if (_selectedDay != null) ...[
                        const SizedBox(height: 24),
                        DayScheduleView(
                          selectedDay: _selectedDay,
                          calendarEvents: _calendarEvents,
                          meetings: _meetings,
                          menteesList: _menteesList,                          isMentor: widget.isMentor,
                          isSettingAvailability: _isSettingAvailability,
                          availabilitySlots: _availabilitySlots,
                          onTimeSelected: (time) {
                            setState(() {
                              _selectedTime = time;
                            });
                          },
                          onRemoveAvailability: _showRemoveAvailabilityDialog,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.isMentor 
        ? (_isSettingAvailability ? 'Set Your Availability' : 'Schedule Meeting with Mentee')
        : 'Request Meeting with Mentor'),
      backgroundColor: const Color(0xFF0F2D52),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: widget.isMentor ? [
        Padding(          padding: const EdgeInsets.only(right: 16.0),
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
                }                return Colors.transparent;
              }),
              foregroundColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
        ),
      ] : null,
    );
  }

  List<TimeSlot> _getTimeSlots() {
    if (_selectedDay == null) return [];
    
    final events = _calendarEvents[_selectedDay!] ?? [];
    
    if (widget.isMentor && _isSettingAvailability) {
      // For mentors setting availability, show all time slots
      // and mark which ones are already set as available
      final allSlots = DateTimeHelpers.generateTimeSlots();
      
      return allSlots.map((time) {
        final timeStr = DateTimeHelpers.formatTime(time);
        // Check if this time slot already exists in events (meaning it's already saved)
        final existingEvent = events.firstWhere(
          (event) => event.time == timeStr,
          orElse: () => CalendarEvent(type: 'available', time: timeStr, status: 'Not Set'),
        );
        
        // If it exists in events, it's already saved as available
        return TimeSlot(timeStr, existingEvent.status == 'Available' ? 'Already Set' : 'Not Set');
      }).toList();    } else if (widget.isMentor && !_isSettingAvailability) {
      // For mentors scheduling meetings, only show their available (not booked) times
      final dayStr = DateTimeHelpers.formatDateForDatabase(_selectedDay!);
      final availableSlots = _availabilitySlots.where((slot) =>
        slot.day == dayStr &&
        !slot.isBooked
      ).map((slot) => TimeSlot(slot.slotStart, 'Available')).toList();
      
      // Sort by time
      availableSlots.sort((a, b) {
        final aTime = DateTimeHelpers.parseTime(a.time, _selectedDay);
        final bTime = DateTimeHelpers.parseTime(b.time, _selectedDay);
        return aTime.compareTo(bTime);
      });
      
      return availableSlots;
    }
    
    return events.map((event) => TimeSlot(event.time, event.status)).toList();
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
                children: [30, 45, 60, 90, 120].map((minutes) {                  return ChoiceChip(
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
          final timeStr = DateTimeHelpers.formatTime(customTime);
          final alreadyExists = _availabilitySlots.any((slot) =>
            slot.day == DateTimeHelpers.formatDateForDatabase(_selectedDay!) &&
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

  void _showCopyAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => CopyAvailabilityDialog(
        selectedDay: _selectedDay!,
        selectedAvailabilitySlots: _selectedAvailabilitySlots,
        meetingService: _meetingService,
        authService: _authService,        onComplete: _loadCalendarData,
      ),
    );
  }

  void _showRemoveAvailabilityDialog(Availability slot) {
    showDialog(
      context: context,
      builder: (context) => RemoveAvailabilityDialog(
        slot: slot,
        onConfirm: () => _removeAvailabilitySlot(slot),
      ),
    );
  }

  Future<void> _removeAvailabilitySlot(Availability slot) async {
    setState(() {
      _pendingOperations.add(slot.id);
    });

    try {
      // Use the new removeAvailabilitySlot method
      final success = await _meetingService.removeAvailabilitySlot(slot.id);

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
  Future<String?> _findAvailabilitySlot(DateTime date, String time) async {
    final dayStr = DateTimeHelpers.formatDateForDatabase(date);
    
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

  void _scheduleMeeting() async {
    // Different validation for availability vs meeting
    if (widget.isMentor && _isSettingAvailability) {
      // Validate availability setting
      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;      }
      
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
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isSavingData = false;
        });
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
        final slots = _selectedAvailabilitySlots.map((time) {          return Availability(
            id: _uuid.v4(),
            mentorId: _authService.currentUser!.uid,
            day: DateTimeHelpers.formatDateForDatabase(_selectedDay!),
            slotStart: DateTimeHelpers.formatTime(time),
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
          
          // Debug logging
          print('DEBUG: Selected mentee data: $_selectedMenteeOrMentor');
          print('DEBUG: Mentee id field: ${_selectedMenteeOrMentor?['id']}');
          print('DEBUG: Mentee firebase_uid field: ${_selectedMenteeOrMentor?['firebase_uid']}');
          
          // Use document ID as primary identifier (e.g., "Dasarathi_Narayanan")
          menteeId = _selectedMenteeOrMentor?['id'] ?? _selectedMenteeOrMentor?['firebase_uid'] ?? '';
          
          if (menteeId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(              const SnackBar(
                content: Text('Please select a mentee to schedule a meeting'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSavingData = false;
            });
            return;
          }
          
          print('DEBUG: Final menteeId being used: $menteeId');
          
          // Find availability slot for this time
          final availabilityId = await _findAvailabilitySlot(_selectedDay!, DateTimeHelpers.formatTime(_selectedTime!));
          
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
            startTime: DateTimeHelpers.createISODateTime(_selectedDay!, _selectedTime!),
            endTime: DateTimeHelpers.createISODateTime(_selectedDay!, _selectedTime!.add(const Duration(minutes: 30))), // 30 min meeting
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
            final meeting = Meeting(
              id: _uuid.v4(),
              mentorId: mentorId,
              menteeId: menteeId,
              startTime: DateTimeHelpers.createISODateTime(_selectedDay!, _selectedTime!),
              endTime: DateTimeHelpers.createISODateTime(_selectedDay!, _selectedTime!.add(const Duration(minutes: 30))),
              topic: _titleController.text,
              location: _locationController.text,
              status: 'pending',
              synced: false,
            );
            await _meetingService.createMeeting(meeting);
          } else {            // Create regular meeting request
            final meeting = Meeting(
              id: _uuid.v4(),
              mentorId: mentorId,
              menteeId: menteeId,
              startTime: DateTimeHelpers.createISODateTime(_selectedDay!, _selectedTime!),
              endTime: DateTimeHelpers.createISODateTime(_selectedDay!, _selectedTime!.add(const Duration(minutes: 30))),
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
      
      // Also manually trigger a rebuild of calendar events in case streams are delayed
      setState(() {
        _buildCalendarEvents();
      });
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,        ),
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
    showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        isMentor: widget.isMentor,
        isSettingAvailability: _isSettingAvailability,
        isCustomTimeRequest: _isCustomTimeRequest,
        selectedDay: _selectedDay,
        selectedTime: _selectedTime,
        selectedAvailabilitySlots: _selectedAvailabilitySlots,
        selectedMenteeOrMentor: _selectedMenteeOrMentor,
        title: _titleController.text,
        location: _locationController.text,
        repeatOption: _repeatOption,
        onDone: () {
          // Reset form and refresh data
          setState(() {
            _selectedAvailabilitySlots.clear();            _selectedTime = null;
            _titleController.clear();
            _descriptionController.clear();
            _locationController.clear();
            _selectedMenteeOrMentor = null;
            _isCustomTimeRequest = false;
          });
          _loadCalendarData(); // Refresh the calendar
        },
      ),
    );
  }
}