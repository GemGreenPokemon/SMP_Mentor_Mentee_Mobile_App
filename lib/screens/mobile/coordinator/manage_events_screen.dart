import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/mentor_service.dart';
import 'package:intl/intl.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Mentors', 'Mentees', 'Both'];

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    final events = mentorService.events;

    // Filter events based on selected filter
    final filteredEvents = _selectedFilter == 'All'
        ? events
        : events.where((e) => e['audience'] == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chip section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFilter = filter;
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Events list
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(
                    child: Text(
                      'No events found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      // Find the original index in the unfiltered list
                      final originalIndex = events.indexOf(event);
                      return _buildEventCard(
                        context,
                        event,
                        originalIndex,
                        mentorService,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(context, mentorService);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Event',
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Map<String, dynamic> event,
    int index,
    MentorService mentorService,
  ) {
    // Set audience badge color
    Color audienceColor;
    String audienceText;

    switch (event['audience']) {
      case 'mentors':
        audienceColor = Colors.blue;
        audienceText = 'MENTORS ONLY';
        break;
      case 'mentees':
        audienceColor = Colors.green;
        audienceText = 'MENTEES ONLY';
        break;
      case 'both':
        audienceColor = Colors.purple;
        audienceText = 'ALL PARTICIPANTS';
        break;
      default:
        audienceColor = Colors.grey;
        audienceText = 'UNDEFINED';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: audienceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: audienceColor,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    audienceText,
                    style: TextStyle(
                      color: audienceColor,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${event['registeredCount']} Registered',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              event['title'],
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  event['date'],
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  event['time'],
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  event['location'],
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              event['description'],
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Edit'),
                  onPressed: () {
                    _showEditEventDialog(
                      context,
                      event,
                      index,
                      mentorService,
                    );
                  },
                ),
                const SizedBox(width: 8.0),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 20),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmationDialog(
                      context,
                      event,
                      index,
                      mentorService,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(
    BuildContext context,
    MentorService mentorService,
  ) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final registeredCountController = TextEditingController(text: '0');
    
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
      hour: TimeOfDay.now().hour + 1,
      minute: TimeOfDay.now().minute,
    );
    
    String audience = 'both';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Start Time'),
                      subtitle: Text(startTime.format(context)),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            startTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('End Time'),
                      subtitle: Text(endTime.format(context)),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            endTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: registeredCountController,
                decoration: const InputDecoration(
                  labelText: 'Initial Registered Count',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Target Audience:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Both Mentors & Mentees'),
                        value: 'both',
                        groupValue: audience,
                        onChanged: (value) {
                          setState(() {
                            audience = value ?? 'both';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Mentors Only'),
                        value: 'mentors',
                        groupValue: audience,
                        onChanged: (value) {
                          setState(() {
                            audience = value ?? 'both';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Mentees Only'),
                        value: 'mentees',
                        groupValue: audience,
                        onChanged: (value) {
                          setState(() {
                            audience = value ?? 'both';
                          });
                        },
                      ),
                    ],
                  );
                },
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
            onPressed: () {
              if (titleController.text.isEmpty || 
                  descriptionController.text.isEmpty || 
                  locationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                  ),
                );
                return;
              }

              final timeString = '${startTime.format(context)} - ${endTime.format(context)}';
              
              final newEvent = {
                'title': titleController.text,
                'description': descriptionController.text,
                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                'time': timeString,
                'location': locationController.text,
                'audience': audience,
                'registeredCount': int.tryParse(registeredCountController.text) ?? 0,
              };

              mentorService.addEvent(newEvent);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event added successfully'),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(
    BuildContext context,
    Map<String, dynamic> event,
    int index,
    MentorService mentorService,
  ) {
    final titleController = TextEditingController(text: event['title']);
    final descriptionController = TextEditingController(text: event['description']);
    final locationController = TextEditingController(text: event['location']);
    final registeredCountController = TextEditingController(text: event['registeredCount'].toString());
    
    // Parse date
    DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(event['date']);
    
    // Parse time range
    final timeRange = event['time'].split(' - ');
    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(timeRange[0].split(':')[0]),
      minute: int.parse(timeRange[0].split(':')[1].split(' ')[0]),
    );
    TimeOfDay endTime = TimeOfDay(
      hour: int.parse(timeRange[1].split(':')[0]),
      minute: int.parse(timeRange[1].split(':')[1].split(' ')[0]),
    );
    
    String audience = event['audience'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Start Time'),
                      subtitle: Text(startTime.format(context)),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            startTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('End Time'),
                      subtitle: Text(endTime.format(context)),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            endTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: registeredCountController,
                decoration: const InputDecoration(
                  labelText: 'Registered Count',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Target Audience:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Both Mentors & Mentees'),
                        value: 'both',
                        groupValue: audience,
                        onChanged: (value) {
                          setState(() {
                            audience = value ?? 'both';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Mentors Only'),
                        value: 'mentors',
                        groupValue: audience,
                        onChanged: (value) {
                          setState(() {
                            audience = value ?? 'both';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Mentees Only'),
                        value: 'mentees',
                        groupValue: audience,
                        onChanged: (value) {
                          setState(() {
                            audience = value ?? 'both';
                          });
                        },
                      ),
                    ],
                  );
                },
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
            onPressed: () {
              if (titleController.text.isEmpty || 
                  descriptionController.text.isEmpty || 
                  locationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                  ),
                );
                return;
              }

              final timeString = '${startTime.format(context)} - ${endTime.format(context)}';
              
              final updatedEvent = {
                'title': titleController.text,
                'description': descriptionController.text,
                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                'time': timeString,
                'location': locationController.text,
                'audience': audience,
                'registeredCount': int.tryParse(registeredCountController.text) ?? 0,
              };

              mentorService.updateEvent(index, updatedEvent);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event updated successfully'),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> event,
    int index,
    MentorService mentorService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete the event "${event['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              mentorService.deleteEvent(index);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event deleted successfully'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 