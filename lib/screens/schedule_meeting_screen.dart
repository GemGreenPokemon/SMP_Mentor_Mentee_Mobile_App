import 'package:flutter/material.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  final bool isMentor;
  const ScheduleMeetingScreen({super.key, required this.isMentor});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  String selectedLocation = 'KL 109';
  bool isRecurring = false;
  int recurringWeeks = 4;

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

  List<MentorTimeSlot> getAvailableTimeSlots() {
    final dateKey = selectedDate.toString().split(' ')[0];
    // For mentors, initialize default slots if none exist
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
    // Return slots for the date (mentors use map, mentees see mentor's slots)
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
                            'Your mentor (Sarah Martinez) will need to approve your meeting request.',
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
                        label: Row(
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
                            ],
                          ],
                        ),
                        backgroundColor: getTimeSlotColor(slot.status),
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        onSelected: isAvailable ? (selected) {
                          setState(() {
                            selectedTime = selected ? slot.time : null;
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
                                  onPressed: () {
                                    // TODO: Save meeting/availability
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
      setState(() {
        mentorAvailability.putIfAbsent(key, () => []);
        mentorAvailability[key]!
            .add(MentorTimeSlot(picked.format(context), 'Available'));
      });
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

  MentorTimeSlot(this.time, this.status);
} 