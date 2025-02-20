import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Coordinator Dashboard'),
            Text(
              'Clarissa Correa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(isMentor: false),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
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
          // Program Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Active Mentors',
                        '12',
                        Icons.psychology,
                      ),
                      _buildStatCard(
                        'Active Mentees',
                        '36',
                        Icons.school,
                      ),
                      _buildStatCard(
                        'Success Rate',
                        '92%',
                        Icons.trending_up,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Messages Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                'Manage Events',
                Icons.event,
                () {
                  // TODO: Open event management
                },
              ),
              _buildQuickActionCard(
                context,
                'Survey Data',
                Icons.analytics,
                () {
                  // TODO: Open survey analytics
                },
              ),
              _buildQuickActionCard(
                context,
                'Resources',
                Icons.folder_shared,
                () {
                  // TODO: Open resource management
                },
              ),
              _buildQuickActionCard(
                context,
                'Announcements',
                Icons.campaign,
                () {
                  // TODO: Open announcements
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mentor-Mentee Assignments
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Mentor-Mentee Assignments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/assignments');
                        },
                        child: const Text('View All'),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activity
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
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: View all activity
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Upcoming Events
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),

          // List of Mentees Card
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
                        'List of Mentees',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: View all mentees
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mentee Status Legend
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildStatusIndicator('Available', Colors.green),
                      _buildStatusIndicator('Pending Request', Colors.orange),
                      _buildStatusIndicator('Assigned', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mentee List
                  _buildMenteeListItem(
                    context,
                    'Michael Brown',
                    '1st Year, Computer Science',
                    'Available',
                    Colors.green,
                  ),
                  const Divider(),
                  _buildMenteeListItem(
                    context,
                    'Lisa Chen',
                    '2nd Year, Biology',
                    'Pending Request from Sarah Martinez',
                    Colors.orange,
                  ),
                  const Divider(),
                  _buildMenteeListItem(
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
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Quick actions menu
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: const Color(0xFF2196F3),
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

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2196F3),
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
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: registrationProgress,
                  backgroundColor: Colors.blue.withOpacity(0.1),
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
        color: const Color(0xFF2196F3),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Handle action item tap
      },
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
        child: Text(name.substring(0, 1).toUpperCase()),
      ),
      title: Text(name),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              recipientName: name,
              recipientRole: description,
            ),
          ),
        );
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  menteeName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            assignmentDate,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          if (isCoordinatorAssigned)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
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

  Widget _buildMenteeListItem(
    BuildContext context,
    String name,
    String program,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(name.substring(0, 1)),
          ),
          const SizedBox(width: 12),
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
                  program,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status == 'Available')
            TextButton(
              onPressed: () {
                // TODO: Show mentor selection dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Assign $name'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Choose an option:'),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text('Assign to Mentor'),
                          subtitle: const Text('Select a mentor to assign'),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Show mentor selection
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: const Text('Make Available'),
                          subtitle: const Text('Allow mentors to request this mentee'),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Update mentee status
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Assign'),
            ),
          if (status.startsWith('Pending'))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                  onPressed: () {
                    // TODO: Approve mentor request
                  },
                  tooltip: 'Approve Request',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  color: Colors.red,
                  onPressed: () {
                    // TODO: Deny mentor request
                  },
                  tooltip: 'Deny Request',
                ),
              ],
            ),
        ],
      ),
    );
  }
} 