import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'web_chat_screen.dart';
import 'web_schedule_meeting_screen.dart';
import 'meeting_notes_screen.dart';
import 'web_progress_reports_screen.dart';
import 'web_resource_hub_screen.dart';
import 'web_settings_screen.dart';
import 'checklist_screen.dart';
import '../services/mentor_service.dart';
import 'checkin_checkout_screen.dart';
import 'web_newsletter_screen.dart';
import 'announcement_screen.dart';
import '../utils/responsive.dart';

class WebMentorDashboardScreen extends StatefulWidget {
  const WebMentorDashboardScreen({super.key});

  @override
  State<WebMentorDashboardScreen> createState() => _WebMentorDashboardScreenState();
}

class _WebMentorDashboardScreenState extends State<WebMentorDashboardScreen> {
  int _selectedIndex = 0;
  
  final List<String> _sidebarItems = [
    'Dashboard',
    'Mentees',
    'Schedule',
    'Reports',
    'Resources',
    'Checklist',
    'Newsletters',
    'Announcements',
    'Settings',
  ];
  
  final List<IconData> _sidebarIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.event_note,
    Icons.assessment,
    Icons.folder_open,
    Icons.check_circle_outline,
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
                          'SMP Mentor',
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
                                'Sarah Martinez',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Mentor',
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
                            if (index == 8) { // Settings
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WebSettingsScreen(isMentor: true),
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
                        icon: const Icon(Icons.support_agent),
                        onPressed: () {
                          // Navigate to coordinator chat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WebChatScreen(
                                recipientName: 'Clarissa Correa',
                                recipientRole: 'SMP Program Coordinator',
                              ),
                            ),
                          );
                        },
                        tooltip: 'Message Coordinator',
                      ),
                      const SizedBox(width: 8),
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
                          // Show notifications dialog
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
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
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
                
                // Main content based on selected sidebar item
                if (_selectedIndex == 0) // Dashboard
                  Expanded(
                    child: _buildDashboardContent(context, mentorService),
                  ),
                
                if (_selectedIndex == 1) // Mentees
                  Expanded(
                    child: _buildMenteesContent(context, mentorService),
                  ),
                
                if (_selectedIndex == 2) // Schedule
                  Expanded(
                    child: Scaffold(
                      body: WebScheduleMeetingScreen(isMentor: true),
                    ),
                  ),
                
                if (_selectedIndex == 3) // Reports
                  Expanded(
                    child: Scaffold(
                      body: WebProgressReportsScreen(),
                    ),
                  ),
                
                if (_selectedIndex == 4) // Resources
                  Expanded(
                    child: Scaffold(
                      body: WebResourceHubScreen(isMentor: true),
                    ),
                  ),
                
                if (_selectedIndex == 5) // Checklist
                  Expanded(
                    child: Scaffold(
                      body: ChecklistScreen(isMentor: true),
                    ),
                  ),
                
                if (_selectedIndex == 6) // Newsletters
                  Expanded(
                    child: Scaffold(
                      body: WebNewsletterScreen(isMentor: true),
                    ),
                  ),
                
                if (_selectedIndex == 7) // Announcements
                  Expanded(
                    child: Scaffold(
                      body: AnnouncementScreen(isCoordinator: false),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, MentorService mentorService) {
    return Column(
      children: [
        const SizedBox(height: 24),
        
        // Middle row - Mentees and upcoming meetings
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mentees overview
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
                            'Your Mentees',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 1; // Switch to mentees tab
                              });
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...mentorService.mentees.take(3).map((mentee) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildMenteeListItem(
                            context,
                            mentee['name'],
                            mentee['program'],
                            mentee['progress'],
                            () {
                              // View mentee details
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Upcoming meetings
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
                            'Upcoming Meetings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 2; // Switch to schedule tab
                              });
                            },
                            child: const Text('View Calendar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMeetingItem(
                              context,
                              'Weekly Check-in',
                              'Alice Johnson',
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
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMeetingItem(
                              context,
                              'Resume Review',
                              'Bob Wilson',
                              'Friday at 4:30 PM',
                              'Library Study Room 3',
                              Colors.green,
                              () {
                                // Navigate to check-in screen
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMeetingItem(
                              context,
                              'Career Planning',
                              'Carlos Rodriguez',
                              'Next Monday at 11:00 AM',
                              'Virtual (Zoom)',
                              Colors.orange,
                              () {
                                // Navigate to check-in screen
                              },
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
        
        const SizedBox(height: 24),
        
        // Bottom row - Announcements and Recent Activity
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Announcements section
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
                      ...mentorService.announcements.take(2).map((announcement) =>
                        _buildAnnouncementItem(
                          announcement['title'],
                          announcement['content'],
                          announcement['time'],
                          announcement['priority'],
                        ),
                      ).toList(),
                      
                      // Add a third announcement if service has less than 2
                      if (mentorService.announcements.length < 2)
                        _buildAnnouncementItem(
                          'End of Semester Survey',
                          'Please remind your mentees to complete the end of semester feedback survey by next Friday.',
                          '3 days ago',
                          'medium',
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Recent activity
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
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem(
                        'Scheduled meeting with Alice Johnson',
                        '2 hours ago',
                        Icons.event_available,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        'Completed Progress Report for Carlos Rodriguez',
                        'Yesterday',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        'Added new resources to the Resource Hub',
                        '2 days ago',
                        Icons.folder_open,
                        Colors.amber,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        'Checked in for meeting with Bob Wilson',
                        '4 days ago',
                        Icons.login,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String title, 
    IconData icon, 
    VoidCallback onTap
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: const Color(0xFF0F2D52),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenteeListItem(
    BuildContext context,
    String name,
    String program,
    double progress,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      program,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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
                      builder: (context) => WebChatScreen(
                        recipientName: name,
                        recipientRole: program,
                      ),
                    ),
                  );
                },
                tooltip: 'Message',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Progress:'),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F2D52)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingItem(
    BuildContext context,
    String title,
    String menteeName,
    String time,
    String location,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  menteeName,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                  fontSize: 14,
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
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 16.0),
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

  Widget _buildActivityItem(String text, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
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
            ),
          ),
        ],
      ),
    );
  }

  // Mentees content
  Widget _buildMenteesContent(BuildContext context, MentorService mentorService) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter bar
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search mentees...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: 'All',
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Mentees')),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      // TODO: Filter mentees
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Mentee'),
                    onPressed: () {
                      _showAddMenteeDialog(context, mentorService);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2D52),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Mentees grid/list
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: mentorService.mentees.length,
              itemBuilder: (context, index) {
                final mentee = mentorService.mentees[index];
                return _buildMenteeCard(context, mentee, mentorService);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenteeCard(BuildContext context, Map<String, dynamic> mentee, MentorService mentorService) {
    final totalGoals = mentee['goals']?.length ?? 0;
    final completedGoals = mentee['goals']?.where((g) => g['completed'] == true).length ?? 0;
    final goalProgress = totalGoals > 0 ? completedGoals / totalGoals : 0.0;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showMenteeDetailsDialog(context, mentee, mentorService),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF0F2D52),
                    child: Text(
                      mentee['name'].substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'message':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebChatScreen(
                                recipientName: mentee['name'],
                                recipientRole: mentee['program'],
                              ),
                            ),
                          );
                          break;
                        case 'schedule':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WebScheduleMeetingScreen(isMentor: true),
                            ),
                          );
                          break;
                        case 'remove':
                          _confirmRemoveMentee(context, mentee, mentorService);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'message',
                        child: Row(
                          children: [
                            Icon(Icons.message, size: 20),
                            SizedBox(width: 8),
                            Text('Send Message'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'schedule',
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 20),
                            SizedBox(width: 8),
                            Text('Schedule Meeting'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove Mentee', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Assignment info
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
              const SizedBox(height: 12),
              
              // Last meeting
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Last meeting: ${mentee['lastMeeting']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress indicators
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: mentee['progress'],
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F2D52)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(mentee['progress'] * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goals Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: goalProgress,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$completedGoals/$totalGoals',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebChatScreen(
                            recipientName: mentee['name'],
                            recipientRole: mentee['program'],
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    onPressed: () => _showMenteeDetailsDialog(context, mentee, mentorService),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMenteeDetailsDialog(BuildContext context, Map<String, dynamic> mentee, MentorService mentorService) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF0F2D52),
                    child: Text(
                      mentee['name'].substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentee['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          mentee['program'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Goals section
              const Text(
                'Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (mentee['goals'] != null && mentee['goals'].isNotEmpty)
                ...mentee['goals'].map<Widget>((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        goal['completed'] ? Icons.check_circle : Icons.circle_outlined,
                        color: goal['completed'] ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal['goal'],
                          style: TextStyle(
                            decoration: goal['completed'] ? TextDecoration.lineThrough : null,
                            color: goal['completed'] ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList()
              else
                const Text('No goals set yet'),
              
              const SizedBox(height: 24),
              
              // Upcoming meetings section
              const Text(
                'Upcoming Meetings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (mentee['upcomingMeetings'] != null && mentee['upcomingMeetings'].isNotEmpty)
                ...mentee['upcomingMeetings'].map<Widget>((meeting) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: Icon(
                      Icons.event,
                      color: meeting['isNext'] ? Colors.green : Colors.blue,
                    ),
                    title: Text(meeting['title']),
                    subtitle: Text('${meeting['date']} at ${meeting['time']} - ${meeting['location']}'),
                    trailing: meeting['isNext'] 
                      ? const Chip(
                          label: Text('Next', style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green,
                          labelPadding: EdgeInsets.symmetric(horizontal: 4),
                        )
                      : null,
                  ),
                )).toList()
              else
                const Text('No upcoming meetings scheduled'),
              
              const SizedBox(height: 24),
              
              // Action items section
              const Text(
                'Action Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (mentee['actionItems'] != null && mentee['actionItems'].isNotEmpty)
                ...mentee['actionItems'].map<Widget>((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.assignment, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Due: ${item['dueDate']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList()
              else
                const Text('No action items'),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text('Send Message'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebChatScreen(
                            recipientName: mentee['name'],
                            recipientRole: mentee['program'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2D52),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddMenteeDialog(BuildContext context, MentorService mentorService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Available Mentees'),
        content: SizedBox(
          width: 500,
          child: Column(
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
              const Divider(),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _confirmRemoveMentee(BuildContext context, Map<String, dynamic> mentee, MentorService mentorService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Mentee'),
        content: Text('Are you sure you want to remove ${mentee['name']} from your mentee list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              mentorService.mentees.remove(mentee);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${mentee['name']} has been removed'),
                  backgroundColor: Colors.orange,
                ),
              );
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
} 