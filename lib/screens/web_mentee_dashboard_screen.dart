import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'schedule_meeting_screen.dart';
import 'resource_hub_screen.dart';
import 'settings_screen.dart';
import 'mentee_checklist_screen.dart';
import 'checkin_checkout_screen.dart';
import 'meeting_notes_screen.dart';
import 'newsletter_screen.dart';
import 'announcement_screen.dart';
import '../services/mentor_service.dart';
import '../utils/responsive.dart';
import 'package:provider/provider.dart';

class WebMenteeDashboardScreen extends StatefulWidget {
  const WebMenteeDashboardScreen({super.key});

  @override
  State<WebMenteeDashboardScreen> createState() => _WebMenteeDashboardScreenState();
}

class _WebMenteeDashboardScreenState extends State<WebMenteeDashboardScreen> {
  int _selectedIndex = 0;
  
  final List<String> _sidebarItems = [
    'Dashboard',
    'Schedule',
    'Resources',
    'Checklist',
    'Meeting Notes',
    'Newsletters',
    'Announcements',
    'Settings',
  ];
  
  final List<IconData> _sidebarIcons = [
    Icons.dashboard,
    Icons.event_note,
    Icons.folder_open,
    Icons.check_circle_outline,
    Icons.note_alt,
    Icons.newspaper,
    Icons.campaign,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            child: SizedBox(
              width: 250,
              child: Column(
                children: [
                  // App logo and title
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    color: const Color(0xFF0F2D52),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/My_SMP_Logo.png',
                          height: 40,
                          width: 40,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SMP Mentee',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'John Smith',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Mentee',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Text('Edit Profile'),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'logout') {
                              Navigator.of(context).pushReplacementNamed('/');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Navigation menu
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: _sidebarItems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(
                            _sidebarIcons[index],
                            color: _selectedIndex == index
                                ? const Color(0xFF0F2D52)
                                : Colors.grey[600],
                          ),
                          title: Text(
                            _sidebarItems[index],
                            style: TextStyle(
                              fontWeight: _selectedIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedIndex == index
                                  ? const Color(0xFF0F2D52)
                                  : Colors.grey[800],
                            ),
                          ),
                          selected: _selectedIndex == index,
                          selectedTileColor: const Color(0xFF0F2D52).withOpacity(0.1),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            
                            // Handle navigation based on selection
                            if (index == 7) { // Settings
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(isMentor: false),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _sidebarItems[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // TODO: Implement search
                        },
                        tooltip: 'Search',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // TODO: Show notifications
                        },
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          // TODO: Show help
                        },
                        tooltip: 'Help',
                      ),
                    ],
                  ),
                ),
                
                // Main content - Dashboard only
                if (_selectedIndex == 0) // Dashboard
                  Expanded(
                    child: _buildDashboardContent(context, mentorService),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, MentorService mentorService) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row - Mentor card and Progress card
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mentor Info Card
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Mentor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 32,
                                child: Icon(Icons.person, size: 40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sarah Martinez',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '3rd Year, Computer Science Major',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Assigned since Feb 1, 2024',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.message),
                                          label: const Text('Message'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ChatScreen(
                                                  recipientName: 'Sarah Martinez',
                                                  recipientRole: '3rd Year, Computer Science Major',
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0F2D52),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.calendar_today),
                                          label: const Text('Schedule'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ScheduleMeetingScreen(isMentor: false),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Progress Card
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Checklist Completion',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: const LinearProgressIndicator(
                                              value: 0.7,
                                              minHeight: 8,
                                              backgroundColor: Color(0xFFE0E0E0),
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F2D52)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          '70%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Meeting Attendance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: const LinearProgressIndicator(
                                              value: 0.9,
                                              minHeight: 8,
                                              backgroundColor: Color(0xFFE0E0E0),
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2B9348)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          '90%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildActivityItem(
                            'Completed task "Review mentor feedback"',
                            '2 days ago',
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildActivityItem(
                            'Attended meeting "Weekly Check-in"',
                            '4 days ago',
                            Icons.event_available,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Middle row - Announcements and Upcoming Meetings
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Announcements Card
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
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
                          const SizedBox(height: 16),
                          _buildAnnouncementItem(
                            'Upcoming Workshop',
                            'Join us for a career development workshop next week. We\'ll be covering resume writing, interview skills, and networking strategies.',
                            '2 hours ago',
                            mentorService.announcements.isNotEmpty ? mentorService.announcements[0]['priority'] : null,
                          ),
                          const Divider(),
                          _buildAnnouncementItem(
                            'Program Update',
                            'New resources have been added to the resource hub including study guides and internship opportunities.',
                            '1 day ago',
                            mentorService.announcements.length > 1 ? mentorService.announcements[1]['priority'] : null,
                          ),
                          const Divider(),
                          _buildAnnouncementItem(
                            'End of Semester Survey',
                            'Please take a moment to complete the end of semester feedback survey.',
                            '3 days ago',
                            'medium',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Upcoming Meetings Card
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming Meetings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to all meetings
                                },
                                child: const Text('View Calendar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMeetingItem(
                            context,
                            'Weekly Check-in',
                            'Tomorrow at 2:00 PM',
                            'KL 109',
                            Colors.blue,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckInCheckOutScreen(
                                    meetingTitle: 'Weekly Check-in',
                                    mentorName: 'Sarah Martinez',
                                    location: 'KL 109',
                                    scheduledTime: 'Tomorrow at 2:00 PM',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildMeetingItem(
                            context,
                            'Program Orientation',
                            'Friday at 10:00 AM',
                            'Science Building Room 201',
                            Colors.green,
                            () {
                              // Navigate to check-in screen
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildMeetingItem(
                            context,
                            'Career Planning Session',
                            'Next Monday at 3:30 PM',
                            'Virtual (Zoom)',
                            Colors.orange,
                            () {
                              // Navigate to check-in screen
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bottom row - Quick Access
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildQuickAccessCard(
                          context,
                          'My Checklist',
                          Icons.checklist,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MenteeChecklistScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          'Resources',
                          Icons.folder_open,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ResourceHubScreen(isMentor: false),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          'Meeting Notes',
                          Icons.note,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MeetingNotesScreen(
                                  isMentor: false,
                                  mentorName: 'Sarah Martinez',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          'Newsletters',
                          Icons.newspaper,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewsletterScreen(isMentor: false),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          'Schedule Meeting',
                          Icons.calendar_today,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScheduleMeetingScreen(isMentor: false),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementItem(String title, String content, String time, [String? priority]) {
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPriority ? Icons.priority_high : Icons.campaign, 
                color: hasPriority ? priorityColor : const Color(0xFF2196F3),
                size: 20,
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
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildMeetingItem(
    BuildContext context,
    String title,
    String time,
    String location,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(0, 28),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Check In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(0xFF0F2D52),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 