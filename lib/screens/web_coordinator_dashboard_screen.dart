import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'qualtrics_dashboard_screen.dart';
import 'resource_hub_screen.dart';
import 'announcement_screen.dart';
import 'manage_events_screen.dart';
import '../services/mentor_service.dart';
import '../utils/responsive.dart';

class WebCoordinatorDashboardScreen extends StatefulWidget {
  const WebCoordinatorDashboardScreen({super.key});

  @override
  State<WebCoordinatorDashboardScreen> createState() => _WebCoordinatorDashboardScreenState();
}

class _WebCoordinatorDashboardScreenState extends State<WebCoordinatorDashboardScreen> {
  int _selectedIndex = 0;
  
  final List<String> _sidebarItems = [
    'Dashboard',
    'Program Stats',
    'Manage Mentors',
    'Manage Mentees',
    'Events',
    'Resources',
    'Announcements',
    'Qualtrics Data',
    'Settings',
  ];
  
  final List<IconData> _sidebarIcons = [
    Icons.dashboard,
    Icons.analytics,
    Icons.psychology,
    Icons.school,
    Icons.event,
    Icons.folder_shared,
    Icons.campaign,
    Icons.insert_chart,
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
                          'SMP Coordinator',
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
                                'Clarissa Correa',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Program Coordinator',
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
                                  builder: (context) => const SettingsScreen(isMentor: false),
                                ),
                              );
                            } else if (index == 7) { // Qualtrics
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const QualtricsDataDashboardScreen(),
                                ),
                              );
                            } else if (index == 6) { // Announcements
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AnnouncementScreen(isCoordinator: true),
                                ),
                              );
                            } else if (index == 5) { // Resources
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ResourceHubScreen(isMentor: false, isCoordinator: true),
                                ),
                              );
                            } else if (index == 4) { // Events
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageEventsScreen(),
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
                          // Show notifications dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Notifications'),
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.person_add, color: Colors.green),
                                    title: Text('New Mentor Registration'),
                                    subtitle: Text('John Davis has registered as a mentor'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.school, color: Colors.blue),
                                    title: Text('New Mentee Registration'),
                                    subtitle: Text('3 new mentees have registered'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.event, color: Colors.orange),
                                    title: Text('Upcoming Event'),
                                    subtitle: Text('Orientation session tomorrow at 10 AM'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dashboard content placeholder
  Widget _buildDashboardContent(BuildContext context, MentorService mentorService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program overview section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program stats
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Program Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              'Active Mentors', 
                              '24',
                              Icons.psychology,
                              Colors.blue[700]!,
                            ),
                            _buildStatItem(
                              'Active Mentees',
                              '52',
                              Icons.school,
                              Colors.green[700]!,
                            ),
                            _buildStatItem(
                              'Unmatched Mentees',
                              '8',
                              Icons.person_search,
                              Colors.orange[700]!,
                            ),
                            _buildStatItem(
                              'Meetings This Week',
                              '37',
                              Icons.event,
                              Colors.purple[700]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Program health
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Program Health',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildProgressItem(
                                'Meeting Completion',
                                0.78,
                                '78%',
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildProgressItem(
                                'Mentor Engagement',
                                0.85,
                                '85%',
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildProgressItem(
                                'Qualtrics Completion',
                                0.62,
                                '62%',
                                Colors.orange,
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
          
          const SizedBox(height: 20),
          
          // Quick actions and alerts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick actions
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildActionButton(
                              'Match Mentors',
                              Icons.people_alt,
                              Colors.blue[700]!,
                              () {
                                // TODO: Navigate to matching page
                              },
                            ),
                            _buildActionButton(
                              'Send Announcement',
                              Icons.campaign,
                              Colors.orange[700]!,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AnnouncementScreen(isCoordinator: true),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              'Create Event',
                              Icons.event,
                              Colors.green[700]!,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ManageEventsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              'View Reports',
                              Icons.assessment,
                              Colors.purple[700]!,
                              () {
                                // TODO: Navigate to reports
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Alerts and notifications
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Alerts & Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              onPressed: () {
                                // TODO: Refresh alerts
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildAlertItem(
                          'Inactive Mentor',
                          'James Wilson has not logged in for 14 days',
                          Icons.warning_amber,
                          Colors.orange[700]!,
                          'high',
                        ),
                        _buildAlertItem(
                          'Missed Meetings',
                          '3 mentors have missed scheduled meetings this week',
                          Icons.event_busy,
                          Colors.red[700]!,
                          'critical',
                        ),
                        _buildAlertItem(
                          'New Mentees',
                          '5 new mentees need to be matched with mentors',
                          Icons.person_add,
                          Colors.blue[700]!,
                          'medium',
                        ),
                        _buildAlertItem(
                          'Qualtrics Reminder',
                          'Mid-semester survey deadline in 5 days',
                          Icons.assignment,
                          Colors.green[700]!,
                          'low',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recent mentors and upcoming events
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent activity
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              child: const Text('View All'),
                              onPressed: () {
                                // TODO: Navigate to activity log
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildMentorListItem(
                          'Alex Johnson',
                          'Introduced to mentee Sofia Chen',
                          '2 hours ago',
                          Colors.blue[700]!,
                        ),
                        _buildMentorListItem(
                          'Maria Rodriguez',
                          'Reported missed meeting with mentee',
                          '5 hours ago',
                          Colors.orange[700]!,
                        ),
                        _buildMentorListItem(
                          'David Patel',
                          'Completed training module 3',
                          'Yesterday',
                          Colors.green[700]!,
                        ),
                        _buildMentorListItem(
                          'Sarah Williams',
                          'Updated availability schedule',
                          'Yesterday',
                          Colors.purple[700]!,
                        ),
                        _buildMentorListItem(
                          'Marcus Lee',
                          'Posted new resource to hub',
                          '2 days ago',
                          Colors.teal[700]!,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Upcoming events
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upcoming Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              child: const Text('Manage'),
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (context) => const ManageEventsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildEventItem(
                          'Mentor Training Workshop',
                          DateTime.now().add(const Duration(days: 2)),
                          'Virtual',
                          15,
                        ),
                        _buildEventItem(
                          'Mid-Semester Check-in',
                          DateTime.now().add(const Duration(days: 5)),
                          'Room 302, Student Center',
                          28,
                        ),
                        _buildEventItem(
                          'Career Panel Discussion',
                          DateTime.now().add(const Duration(days: 8)),
                          'Auditorium B',
                          42,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressItem(String label, double value, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertItem(String title, String description, IconData icon, Color color, String priority) {
    Color backgroundColor;
    Color borderColor;
    
    if (priority == 'critical') {
      backgroundColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
    } else if (priority == 'high') {
      backgroundColor = Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange;
    } else if (priority == 'medium') {
      backgroundColor = Colors.blue.withOpacity(0.1);
      borderColor = Colors.blue;
    } else {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              // TODO: Show actions menu
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMentorListItem(String name, String activity, String time, Color activityColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        activity,
        style: TextStyle(
          fontSize: 14,
          color: activityColor,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Colors.grey[400],
          ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to mentor details
      },
    );
  }
  
  Widget _buildEventItem(String title, DateTime dateTime, String location, int attendees) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '$attendees attendees registered',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // TODO: View event details
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F2D52),
                  side: const BorderSide(color: Color(0xFF0F2D52)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Details'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  // TODO: Manage event
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2D52),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Manage'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
