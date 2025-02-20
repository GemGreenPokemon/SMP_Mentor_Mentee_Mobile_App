import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'schedule_meeting_screen.dart';
import 'meeting_notes_screen.dart';
import 'progress_reports_screen.dart';
import 'resource_hub_screen.dart';
import 'settings_screen.dart';
import 'checklist_screen.dart';
import '../services/mentor_service.dart';

class MentorDashboardScreen extends StatelessWidget {
  const MentorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'Message Coordinator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatScreen(
                    recipientName: 'Clarissa Correa',
                    recipientRole: 'SMP Program Coordinator',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(isMentor: true),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Notifications'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.notification_important, color: Colors.red),
                        title: Text('New Progress Report Due'),
                        subtitle: Text('Due in 2 days'),
                      ),
                      ListTile(
                        leading: Icon(Icons.event, color: Colors.blue),
                        title: Text('Upcoming Meeting'),
                        subtitle: Text('Tomorrow at 2:00 PM'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Mentees Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Mentees',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Available Mentees'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: const Text('Michael Brown'),
                            subtitle: const Text('1st Year, Computer Science'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                mentorService.addMentee({
                                  'name': 'Michael Brown',
                                  'program': '1st Year, Computer Science',
                                  'lastMeeting': 'Not met yet',
                                  'progress': 0.0,
                                  'assignedBy': 'You',
                                  'goals': [],
                                  'upcomingMeetings': [],
                                  'actionItems': [],
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('New mentee added successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text('Select'),
                            ),
                          ),
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: const Text('Lisa Chen'),
                            subtitle: const Text('2nd Year, Biology'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                mentorService.addMentee({
                                  'name': 'Lisa Chen',
                                  'program': '2nd Year, Biology',
                                  'lastMeeting': 'Not met yet',
                                  'progress': 0.0,
                                  'assignedBy': 'You',
                                  'goals': [],
                                  'upcomingMeetings': [],
                                  'actionItems': [],
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('New mentee added successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text('Select'),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Select Mentee'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mentee Cards
          ...mentorService.mentees.map((mentee) => Column(
            children: [
              _buildMenteeCard(
                context,
                mentee['name'],
                mentee['program'],
                mentee['lastMeeting'],
                mentee['progress'],
                mentee['assignedBy'],
                mentorService,
              ),
              const SizedBox(height: 12),
            ],
          )).toList(),

          // Announcements Card
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
                        'Announcements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all announcements
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('All Announcements'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: mentorService.announcements.map((announcement) =>
                                    _buildAnnouncementItem(
                                      announcement['title'],
                                      announcement['content'],
                                      announcement['time'],
                                    ),
                                  ).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...mentorService.announcements.take(2).map((announcement) =>
                    _buildAnnouncementItem(
                      announcement['title'],
                      announcement['content'],
                      announcement['time'],
                    ),
                  ).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                context,
                'Schedule Meetings',
                Icons.calendar_today,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleMeetingScreen(isMentor: true),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                'Meeting Notes',
                Icons.note_add,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeetingNotesScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                'Resources Hub',
                Icons.folder_shared,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResourceHubScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                'Progress Reports',
                Icons.assessment,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgressReportsScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                'Assign Check List',
                Icons.checklist_rtl,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChecklistScreen(isMentor: true),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Today's Schedule
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
                        'Today\'s Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScheduleMeetingScreen(isMentor: true),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...mentorService.mentees.expand((mentee) => 
                    mentee['upcomingMeetings'].map((meeting) =>
                      _buildScheduleItem(
                        context,
                        '${meeting['title']} with ${mentee['name']}',
                        meeting['time'],
                        meeting['isNext'],
                        mentorService,
                        mentee['name'],
                        meeting['title'],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Items Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...mentorService.mentees.expand((mentee) =>
                    mentee['actionItems'].where((item) => !item['completed']).map((item) =>
                      _buildActionItem(
                        context,
                        item['task'],
                        item['dueDate'],
                        Icons.assignment,
                        mentorService,
                        mentee['name'],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_task),
                  title: const Text('Add Action Item'),
                  onTap: () {
                    Navigator.pop(context);
                    // Show add action item dialog
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.announcement),
                  title: const Text('Create Announcement'),
                  onTap: () {
                    Navigator.pop(context);
                    // Show create announcement dialog
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_note),
                  title: const Text('Schedule Meeting'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleMeetingScreen(isMentor: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenteeCard(
    BuildContext context,
    String name,
    String program,
    String lastMeeting,
    double progress,
    String assignedBy,
    MentorService mentorService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        program,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              assignedBy,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          recipientName: name,
                          recipientRole: program,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lastMeeting,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String title,
    String time,
    bool isNext,
    MentorService mentorService,
    String menteeName,
    String meetingTitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isNext ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Location: KL 109',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isNext)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Meeting Check-In/Out'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Please verify:'),
                              const SizedBox(height: 8),
                              const Text('• You are with your mentee'),
                              const Text('• You are at the correct location'),
                              const Text('• The meeting is starting/ending now'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Record check-in/out time
                                Navigator.of(context).pop();
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Check In/Out'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String deadline,
    IconData icon,
    MentorService mentorService,
    String menteeName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  deadline,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditItemDialog(
                    context,
                    title,
                    '',
                    (title, description) {
                      mentorService.updateActionItem(
                        menteeName,
                        title,
                        description,
                      );
                    },
                  );
                },
                constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  mentorService.removeActionItem(
                    menteeName,
                    title,
                  );
                },
                constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String content, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    String currentTitle,
    String currentDescription,
    Function(String, String) onSave,
  ) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController(text: currentTitle);
    final _descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Action Item'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description cannot be empty';
                  }
                  return null;
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
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                onSave(_titleController.text, _descriptionController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 