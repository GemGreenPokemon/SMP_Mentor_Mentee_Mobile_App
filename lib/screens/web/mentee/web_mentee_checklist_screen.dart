import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';

class WebMenteeChecklistScreen extends StatefulWidget {
  const WebMenteeChecklistScreen({super.key});

  @override
  State<WebMenteeChecklistScreen> createState() => _WebMenteeChecklistScreenState();
}

class _WebMenteeChecklistScreenState extends State<WebMenteeChecklistScreen> {
  // Mock data for assigned checklists
  final List<Map<String, dynamic>> assignedChecklists = [
    {
      'title': 'Academic Success Foundations',
      'description': 'Essential tasks for building strong academic habits',
      'progress': 0.4,
      'assignedBy': 'Sarah Martinez',
      'assignedDate': 'Feb 15, 2024',
      'dueDate': 'Mar 15, 2024',
      'priority': 'High',
      'items': [
        {
          'title': 'Study Schedule Created',
          'description': 'Create a weekly study schedule with dedicated time blocks for each course',
          'completed': true,
        },
        {
          'title': 'Course Resources Accessed',
          'description': 'Access all course materials and understand where to find help for each class',
          'completed': true,
        },
        {
          'title': 'Study Group Participation',
          'description': 'Join or form at least one study group for a challenging course',
          'completed': false,
        },
        {
          'title': 'Office Hours Plan',
          'description': 'Schedule and attend at least one office hours session for each course',
          'completed': false,
        },
        {
          'title': 'Academic Support Services',
          'description': 'Visit the tutoring center and identify available academic support resources',
          'completed': false,
        },
      ],
    },
    {
      'title': 'Time Management Skills',
      'description': 'Developing effective time management strategies',
      'progress': 0.0,
      'assignedBy': 'Sarah Martinez',
      'assignedDate': 'Feb 20, 2024',
      'dueDate': 'Mar 20, 2024',
      'priority': 'Medium',
      'items': [
        {
          'title': 'Daily Planner Setup',
          'description': 'Set up and start using a daily planner or digital calendar',
          'completed': false,
        },
        {
          'title': 'Assignment Tracking',
          'description': 'Create a system to track all assignments and due dates',
          'completed': false,
        },
        {
          'title': 'Study-Life Balance',
          'description': 'Plan dedicated time for both studying and self-care activities',
          'completed': false,
        },
        {
          'title': 'Procrastination Management',
          'description': 'Identify procrastination triggers and develop strategies to overcome them',
          'completed': false,
        },
      ],
    },
    {
      'title': 'Course Success Strategy',
      'description': 'Steps for excelling in your current courses',
      'progress': 0.25,
      'assignedBy': 'Sarah Martinez',
      'assignedDate': 'Feb 25, 2024',
      'dueDate': 'Apr 25, 2024',
      'priority': 'Low',
      'items': [
        {
          'title': 'Note-Taking System',
          'description': 'Develop an effective note-taking system for each class',
          'completed': true,
        },
        {
          'title': 'Test Preparation',
          'description': 'Create study guides and practice tests for upcoming exams',
          'completed': false,
        },
        {
          'title': 'Assignment Planning',
          'description': 'Break down major assignments into smaller, manageable tasks',
          'completed': false,
        },
        {
          'title': 'Grade Monitoring',
          'description': 'Regularly check grades and identify areas needing improvement',
          'completed': false,
        },
      ],
    },
  ];

  // Index of the currently active checklist
  int _activeChecklistIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Sort checklists by due date (closest first)
    assignedChecklists.sort((a, b) {
      // This is a simple string comparison - in a real app, you'd parse the dates
      return a['dueDate'].compareTo(b['dueDate']);
    });
    
    // Add a rejected proof example with feedback
    assignedChecklists[0]['items'][2]['completed'] = true;
    assignedChecklists[0]['items'][2]['proof'] = 'Goals document';
    assignedChecklists[0]['items'][2]['proofStatus'] = 'rejected';
    assignedChecklists[0]['items'][2]['feedback'] = 'Please be more specific about your academic goals.';
    
    // Add an approved proof example
    assignedChecklists[0]['items'][0]['proof'] = 'Meeting notes from Feb 15';
    assignedChecklists[0]['items'][0]['proofStatus'] = 'approved';
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    // Calculate overall progress
    double totalProgress = 0;
    int totalItems = 0;
    int completedItems = 0;
    
    for (var checklist in assignedChecklists) {
      totalItems += (checklist['items'] as List).length;
      completedItems += (checklist['items'] as List).where((item) => item['completed'] == true).length;
    }
    
    if (totalItems > 0) {
      totalProgress = completedItems / totalItems;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Checklists'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Overall Progress: ${(totalProgress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: assignedChecklists.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Focus message card
                        Card(
                          elevation: 2,
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Focus on one checklist at a time',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Complete tasks in priority order to maximize your progress and stay on track with your mentorship goals.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Checklist tabs
                        if (isDesktop || isTablet) ...[
                          DefaultTabController(
                            length: assignedChecklists.length,
                            child: Column(
                              children: [
                                TabBar(
                                  isScrollable: true,
                                  labelColor: const Color(0xFF0F2D52),
                                  unselectedLabelColor: Colors.grey[600],
                                  indicatorColor: const Color(0xFF0F2D52),
                                  tabs: assignedChecklists.map((checklist) {
                                    return Tab(
                                      child: _buildTabLabel(checklist),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 600, // Fixed height for tab content
                                  child: TabBarView(
                                    children: assignedChecklists.map((checklist) {
                                      return _buildChecklistContent(checklist);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Mobile view - show one checklist at a time
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _activeChecklistIndex > 0
                                            ? () {
                                                setState(() {
                                                  _activeChecklistIndex--;
                                                });
                                              }
                                            : null,
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${_activeChecklistIndex + 1} of ${assignedChecklists.length}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: _activeChecklistIndex < assignedChecklists.length - 1
                                            ? () {
                                                setState(() {
                                                  _activeChecklistIndex++;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildChecklistContent(assignedChecklists[_activeChecklistIndex]),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // All checklists overview (desktop only)
                        if (isDesktop) ...[
                          const Text(
                            'All Checklists Overview',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChecklistsGrid(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No checklists assigned yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your mentor will assign checklists to help guide your progress.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel(Map<String, dynamic> checklist) {
    Color priorityColor = _getPriorityColor(checklist['priority']);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(checklist['title']),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: checklist['progress'] == 1.0 
                ? Colors.green.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(checklist['progress'] * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: checklist['progress'] == 1.0 ? Colors.green : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistContent(Map<String, dynamic> checklist) {
    // Calculate progress based on completed items
    final totalItems = checklist['items'].length;
    final completedItems = checklist['items'].where((item) => item['completed'] == true).length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checklist header
          _buildChecklistHeader(checklist, progress, completedItems, totalItems),
          
          const SizedBox(height: 24),
          
          // Progress visualization
          _buildProgressSection(progress, completedItems, totalItems),
          
          const SizedBox(height: 32),
          
          // Tasks section
          const Text(
            'Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Task list
          ...checklist['items'].asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildTaskItem(checklist, item, index);
          }).toList(),
          
          const SizedBox(height: 32),
          
          // Save progress button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Progress'),
              onPressed: () {
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistHeader(Map<String, dynamic> checklist, double progress, int completedItems, int totalItems) {
    Color priorityColor = _getPriorityColor(checklist['priority']);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              checklist['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: priorityColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag,
                                  size: 16,
                                  color: priorityColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${checklist['priority']} Priority',
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        checklist['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.person,
                    'Assigned by',
                    checklist['assignedBy'],
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    'Assigned on',
                    checklist['assignedDate'],
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.event_available,
                    'Due date',
                    checklist['dueDate'],
                    isHighlighted: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? Colors.red : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isHighlighted ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(double progress, int completedItems, int totalItems) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: progress == 1.0 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: progress == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                  child: Text(
                    progress == 1.0 ? 'Completed!' : '${(progress * 100).round()}% Complete',
                    style: TextStyle(
                      color: progress == 1.0 ? Colors.green[700] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? Colors.green : Colors.blue,
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$completedItems out of $totalItems tasks completed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> checklist, Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: item['completed'],
            onChanged: (bool? value) {
              setState(() {
                checklist['items'][index]['completed'] = value;
                
                // Recalculate progress
                final totalItems = checklist['items'].length;
                final completedItems = checklist['items'].where((item) => item['completed'] == true).length;
                final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
                checklist['progress'] = progress;
              });
            },
            activeColor: const Color(0xFF0F2D52),
          ),
          title: Text(
            item['title'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: item['completed'] ? TextDecoration.lineThrough : null,
              color: item['completed'] ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Text(
            item['description'],
            style: TextStyle(
              fontSize: 14,
              color: item['completed'] ? Colors.grey[400] : Colors.grey[600],
              decoration: item['completed'] ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  if (item['completed'] == true) ...[
                    const SizedBox(height: 16),
                    if (item['proof'] == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Proof of completion required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showProofSubmissionDialog(checklist, index),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Submit Proof'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item['proof'] != null)
                      _buildProofSection(item, checklist, index),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection(Map<String, dynamic> item, Map<String, dynamic> checklist, int index) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (item['proofStatus']) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Review';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Proof $statusText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attachment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['proof'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          if (item['proofStatus'] == 'rejected' && item['feedback'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.feedback, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Mentor Feedback:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['feedback'],
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showProofSubmissionDialog(checklist, index),
              icon: const Icon(Icons.refresh),
              label: const Text('Resubmit Proof'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: assignedChecklists.length,
      itemBuilder: (context, index) {
        final checklist = assignedChecklists[index];
        return _buildChecklistCard(checklist, index);
      },
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist, int index) {
    final completedItems = checklist['items'].where((item) => item['completed'] == true).length;
    final totalItems = checklist['items'].length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    Color priorityColor = _getPriorityColor(checklist['priority']);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showChecklistDetailsDialog(checklist),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      checklist['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                checklist['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              
              // Due date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${checklist['dueDate']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedItems of $totalItems',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: progress == 1.0 ? Colors.green : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : Colors.blue,
                      ),
                      minHeight: 6,
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

  void _showChecklistDetailsDialog(Map<String, dynamic> checklist) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: Responsive.isDesktop(context) ? 800 : 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2D52),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checklist['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            checklist['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: _buildChecklistContent(checklist),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProofSubmissionDialog(Map<String, dynamic> checklist, int itemIndex) {
    final TextEditingController proofController = TextEditingController();
    String? selectedFile;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.upload_file,
                      color: Color(0xFF0F2D52),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Submit Proof of Completion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Task info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        checklist['items'][itemIndex]['title'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Description of completion:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: proofController,
                  decoration: const InputDecoration(
                    hintText: 'Describe how you completed this task...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                
                // File upload section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // In a real app, this would open a file picker
                          setState(() {
                            selectedFile = 'screenshot_evidence.png';
                          });
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Choose File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(selectedFile!),
                          onDeleted: () {
                            setState(() {
                              selectedFile = null;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Accepted formats: PDF, DOC, DOCX, PNG, JPG, JPEG',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (proofController.text.isEmpty && selectedFile == null)
                          ? null
                          : () {
                              String proof = proofController.text;
                              if (selectedFile != null) {
                                proof = proof.isEmpty ? selectedFile! : '$proof (File: $selectedFile)';
                              }
                              
                              setState(() {
                                checklist['items'][itemIndex]['proof'] = proof;
                                checklist['items'][itemIndex]['proofStatus'] = 'pending';
                              });
                              Navigator.pop(context);
                              
                              // Show confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Proof submitted successfully! Waiting for mentor approval.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2D52),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit Proof'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch(priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}