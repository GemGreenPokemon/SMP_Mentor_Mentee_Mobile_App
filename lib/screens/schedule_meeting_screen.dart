import 'package:flutter/material.dart';
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
  List<Meeting> _pendingMeetings = []; // Pending meeting requests
  Map<String, User> _menteeMap = {}; // Map of mentee IDs to User objects
  bool _isLoading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    if (TestModeManager.isTestMode) {
      try {
        // Get current user from test mode
        _currentUser = TestModeManager.currentTestUser;
        
        if (_currentUser != null) {
          if (widget.isMentor) {
            // Mentor viewing their own availability (both available and booked)
            _availabilities = await _localDb.getAvailabilityByMentor(_currentUser!.id);
            
            // Load pending meeting requests
            final allMeetings = await _localDb.getMeetingsByMentor(_currentUser!.id);
            _pendingMeetings = allMeetings.where((m) => m.status == 'pending').toList();
            
            // Load mentee information for pending meetings
            for (final meeting in _pendingMeetings) {
              final mentee = await _localDb.getUserById(meeting.menteeId);
              if (mentee != null) {
                _menteeMap[meeting.menteeId] = mentee;
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
        
        if (avail.isBooked) {
          status = 'Booked';
          // Find if there's a pending meeting for this slot
          final pendingMeeting = _pendingMeetings.firstWhere(
            (m) => m.availabilityId == avail.id,
            orElse: () => Meeting(id: '', mentorId: '', menteeId: '', startTime: '', createdAt: DateTime.now()),
          );
          
          if (pendingMeeting.id.isNotEmpty) {
            status = 'Pending Request';
            menteeName = _menteeMap[pendingMeeting.menteeId]?.name;
          } else if (avail.menteeId != null) {
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
                  CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    onDateChanged: (date) {
                      setState(() {
                        selectedDate = date;
                        selectedTime = null;
                      });
                    },
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
          if (widget.isMentor && _pendingMeetings.isNotEmpty)
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
                    ..._pendingMeetings.map((meeting) {
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
}

class MentorTimeSlot {
  final String time;
  final String status; // 'Available', 'Pending Request', or 'Booked'
  final String? availabilityId;
  final String? menteeName;

  MentorTimeSlot(this.time, this.status, {this.availabilityId, this.menteeName});
} 