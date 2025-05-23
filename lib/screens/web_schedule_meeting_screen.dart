import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/responsive.dart';

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
  String? _selectedMenteeOrMentor;
  String _meetingType = 'in-person';
  String _repeatOption = 'none';
  
  // Mock data for mentees/mentors
  final List<String> mentees = [
    'Alice Johnson - 1st Year, Biology Major',
    'Bob Wilson - 2nd Year, Psychology Major',
    'Carlos Rodriguez - 1st Year, Engineering',
  ];
  
  final List<String> mentors = [
    'Sarah Martinez - 3rd Year, Computer Science Major',
  ];
  
  // Mock mentor availability data
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
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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
      body: SingleChildScrollView(
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
                            const Text(
                              'Select Date',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TableCalendar(
                              firstDay: DateTime.now(),
                              lastDay: DateTime.now().add(const Duration(days: 365)),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
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
                              calendarStyle: CalendarStyle(
                                selectedDecoration: const BoxDecoration(
                                  color: Color(0xFF0F2D52),
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: const Color(0xFF0F2D52).withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
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
                                        ? 'Green slots show your available times. You can schedule meetings during these times or add new ones.'
                                        : 'Green slots show when your mentor is available. You can also request a custom time if needed.',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildLegend('Available', Colors.green),
                                        const SizedBox(width: 16),
                                        _buildLegend('Pending', Colors.orange),
                                        const SizedBox(width: 16),
                                        _buildLegend('Booked', Colors.red),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.isMentor && _isSettingAvailability) ...[
                                  // Multiple selection for availability
                                  ..._generateTimeSlots().map((time) {
                                    final isSelected = _selectedAvailabilitySlots.any(
                                      (slot) => slot.hour == time.hour && slot.minute == time.minute
                                    );
                                    return FilterChip(
                                      label: Text(_formatTime(time)),
                                      selected: isSelected,
                                      selectedColor: Colors.green,
                                      checkmarkColor: Colors.white,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedAvailabilitySlots.add(time);
                                          } else {
                                            _selectedAvailabilitySlots.removeWhere(
                                              (slot) => slot.hour == time.hour && slot.minute == time.minute
                                            );
                                          }
                                        });
                                      },
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
                                    
                                    return ChoiceChip(
                                      label: Text(
                                        slot.time,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : textColor,
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
                              DropdownButtonFormField<String>(
                                value: _selectedMenteeOrMentor,
                                decoration: InputDecoration(
                                  labelText: widget.isMentor ? 'Select Mentee' : 'Select Mentor',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.person),
                                ),
                                items: (widget.isMentor ? mentees : mentors).map((person) {
                                  return DropdownMenuItem(
                                    value: person,
                                    child: Text(person),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMenteeOrMentor = value;
                                  });
                                },
                              ),
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
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _scheduleMeeting,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F2D52),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Text(widget.isMentor 
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
    if (widget.isMentor) {
      // For mentors, show all time slots as available
      return _generateTimeSlots().map((time) => 
        TimeSlot(_formatTime(time), 'Available')).toList();
    } else {
      // For mentees, show mentor's availability
      if (_selectedDay != null) {
        final dateKey = _selectedDay!.toString().split(' ')[0];
        return mentorAvailability[dateKey] ?? [];
      }
      return [];
    }
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
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Booked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSlotTextColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green[700]!;
      case 'Pending':
        return Colors.orange[700]!;
      case 'Booked':
        return Colors.red[700]!;
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

  void _scheduleMeeting() {
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
    
    // TODO: Save meeting to database
    
    // Show success dialog
    final String dialogTitle = widget.isMentor 
      ? (_isSettingAvailability ? 'Availability Set' : 'Meeting Scheduled')
      : (_isCustomTimeRequest ? 'Meeting Request Sent' : 'Meeting Scheduled');
    
    final IconData dialogIcon = widget.isMentor || !_isCustomTimeRequest
      ? Icons.check_circle 
      : Icons.schedule_send;
    
    final Color dialogColor = widget.isMentor || !_isCustomTimeRequest
      ? Colors.green 
      : Colors.orange;
    
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
                    backgroundColor: Colors.green.withOpacity(0.2),
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
              Text('With: $_selectedMenteeOrMentor'),
              Text('Date: ${_formatDate(_selectedDay!)}'),
              Text('Time: ${_formatTime(_selectedTime!)}'),
            ],
            if (_isCustomTimeRequest && !widget.isMentor) ...[
              const SizedBox(height: 4),
              const Text(
                '(Custom time - pending approval)',
                style: TextStyle(
                  color: Colors.orange,
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
              Navigator.pop(context);
              Navigator.pop(context);
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