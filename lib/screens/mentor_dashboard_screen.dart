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
import 'checkin_checkout_screen.dart';
import 'newsletter_screen.dart';
import 'announcement_screen.dart';
import '../utils/developer_session.dart';
import '../utils/test_mode_manager.dart';
import '../models/meeting.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  State<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize mentor service to load database data if in test mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mentorService = Provider.of<MentorService>(context, listen: false);
      mentorService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    // Show loading indicator while data is being loaded
    if (mentorService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mentor Dashboard'),
            Text(
              mentorService.mentorProfile['name'] ?? 'Mentor',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh the mentor service data
          await mentorService.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
          // Debug info in test mode
          if (TestModeManager.isTestMode && DeveloperSession.isActive)
            Card(
              color: Colors.yellow.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Mode Active',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Current Mentor: ${TestModeManager.currentTestMentor?.name} (${TestModeManager.currentTestMentor?.id})'),
                    Text('Current Mentee: ${TestModeManager.currentTestMentee?.name} (${TestModeManager.currentTestMentee?.id})'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
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
                mentee,
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
                          // Navigate to the AnnouncementScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnnouncementScreen(isCoordinator: false),
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
                      announcement['priority'],
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
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            // Increase height for dev labels to avoid overflow
            childAspectRatio: DeveloperSession.isActive ? 0.8 : 1.0,
            children: [
              _buildQuickActionCard(
                context,
                'Schedule Meetings',
                Icons.calendar_today,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleMeetingScreen(isMentor: true),
                    ),
                  );
                  // Refresh when returning from schedule screen
                  if (mounted) {
                    mentorService.refresh();
                  }
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
              _buildQuickActionCard(
                context,
                'Newsletters',
                Icons.newspaper_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewsletterScreen(isMentor: true),
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
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              final service = Provider.of<MentorService>(dialogContext, listen: false);
                              final todaysMeetings = service.mentees
                                  .expand((mentee) => (mentee['upcomingMeetings'] as List).map((meeting) => {
                                        ...meeting,
                                        'menteeName': mentee['name']
                                      }))
                                  .where((meeting) => meeting['date'] == 'Today') // Filter for 'Today'
                                  .toList();

                              return AlertDialog(
                                title: const Text("Today's Meetings"),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: todaysMeetings.isEmpty
                                      ? const Text('No meetings scheduled for today.')
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: todaysMeetings.length,
                                          itemBuilder: (context, index) {
                                            final meeting = todaysMeetings[index];
                                            return ListTile(
                                              leading: const Icon(Icons.event_available, color: Color(0xFF005487)),
                                              title: Text('${meeting['title']} with ${meeting['menteeName']}'),
                                              subtitle: Text('${meeting['time']} at ${meeting['location']}'),
                                            );
                                          },
                                        ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(); // Close the dialog
                                    },
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('View Full Schedule'), // Keep label, functionality changed
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
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleMeetingScreen(isMentor: true),
                      ),
                    );
                    // Refresh when returning from schedule screen
                    if (mounted) {
                      mentorService.refresh();
                    }
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
    Map<String, dynamic> mentee,
    MentorService mentorService,
  ) {
    final upcomingMeetings = mentee['upcomingMeetings'] as List<Map<String, dynamic>>? ?? [];
    final nextMeeting = upcomingMeetings.isNotEmpty ? upcomingMeetings.first : null;
    
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
                        mentee['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mentee['program'],
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
                              mentee['assignedBy'],
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
                // TODO: Retrieve and sync mentee list from Firestore via MentorService before caching locally.
                // TODO: Persist basic mentee info (name and unique ID) locally via MentorService (e.g., SQLite) for offline quick-access.
                // TODO: Ensure each mentee model includes an index or UUID to map to chat threads.
                // TODO: On tap, pass menteeID and menteeName to ChatScreen to load the correct conversation.
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          recipientName: mentee['name'],
                          recipientRole: mentee['program'],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mentee['lastMeeting'],
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            // Display next meeting if available
            if (nextMeeting != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 20,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next: ${nextMeeting['title']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            '${nextMeeting['date']} ${nextMeeting['time']} - ${nextMeeting['location']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (nextMeeting['isNext'] == true)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckInCheckOutScreen(
                                meetingTitle: nextMeeting['title'] ?? 'Meeting',
                                mentorName: 'You',
                                location: nextMeeting['location'] ?? 'TBD',
                                scheduledTime: '${nextMeeting['date']} ${nextMeeting['time']}',
                                isMentor: true,
                                meeting: null, // TODO: Pass actual meeting object
                              ),
                            ),
                          );
                        },
                        child: const Text('Check In'),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: mentee['progress'],
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(mentee['progress'] * 100).round()}%',
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
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (DeveloperSession.isActive) ...[
                const SizedBox(height: 4),
                const Text(
                  'Coming Soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
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
    String meetingTitle, {
    Meeting? meeting,
    String? location,
  }) {
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
                Text(
                  'Location: ${location ?? "KL 109"}',
                  style: const TextStyle(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckInCheckOutScreen(
                          meetingTitle: meetingTitle,
                          mentorName: 'You',
                          location: location ?? 'KL 109',
                          scheduledTime: time,
                          isMentor: true,
                          meeting: meeting,
                        ),
                      ),
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

  Widget _buildAnnouncementItem(String title, String content, String time, String? priority) {
    // Set priority color and text based on priority value
    Color priorityColor = Colors.blue;
    String priorityText = '';
    bool hasPriority = priority != null && priority != 'none';
    
    if (hasPriority) {
      switch (priority) {
        case 'high':
          priorityColor = Colors.red;
          priorityText = 'HIGH';
          break;
        case 'medium':
          priorityColor = Colors.orange;
          priorityText = 'MEDIUM';
          break;
        case 'low':
          priorityColor = Colors.green;
          priorityText = 'LOW';
          break;
        default:
          priorityColor = Colors.blue;
          priorityText = '';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPriority ? Icons.priority_high : Icons.campaign, 
                color: hasPriority ? priorityColor : const Color(0xFF2196F3)
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (hasPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: priorityColor,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          priorityText,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
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
} 