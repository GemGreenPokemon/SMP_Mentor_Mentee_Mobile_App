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
        title: const Text('Schedule Meeting'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
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
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _generateTimeSlots().map((time) {
                                final isSelected = _selectedTime?.hour == time.hour && 
                                                 _selectedTime?.minute == time.minute;
                                return ChoiceChip(
                                  label: Text(
                                    _formatTime(time),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0F2D52),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedTime = selected ? time : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
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
                            const Text(
                              'Meeting Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Meeting title
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
                                    child: const Text('Schedule Meeting'),
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
    // Validate inputs
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
    
    // TODO: Save meeting to database
    
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Meeting Scheduled'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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