import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'schedule_meeting_screen.dart';
import 'progress_reports_screen.dart';
import 'web_resource_hub_screen.dart';
import 'web_settings_screen.dart';
import 'announcement_screen.dart';
import 'web_newsletter_screen.dart';
import '../services/mentor_service.dart';
import '../services/auth_service.dart';
import '../services/dashboard_data_service.dart';
import '../utils/responsive.dart';

class WebCoordinatorDashboardScreen extends StatefulWidget {
  const WebCoordinatorDashboardScreen({super.key});

  @override
  State<WebCoordinatorDashboardScreen> createState() => _WebCoordinatorDashboardScreenState();
}

class _WebCoordinatorDashboardScreenState extends State<WebCoordinatorDashboardScreen> {
  int _selectedIndex = 0;
  final DashboardDataService _dataService = DashboardDataService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  
  final List<String> _sidebarItems = [
    'Dashboard',
    'Mentors',
    'Mentees',
    'Matching',
    'Reports',
    'Resources',
    'Announcements',
    'Newsletter',
    'Program Data',
    'Settings',
  ];
  
  final List<IconData> _sidebarIcons = [
    Icons.dashboard,
    Icons.supervisor_account,
    Icons.people,
    Icons.handshake,
    Icons.assessment,
    Icons.folder_open,
    Icons.campaign,
    Icons.newspaper,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final data = await _dataService.getCoordinatorDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
                          backgroundColor: Color(0xFF0F2D52),
                          child: Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
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
                          onSelected: (value) async {
                            if (value == 'logout') {
                              await AuthService().signOut();
                              // Navigation will be handled automatically by AuthWrapper
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
                            switch (index) {
                              case 9: // Settings
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WebSettingsScreen(isMentor: false),
                                  ),
                                );
                                break;
                              case 7: // Newsletter
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WebNewsletterScreen(isMentor: false, isCoordinator: true),
                                  ),
                                );
                                break;
                              case 6: // Announcements
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AnnouncementScreen(isCoordinator: true),
                                  ),
                                );
                                break;
                              case 5: // Resources
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WebResourceHubScreen(isCoordinator: true),
                                  ),
                                );
                                break;
                              case 4: // Reports
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProgressReportsScreen(),
                                  ),
                                );
                                break;
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
                                    leading: Icon(Icons.warning, color: Colors.red),
                                    title: Text('Mentor-Mentee Match Issues'),
                                    subtitle: Text('3 mentees still need mentors'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.assignment_late, color: Colors.orange),
                                    title: Text('Pending Reports'),
                                    subtitle: Text('5 mentors have overdue reports'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.event, color: Colors.blue),
                                    title: Text('Upcoming Program Review'),
                                    subtitle: Text('Scheduled for next week'),
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    const Text('Error loading dashboard data', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text(_error!, style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadDashboardData,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _buildDashboardContent(context, mentorService),
                  ),
                
                if (_selectedIndex == 1) // Mentors
                  Expanded(
                    child: _buildMentorsContent(context, mentorService),
                  ),
                
                if (_selectedIndex == 2) // Mentees
                  Expanded(
                    child: _buildMenteesContent(context, mentorService),
                  ),
                
                if (_selectedIndex == 3) // Matching
                  Expanded(
                    child: _buildMatchingContent(context, mentorService),
                  ),
                
                if (_selectedIndex == 8) // Program Data
                  Expanded(
                    child: _buildProgramDataContent(context, mentorService),
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
    if (_dashboardData == null) {
      return const Center(child: Text('No data available'));
    }
    
    final stats = _dashboardData!['stats'] ?? {};
    final mentors = List<Map<String, dynamic>>.from(_dashboardData!['mentors'] ?? []);
    final mentees = List<Map<String, dynamic>>.from(_dashboardData!['mentees'] ?? []);
    final recentAssignments = List<Map<String, dynamic>>.from(_dashboardData!['recentAssignments'] ?? []);
    final announcements = List<Map<String, dynamic>>.from(_dashboardData!['announcements'] ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Program Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Active Mentors',
                        '${stats['totalMentors'] ?? 0}',
                        Icons.psychology,
                        const Color(0xFF2196F3),
                      ),
                      _buildStatCard(
                        'Active Mentees',
                        '${stats['totalMentees'] ?? 0}',
                        Icons.school,
                        const Color(0xFF4CAF50),
                      ),
                      _buildStatCard(
                        'Success Rate',
                        '${stats['successRate'] ?? 0}%',
                        Icons.trending_up,
                        const Color(0xFFFFA726),
                      ),
                      _buildStatCard(
                        'Program Completion',
                        '${stats['completionRate'] ?? 0}%',
                        Icons.pie_chart,
                        const Color(0xFF9C27B0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Actions Row
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Manage Events',
                  Icons.event,
                  () {
                    // TODO: Navigate to manage events
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Qualtrics',
                  Icons.analytics,
                  () {
                    Navigator.pushNamed(context, '/qualtrics');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Resources',
                  Icons.folder_shared,
                  () {
                    // TODO: Navigate to resources
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Announcements',
                  Icons.campaign,
                  () {
                    // TODO: Navigate to announcements
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Two-column layout for the rest of the content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Messages and Mentor-Mentee Assignments
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Messages Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Direct Messages',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('New Message'),
                                  onPressed: () {
                                    // TODO: New message action
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Mentors',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Mock list of mentors
                            _buildMessageListTile(
                              context,
                              'Sarah Martinez',
                              '3rd Year, Computer Science Major',
                              'Mentor',
                            ),
                            _buildMessageListTile(
                              context,
                              'John Davis',
                              '4th Year, Biology Major',
                              'Mentor',
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Mentees',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Mock list of mentees
                            _buildMessageListTile(
                              context,
                              'Alice Johnson',
                              '1st Year, Biology Major',
                              'Mentee',
                            ),
                            _buildMessageListTile(
                              context,
                              'Bob Wilson',
                              '2nd Year, Psychology Major',
                              'Mentee',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Mentor-Mentee Assignments
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mentor-Mentee Assignments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View All'),
                                  onPressed: () {
                                    // TODO: View all assignments
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Recent Assignments
                            _buildAssignmentItem(
                              'Sarah Martinez',
                              'Alice Johnson',
                              '2 days ago',
                              true, // coordinator assigned
                            ),
                            const Divider(),
                            _buildAssignmentItem(
                              'John Davis',
                              'Bob Wilson',
                              '1 week ago',
                              false, // mentor selected
                            ),
                            const Divider(),
                            _buildAssignmentItem(
                              'Maria Rodriguez',
                              'David Lee',
                              '3 days ago',
                              true, // coordinator assigned
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Right column - Recent Activity and Upcoming Events
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Recent Activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
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
                                TextButton.icon(
                                  icon: const Icon(Icons.filter_list),
                                  label: const Text('Filter'),
                                  onPressed: () {
                                    // TODO: Filter action
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildActivityItem(
                              'New Survey Response',
                              'From: Dr. Smith (Mentor)',
                              '10 minutes ago',
                              Icons.poll,
                            ),
                            const Divider(),
                            _buildActivityItem(
                              'Meeting Completed',
                              'Alice Johnson & Dr. Smith',
                              '1 hour ago',
                              Icons.check_circle,
                            ),
                            const Divider(),
                            _buildActivityItem(
                              'Resource Added',
                              'New Mentorship Guide',
                              '2 hours ago',
                              Icons.upload_file,
                            ),
                            const Divider(),
                            _buildActivityItem(
                              'New Mentor Application',
                              'From: Jordan Peterson',
                              '3 hours ago',
                              Icons.person_add,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Upcoming Events
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildEventCard(
                              'Mentor Training Workshop',
                              'Tomorrow, 2:00 PM',
                              '24 Registered',
                              0.8,
                            ),
                            const SizedBox(height: 12),
                            _buildEventCard(
                              'Group Mentoring Session',
                              'Friday, 3:00 PM',
                              '18 Registered',
                              0.6,
                            ),
                            const SizedBox(height: 12),
                            _buildEventCard(
                              'End of Year Celebration',
                              'May 30, 5:00 PM',
                              '42 Registered',
                              0.7,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action Items Card
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Action Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildActionItem(
                              'Review Mentor Applications',
                              '3 pending reviews',
                              Icons.person_add,
                            ),
                            const Divider(),
                            _buildActionItem(
                              'Survey Analysis Due',
                              'End of week deadline',
                              Icons.assessment,
                            ),
                            const Divider(),
                            _buildActionItem(
                              'Update Program Resources',
                              'Requested by mentors',
                              Icons.update,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(0xFF0F2D52),
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
  
  Widget _buildMessageListTile(
    BuildContext context,
    String name,
    String description,
    String role,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF0F2D52),
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to chat screen
      },
    );
  }
  
  Widget _buildAssignmentItem(
    String mentorName,
    String menteeName,
    String assignmentDate,
    bool isCoordinatorAssigned,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mentor: $mentorName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mentee: $menteeName',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              assignmentDate,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          if (isCoordinatorAssigned)
            const Tooltip(
              message: 'Assigned by coordinator',
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            )
          else
            const Tooltip(
              message: 'Mentor selected',
              child: Icon(
                Icons.person,
                color: Colors.blue,
                size: 20,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show assignment options
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2D52).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F2D52),
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
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
  
  Widget _buildEventCard(
    String title,
    String time,
    String attendance,
    double registrationProgress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: registrationProgress,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  color: const Color(0xFF0F2D52),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                attendance,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF0F2D52),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Handle action item tap
      },
    );
  }
  
  // Placeholder content for other tabs
  Widget _buildMentorsContent(BuildContext context, MentorService mentorService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search mentors...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Department'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Departments')),
                  DropdownMenuItem(value: 'cs', child: Text('Computer Science')),
                  DropdownMenuItem(value: 'bio', child: Text('Biology')),
                  DropdownMenuItem(value: 'psych', child: Text('Psychology')),
                ],
                onChanged: (value) {
                  // TODO: Filter by department
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                ],
                onChanged: (value) {
                  // TODO: Filter by status
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Mentor'),
                onPressed: () {
                  // TODO: Add new mentor
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2D52),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Mentors list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Active Mentors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // TODO: Refresh mentor list
                        },
                        tooltip: 'Refresh List',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // TODO: Export mentor list
                        },
                        tooltip: 'Export List',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2D52).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('MENTEES', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  
                  // Mentor rows
                  const SizedBox(height: 8),
                  _buildMentorRow(
                    'Sarah Martinez', 
                    'Computer Science', 
                    3, 
                    'Active',
                    const Color(0xFF4CAF50),
                  ),
                  const Divider(),
                  _buildMentorRow(
                    'John Davis', 
                    'Biology', 
                    2, 
                    'Active',
                    const Color(0xFF4CAF50),
                  ),
                  const Divider(),
                  _buildMentorRow(
                    'Maria Rodriguez', 
                    'Psychology', 
                    4, 
                    'Active',
                    const Color(0xFF4CAF50),
                  ),
                  const Divider(),
                  _buildMentorRow(
                    'David Lee', 
                    'Physics', 
                    0, 
                    'Inactive',
                    Colors.grey,
                  ),
                  const Divider(),
                  _buildMentorRow(
                    'James Wilson', 
                    'Chemistry', 
                    1, 
                    'Active',
                    const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Pending Approvals Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Mentor Applications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPendingMentorItem(
                    'Elizabeth Brown',
                    'Mathematics',
                    'Applied on May 15, 2023',
                  ),
                  const Divider(),
                  _buildPendingMentorItem(
                    'Michael Johnson',
                    'Computer Engineering',
                    'Applied on May 14, 2023',
                  ),
                  const Divider(),
                  _buildPendingMentorItem(
                    'Sophia Martinez',
                    'Psychology',
                    'Applied on May 10, 2023',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorRow(
    String name,
    String department,
    int menteeCount,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F2D52),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(department)),
          Expanded(
            flex: 2, 
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: menteeCount > 0 ? const Color(0xFF0F2D52).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$menteeCount ${menteeCount == 1 ? 'Mentee' : 'Mentees'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: menteeCount > 0 ? const Color(0xFF0F2D52) : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2, 
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(status),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // TODO: Edit mentor
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    // TODO: Show more options
                  },
                  tooltip: 'More Options',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingMentorItem(
    String name,
    String department,
    String appliedDate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$department • $appliedDate',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: View application
            },
            child: const Text('Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              // TODO: Reject application
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteesContent(BuildContext context, MentorService mentorService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search mentees...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Program'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Programs')),
                  DropdownMenuItem(value: 'cs', child: Text('Computer Science')),
                  DropdownMenuItem(value: 'bio', child: Text('Biology')),
                  DropdownMenuItem(value: 'psych', child: Text('Psychology')),
                ],
                onChanged: (value) {
                  // TODO: Filter by program
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                  DropdownMenuItem(value: 'unassigned', child: Text('Unassigned')),
                  DropdownMenuItem(value: 'requested', child: Text('Requested Mentor')),
                ],
                onChanged: (value) {
                  // TODO: Filter by status
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Mentee'),
                onPressed: () {
                  // TODO: Add new mentee
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2D52),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Mentees List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'All Mentees',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // TODO: Refresh mentee list
                        },
                        tooltip: 'Refresh List',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // TODO: Export mentee list
                        },
                        tooltip: 'Export List',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildStatusIndicator('Available', Colors.green),
                      _buildStatusIndicator('Assigned', Colors.blue),
                      _buildStatusIndicator('Requested Mentor', Colors.orange),
                      _buildStatusIndicator('Inactive', Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2D52).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('PROGRAM', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  
                  // Mentee rows
                  const SizedBox(height: 8),
                  _buildMenteeRow(
                    context,
                    'Alice Johnson',
                    '1st Year, Biology',
                    'Assigned to Sarah Martinez',
                    Colors.blue,
                  ),
                  const Divider(),
                  _buildMenteeRow(
                    context,
                    'Bob Wilson',
                    '2nd Year, Psychology',
                    'Assigned to John Davis',
                    Colors.blue,
                  ),
                  const Divider(),
                  _buildMenteeRow(
                    context,
                    'Michael Brown',
                    '1st Year, Computer Science',
                    'Available',
                    Colors.green,
                  ),
                  const Divider(),
                  _buildMenteeRow(
                    context,
                    'Lisa Chen',
                    '2nd Year, Biology',
                    'Requested Mentor: Sarah Martinez',
                    Colors.orange,
                  ),
                  const Divider(),
                  _buildMenteeRow(
                    context,
                    'James Wilson',
                    '1st Year, Psychology',
                    'Available',
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Mentee Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mentee Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMenteeMetric(
                        'Total Mentees',
                        '36',
                        Icons.people,
                        const Color(0xFF2196F3),
                      ),
                      _buildMenteeMetric(
                        'Assigned',
                        '28',
                        Icons.check_circle,
                        const Color(0xFF4CAF50),
                      ),
                      _buildMenteeMetric(
                        'Unassigned',
                        '8',
                        Icons.person_off,
                        Colors.orange,
                      ),
                      _buildMenteeMetric(
                        'New This Month',
                        '12',
                        Icons.new_releases,
                        const Color(0xFF9C27B0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMenteeRow(
    BuildContext context,
    String name,
    String program,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F2D52),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(program)),
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: status.startsWith('Requested')
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        onPressed: () {
                          // TODO: Approve mentee's mentor request
                        },
                        tooltip: 'Approve Request',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                        onPressed: () {
                          // TODO: Deny mentee's mentor request
                        },
                        tooltip: 'Deny Request',
                      ),
                    ],
                  )
                : status == 'Available'
                    ? TextButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign'),
                        onPressed: () {
                          // TODO: Assign mentor
                        },
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              // TODO: Edit mentee
                            },
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () {
                              // TODO: Show more options
                            },
                            tooltip: 'More Options',
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMatchingContent(BuildContext context, MentorService mentorService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and explanation
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mentor-Mentee Matching',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pair mentors with compatible mentees based on their profiles, interests, and academic goals.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto-Match'),
                onPressed: () {
                  // TODO: Implement auto-matching algorithm
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Auto-matching in progress...'),
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
          const SizedBox(height: 24),
          
          // Matching criteria card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Matching Criteria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildCriteriaChip('Academic Field', true),
                      _buildCriteriaChip('Career Goals', true),
                      _buildCriteriaChip('Research Interests', true),
                      _buildCriteriaChip('Background', false),
                      _buildCriteriaChip('Personality', false),
                      _buildCriteriaChip('Mentorship Style', true),
                      _buildCriteriaChip('Availability', true),
                      _buildCriteriaChip('Gender', false),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Adjust Weights'),
                        onPressed: () {
                          // TODO: Open criteria weight adjustment dialog
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Main matching interface - two column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Available Mentees
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Available Mentees',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                // TODO: Search mentees
                              },
                              tooltip: 'Search',
                            ),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {
                                // TODO: Filter mentees
                              },
                              tooltip: 'Filter',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search mentees...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      // List of mentees
                      Container(
                        height: 400,
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            _buildMenteeCardForMatching(
                              'Michael Brown',
                              '1st Year, Computer Science',
                              'Interests: AI, Mobile Development, Web Development',
                              Icons.computer,
                              const Color(0xFF2196F3),
                            ),
                            const SizedBox(height: 12),
                            _buildMenteeCardForMatching(
                              'Lisa Chen',
                              '2nd Year, Biology',
                              'Interests: Molecular Biology, Genetics, Research',
                              Icons.biotech,
                              const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 12),
                            _buildMenteeCardForMatching(
                              'James Wilson',
                              '1st Year, Psychology',
                              'Interests: Clinical Psychology, Research Methods',
                              Icons.psychology,
                              const Color(0xFF9C27B0),
                            ),
                            const SizedBox(height: 12),
                            _buildMenteeCardForMatching(
                              'Jennifer Lopez',
                              '1st Year, Business',
                              'Interests: Entrepreneurship, Marketing, Finance',
                              Icons.business,
                              const Color(0xFFFFA726),
                            ),
                            const SizedBox(height: 12),
                            _buildMenteeCardForMatching(
                              'Robert Garcia',
                              '2nd Year, Engineering',
                              'Interests: Robotics, Mechanical Design, IoT',
                              Icons.engineering,
                              const Color(0xFFE91E63),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Center column with arrows
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 32),
                      onPressed: () {
                        // TODO: Match selected mentee with mentor
                      },
                      tooltip: 'Create Match',
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 32),
                      onPressed: () {
                        // TODO: Remove match
                      },
                      tooltip: 'Remove Match',
                    ),
                  ],
                ),
              ),
              
              // Right column - Available Mentors
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Available Mentors',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                // TODO: Search mentors
                              },
                              tooltip: 'Search',
                            ),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {
                                // TODO: Filter mentors
                              },
                              tooltip: 'Filter',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search mentors...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      // List of mentors
                      Container(
                        height: 400,
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            _buildMentorCardForMatching(
                              'Sarah Martinez',
                              'Computer Science',
                              3,
                              'Specialty: Mobile & Web Development',
                              Icons.computer,
                              const Color(0xFF2196F3),
                            ),
                            const SizedBox(height: 12),
                            _buildMentorCardForMatching(
                              'John Davis',
                              'Biology',
                              2,
                              'Specialty: Molecular Biology & Genetics',
                              Icons.biotech,
                              const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 12),
                            _buildMentorCardForMatching(
                              'Maria Rodriguez',
                              'Psychology',
                              4,
                              'Specialty: Clinical Psychology',
                              Icons.psychology,
                              const Color(0xFF9C27B0),
                            ),
                            const SizedBox(height: 12),
                            _buildMentorCardForMatching(
                              'James Wilson',
                              'Chemistry',
                              1,
                              'Specialty: Organic Chemistry',
                              Icons.science,
                              const Color(0xFFE91E63),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Current Matches
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Current Matches',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Export Matches'),
                        onPressed: () {
                          // TODO: Export match list
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2D52).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('MENTOR', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text('MENTEE', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('MATCHED DATE', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('MATCH SCORE', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  
                  // Match rows
                  const SizedBox(height: 8),
                  _buildMatchRow(
                    'Sarah Martinez', 
                    'Alice Johnson',
                    'May 15, 2023',
                    '95%',
                  ),
                  const Divider(),
                  _buildMatchRow(
                    'John Davis', 
                    'Bob Wilson',
                    'May 10, 2023',
                    '87%',
                  ),
                  const Divider(),
                  _buildMatchRow(
                    'Maria Rodriguez', 
                    'David Lee',
                    'May 17, 2023',
                    '92%',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaChip(String label, bool isActive) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (value) {
        // TODO: Toggle matching criteria
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: const Color(0xFF0F2D52).withOpacity(0.1),
      checkmarkColor: const Color(0xFF0F2D52),
      labelStyle: TextStyle(
        color: isActive ? const Color(0xFF0F2D52) : Colors.black,
      ),
    );
  }

  Widget _buildMenteeCardForMatching(
    String name,
    String program,
    String interests,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    program,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    interests,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: name,
              groupValue: null,
              onChanged: (value) {
                // TODO: Select mentee
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorCardForMatching(
    String name,
    String department,
    int menteeCount,
    String specialty,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    '$department • $menteeCount ${menteeCount == 1 ? 'Mentee' : 'Mentees'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: name,
              groupValue: null,
              onChanged: (value) {
                // TODO: Select mentor
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchRow(
    String mentorName,
    String menteeName,
    String matchDate,
    String matchScore,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F2D52),
                  child: Text(
                    mentorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(mentorName),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    menteeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(menteeName),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(matchDate),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                matchScore,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    // TODO: Delete match
                  },
                  tooltip: 'Delete Match',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    // TODO: Show more options
                  },
                  tooltip: 'More Options',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgramDataContent(BuildContext context, MentorService mentorService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Data Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Program Analytics Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDataMetric(
                        'Mentorship Quality',
                        '4.7/5',
                        Icons.thumb_up,
                        const Color(0xFF4CAF50),
                      ),
                      _buildDataMetric(
                        'Completion Rate',
                        '85%',
                        Icons.assignment_turned_in,
                        const Color(0xFF2196F3),
                      ),
                      _buildDataMetric(
                        'Mentee Retention',
                        '92%',
                        Icons.group,
                        const Color(0xFFFFA726),
                      ),
                      _buildDataMetric(
                        'Meeting Attendance',
                        '78%',
                        Icons.event_available,
                        const Color(0xFF9C27B0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Qualtrics Data Card
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        size: 28,
                        color: Color(0xFF0F2D52),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qualtrics Surveys and Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Access all program survey data, create new surveys, and analyze results',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Dashboard'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/qualtrics');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2D52),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Survey Activities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSurveyListItem(
                        'Mentor Program Satisfaction',
                        'May 15, 2023',
                        '42/50 responses',
                        0.84,
                      ),
                      const SizedBox(height: 12),
                      _buildSurveyListItem(
                        'Mentee Mid-Program Feedback',
                        'May 10, 2023',
                        '36/40 responses',
                        0.9,
                      ),
                      const SizedBox(height: 12),
                      _buildSurveyListItem(
                        'Workshop Effectiveness',
                        'May 5, 2023',
                        '28/35 responses',
                        0.8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Program Metrics Visualization Placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Program Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildMetricVisualizationPlaceholder(
                          'Mentor-Mentee Match Satisfaction',
                          'By Academic Department',
                          Icons.pie_chart,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildMetricVisualizationPlaceholder(
                          'Program Participation',
                          'Last 6 Months Trend',
                          Icons.show_chart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMetricVisualizationPlaceholder(
                    'Mentorship Outcome Categories',
                    'Distribution by Goal Type',
                    Icons.bar_chart,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildSurveyListItem(
    String title,
    String date,
    String responses,
    double completionRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.poll,
            color: Color(0xFF0F2D52),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
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
                        value: completionRate,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        color: const Color(0xFF0F2D52),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      responses,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              // TODO: View survey details
            },
            tooltip: 'View Details',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download survey data
            },
            tooltip: 'Download Data',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricVisualizationPlaceholder(
    String title,
    String subtitle,
    IconData chartIcon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2D52).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  chartIcon,
                  size: 60,
                  color: const Color(0xFF0F2D52).withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 