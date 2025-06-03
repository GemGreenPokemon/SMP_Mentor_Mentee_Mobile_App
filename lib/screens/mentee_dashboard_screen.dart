import 'package:flutter/material.dart';
import 'dart:async';
import 'chat_screen.dart';
import 'schedule_meeting_screen.dart';
import 'resource_hub_screen.dart';
import 'settings_screen.dart';
import 'checklist_screen.dart';
import 'mentee_checklist_screen.dart';
import 'checkin_checkout_screen.dart';
import 'meeting_notes_screen.dart';
import 'newsletter_screen.dart';
import 'announcement_screen.dart';
import '../services/mentee_service.dart';
import '../utils/test_mode_manager.dart';
import '../utils/developer_session.dart';
import 'package:provider/provider.dart';

class MenteeDashboardScreen extends StatefulWidget {
  const MenteeDashboardScreen({super.key});

  @override
  State<MenteeDashboardScreen> createState() => _MenteeDashboardScreenState();
}

class _MenteeDashboardScreenState extends State<MenteeDashboardScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize mentee service to load database data if in test mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menteeService = Provider.of<MenteeService>(context, listen: false);
      menteeService.initialize();
    });
    
    // Set up periodic refresh for real-time updates (every 3 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (mounted && TestModeManager.isTestMode) {
        final menteeService = Provider.of<MenteeService>(context, listen: false);
        // Silent refresh - don't show loading indicator
        await menteeService.silentRefresh();
        print('DEBUG: Dashboard auto-refresh completed at ${DateTime.now()}');
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh when app comes to foreground
      final menteeService = Provider.of<MenteeService>(context, listen: false);
      menteeService.silentRefresh();
      print('DEBUG: App resumed, refreshing dashboard...');
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menteeService = Provider.of<MenteeService>(context);
    
    // Show loading indicator while data is being loaded
    if (menteeService.isLoading) {
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
            const Text('Mentee Dashboard'),
            Text(
              menteeService.menteeProfile['name'] ?? 'Mentee',
              style: const TextStyle(
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
      body: RefreshIndicator(
        onRefresh: () async {
          await menteeService.refresh();
          if (mounted) {
            setState(() {}); // Force UI rebuild
          }
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
          // Mentor Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(menteeService.mentorInfo['name'] ?? 'No Mentor Assigned'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(menteeService.mentorInfo['role'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          'Assigned since ${menteeService.mentorInfo['assignedDate'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        // Pass IDs for proper message routing
                        final currentMenteeId = TestModeManager.isTestMode && TestModeManager.currentTestMentee != null
                            ? TestModeManager.currentTestMentee!.id
                            : null;
                        final mentorId = menteeService.mentorInfo['id'] as String?;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              recipientName: menteeService.mentorInfo['name'] ?? 'Mentor',
                              recipientRole: menteeService.mentorInfo['role'] ?? '',
                              currentUserId: currentMenteeId,
                              recipientId: mentorId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
                  _buildAnnouncementItem(
                    'Upcoming Workshop',
                    'Join us for a career development workshop next week.',
                    '2 hours ago',
                    menteeService.announcements.isNotEmpty ? menteeService.announcements[0]['priority'] : null,
                  ),
                  const Divider(),
                  _buildAnnouncementItem(
                    'Program Update',
                    'New resources have been added to the hub.',
                    '1 day ago',
                    menteeService.announcements.length > 1 ? menteeService.announcements[1]['priority'] : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress Section
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          
          // Quick Actions
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                context,
                'Schedule Meeting',
                Icons.calendar_today,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleMeetingScreen(isMentor: false),
                    ),
                  );
                  // Refresh when returning
                  if (mounted) {
                    print('DEBUG: Returned from schedule screen (quick action), refreshing...');
                    setState(() {}); // Force UI rebuild
                    final menteeService = Provider.of<MenteeService>(context, listen: false);
                    await menteeService.refresh();
                    // Silent refresh after short delay
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      if (mounted) {
                        await menteeService.silentRefresh();
                        print('DEBUG: Secondary silent refresh completed (quick action)');
                      }
                    });
                  }
                },
              ),
              _buildQuickActionCard(
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
              _buildQuickActionCard(
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
              _buildQuickActionCard(
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
              _buildQuickActionCard(
                context,
                'Newsletters',
                Icons.newspaper_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewsletterScreen(isMentor: false),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // My Meetings Card - Combined view with tabs
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
                        'My Meetings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScheduleMeetingScreen(isMentor: false),
                                ),
                              );
                              // Refresh when returning from schedule screen
                              if (mounted) {
                                print('DEBUG: Returned from schedule screen, refreshing...');
                                setState(() {}); // Force UI rebuild
                                await menteeService.refresh();
                                // Silent refresh after short delay to catch any delayed DB writes
                                Future.delayed(const Duration(milliseconds: 500), () async {
                                  if (mounted) {
                                    await menteeService.silentRefresh();
                                    print('DEBUG: Secondary silent refresh completed');
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Schedule'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Meeting Statistics
                  Row(
                    children: [
                      _buildMeetingStatChip(
                        'Confirmed',
                        menteeService.upcomingMeetings.where((m) => m['status'] == 'accepted').length,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildMeetingStatChip(
                        'Pending',
                        menteeService.upcomingMeetings.where((m) => m['status'] == 'pending').length,
                        Colors.blue[600]!,
                      ),
                      const SizedBox(width: 8),
                      _buildMeetingStatChip(
                        'Total',
                        menteeService.upcomingMeetings.length,
                        Colors.grey[600]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Meetings List
                  Builder(
                    builder: (context) {
                      if (menteeService.upcomingMeetings.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No meetings scheduled',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Request a meeting with your mentor',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      }
                      
                      // Debug: log all meetings
                      print('DEBUG MenteeDashboard BUILD: Total meetings: ${menteeService.upcomingMeetings.length}');
                      print('DEBUG MenteeDashboard BUILD: Timestamp: ${DateTime.now()}');
                      for (final meeting in menteeService.upcomingMeetings) {
                        print('  Meeting: ${meeting['title']} - ${meeting['status']} - ${meeting['date']} ${meeting['time']} - ID: ${meeting['id']}');
                      }
                      
                      // Group meetings by status
                      final confirmedMeetings = menteeService.upcomingMeetings
                          .where((m) => m['status'] == 'accepted')
                          .toList();
                      final pendingMeetings = menteeService.upcomingMeetings
                          .where((m) => m['status'] == 'pending')
                          .toList();
                      final rejectedMeetings = menteeService.upcomingMeetings
                          .where((m) => m['status'] == 'rejected')
                          .toList();
                      
                      // Show only the most recent meetings
                      const maxDisplay = 1; // Show only 1 of each type
                      final hasOverflow = confirmedMeetings.length > maxDisplay || 
                                         pendingMeetings.length > maxDisplay || 
                                         rejectedMeetings.length > maxDisplay;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Next Confirmed Meeting (if any)
                          if (confirmedMeetings.isNotEmpty) ...[
                            _buildSectionHeader('Next Confirmed Meeting', Colors.green),
                            _buildMeetingCard(
                              confirmedMeetings.first,
                              Colors.green,
                              showCheckIn: true,
                            ),
                            if (confirmedMeetings.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 8),
                                child: Text(
                                  '+${confirmedMeetings.length - 1} more confirmed',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                          
                          // Latest Pending Request (if any)
                          if (pendingMeetings.isNotEmpty) ...[
                            _buildSectionHeader('Latest Pending Request', Colors.blue[600]!),
                            _buildMeetingCard(
                              pendingMeetings.first,
                              Colors.blue[600]!,
                              showCheckIn: false,
                            ),
                            if (pendingMeetings.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 8),
                                child: Text(
                                  '+${pendingMeetings.length - 1} more pending',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                          
                          // Most Recent Rejection (if any)
                          if (rejectedMeetings.isNotEmpty) ...[
                            _buildSectionHeader('Recent Rejection', Colors.red),
                            _buildMeetingCard(
                              rejectedMeetings.first,
                              Colors.red,
                              showCheckIn: false,
                            ),
                            if (rejectedMeetings.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 8),
                                child: Text(
                                  '+${rejectedMeetings.length - 1} more rejected',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                          
                          // View All Button if there's overflow
                          if (hasOverflow) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ScheduleMeetingScreen(isMentor: false),
                                    ),
                                  );
                                  // Refresh when returning
                                  if (mounted) {
                                    setState(() {}); // Force UI rebuild
                                    final menteeService = Provider.of<MenteeService>(context, listen: false);
                                    await menteeService.refresh();
                                    // Silent refresh after delay
                                    Future.delayed(const Duration(milliseconds: 500), () async {
                                      if (mounted) {
                                        await menteeService.silentRefresh();
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_view_day),
                                label: const Text('View All Meetings'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting, Color statusColor, {required bool showCheckIn}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: statusColor.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            meeting['status'] == 'accepted' ? Icons.event_available :
            meeting['status'] == 'pending' ? Icons.schedule :
            Icons.event_busy,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          meeting['title'] ?? 'Meeting with Mentor',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${meeting['date']} at ${meeting['time']}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meeting['location'] ?? 'TBD',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (meeting['status'] == 'rejected') ...[
              const SizedBox(height: 4),
              Text(
                'Consider scheduling a new time',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: showCheckIn ? SizedBox(
          width: 100,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckInCheckOutScreen(
                    meetingTitle: meeting['title'] ?? 'Meeting',
                    mentorName: meeting['withMentor'] ?? 'Mentor',
                    location: meeting['location'] ?? 'TBD',
                    scheduledTime: '${meeting['date']} ${meeting['time']}',
                    isMentor: false,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: statusColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Check In',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ) : null,
      ),
    );
  }
} 