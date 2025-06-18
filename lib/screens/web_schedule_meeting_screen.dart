import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    
    print('🚀 === INIT STATE COMPLETE ===${'=' * 50}\n');
  }
  
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
    
    print('🌐 === SETUP REALTIME LISTENERS END ===${'=' * 50}\n');
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
              'firebase_uid': mentee['firebase_uid'] ?? '', // Don't use id as fallback here
              'name': mentee['name'] ?? 'Unknown',
              'program': mentee['program'] ?? '',
              'display': mentee['name'] ?? 'Unknown', // Just show name to avoid overflow
            };
          }).toList();
          
          print('DEBUG: Loaded ${_menteesList.length} mentees for mentor');
          for (var mentee in _menteesList) {
            print('DEBUG: Mentee loaded - id: ${mentee['id']}, name: ${mentee['name']}, firebase_uid: ${mentee['firebase_uid']}');
          }
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
      
      print('📆 Calling subscribeToMeetings with userId: $userId, isMentor: ${widget.isMentor}');
      _meetingService.subscribeToMeetings(userId, widget.isMentor);
      
      print('📆 ✅ Subscriptions setup complete');
      
      // TEMPORARY: Direct Firestore query to verify meetings exist
      print('\n🔍 DIRECT FIRESTORE TEST QUERY:');
      try {
        final testPath = 'california_merced_uc_merced/data/users';
        print('🔍 Checking path: $testPath');
        
        // First find the user document
        final userQuery = await FirebaseFirestore.instance
            .collection(testPath)
            .where('firebase_uid', isEqualTo: userId)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          final userDocId = userQuery.docs.first.id;
          print('🔍 Found user doc: $userDocId');
          
          // Then check meetings subcollection
          final meetingsTest = await FirebaseFirestore.instance
              .collection('$testPath/$userDocId/meetings')
              .get();
          
          print('🔍 Direct query found ${meetingsTest.docs.length} meetings');
          for (var doc in meetingsTest.docs) {
            final data = doc.data();
            print('  - ${doc.id}: ${data['topic']} on ${data['start_time']}');
          }
        } else {
          print('🔍 ⚠️ No user document found with firebase_uid: $userId');
        }
      } catch (testError) {
        print('🔍 ❌ Test query error: $testError');
      }
      
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
        final period = startTime.hour >= 12 ? 'PM' : 'AM';
        final timeStr = '${hour}:${startTime.minute.toString().padLeft(2, '0')} $period';
        
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
              child: Column(
                children: [
                  // Main row with calendar and meeting details
                  Row(
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
                                // Normalize the day to midnight for consistent comparison
                                final normalizedDay = DateTime(day.year, day.month, day.day);
                                final events = _calendarEvents[normalizedDay] ?? [];
                                
                                // Only log if there are events or if it's the selected day
                                if (events.isNotEmpty || (day.day == _selectedDay?.day && day.month == _selectedDay?.month && day.year == _selectedDay?.year)) {
                                  print('📅 EventLoader: ${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')} -> ${events.length} events');
                                  if (events.isNotEmpty) {
                                    for (var event in events) {
                                      print('   • ${event.time} - ${event.status} (${event.type})');
                                    }
                                  }
                                }
                                
                                return events;
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
                                  print('DEBUG: markerBuilder called for $day with ${events.length} events');
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
                            
                            // Show events for selected day
                            if (_selectedDay != null && _calendarEvents[_selectedDay!] != null && _calendarEvents[_selectedDay!]!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Events on ${_formatDate(_selectedDay!)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ..._calendarEvents[_selectedDay!]!.map((event) {
                                      Color dotColor = Colors.grey;
                                      IconData icon = Icons.circle;
                                      
                                      if (event.status == 'Available') {
                                        dotColor = Colors.lightBlue;
                                        icon = Icons.access_time;
                                      } else if (event.status == 'Pending') {
                                        dotColor = Colors.blue[600]!;
                                        icon = Icons.hourglass_empty;
                                      } else if (event.status == 'Booked') {
                                        dotColor = Colors.indigo;
                                        icon = Icons.check_circle;
                                      }
                                      
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(icon, size: 16, color: dotColor),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    event.time,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: dotColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        event.status,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: dotColor,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  if (event.type == 'meeting') ...[
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        'Meeting scheduled',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],
                            
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
                                  print('DEBUG: Dropdown onChanged triggered');
                                  print('DEBUG: Selected value: $value');
                                  print('DEBUG: Value type: ${value.runtimeType}');
                                  if (value != null) {
                                    print('DEBUG: Value id: ${value['id']}');
                                    print('DEBUG: Value name: ${value['name']}');
                                    print('DEBUG: Value firebase_uid: ${value['firebase_uid']}');
                                  }
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
                  
                  // Daily events section below calendar
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 24),
                    Card(
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
                                      'Schedule for ${_formatDate(_selectedDay!)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_calendarEvents[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]?.length ?? 0} events',
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
  
  Widget _buildDaySchedule() {
    final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final events = _calendarEvents[normalizedDay] ?? [];
    
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
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
              if (widget.isMentor && !_isSettingAvailability) ...[
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
    final meetings = events.where((e) => e.type == 'meeting').toList();
    final availableSlots = events.where((e) => e.type == 'available' || e.type == 'booked').toList();
    
    // Sort by time
    meetings.sort((a, b) => _parseTime(a.time).compareTo(_parseTime(b.time)));
    availableSlots.sort((a, b) => _parseTime(a.time).compareTo(_parseTime(b.time)));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meetings section
        if (meetings.isNotEmpty) ...[
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
            ],
          ),
          const SizedBox(height: 12),
          ...meetings.map((event) => _buildEventCard(event, true)),
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
      ],
    );
  }
  
  Widget _buildEventCard(CalendarEvent event, bool isMeeting) {
    Color cardColor;
    IconData icon;
    String subtitle = '';
    
    if (isMeeting) {
      cardColor = Colors.indigo;
      icon = Icons.videocam;
      // Find the actual meeting details
      final meetingTime = _parseTime(event.time);
      final meeting = _meetings.firstWhere(
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
      
      if (meeting.topic != null) {
        subtitle = meeting.topic!;
      }
      
      // Add mentee name if available
      if (widget.isMentor && meeting.menteeId.isNotEmpty) {
        final mentee = _menteesList.firstWhere(
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
          icon = Icons.event;
      }
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
            if (!isMeeting && event.status == 'Available' && !widget.isMentor) {
              // Mentee can select this time
              setState(() {
                _selectedTime = _parseTime(event.time);
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
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
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
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
                if (!isMeeting && event.status == 'Available' && widget.isMentor) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Remove this slot',
                    onPressed: () {
                      _showRemoveAvailabilityDialog(
                        _availabilitySlots.firstWhere(
                          (slot) => slot.slotStart == event.time && slot.day == _formatDateForDatabase(_selectedDay!),
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
          
          // Debug logging
          print('DEBUG: Selected mentee data: $_selectedMenteeOrMentor');
          print('DEBUG: Mentee id field: ${_selectedMenteeOrMentor?['id']}');
          print('DEBUG: Mentee firebase_uid field: ${_selectedMenteeOrMentor?['firebase_uid']}');
          
          // Use document ID as primary identifier (e.g., "Dasarathi_Narayanan")
          menteeId = _selectedMenteeOrMentor?['id'] ?? _selectedMenteeOrMentor?['firebase_uid'] ?? '';
          
          if (menteeId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
      
      // Also manually trigger a rebuild of calendar events in case streams are delayed
      setState(() {
        _buildCalendarEvents();
      });
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