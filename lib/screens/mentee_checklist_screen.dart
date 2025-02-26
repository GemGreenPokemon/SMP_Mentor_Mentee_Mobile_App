import 'package:flutter/material.dart';

class MenteeChecklistScreen extends StatefulWidget {
  const MenteeChecklistScreen({super.key});

  @override
  State<MenteeChecklistScreen> createState() => _MenteeChecklistScreenState();
}

class _MenteeChecklistScreenState extends State<MenteeChecklistScreen> {
  // Mock data for assigned checklists
  final List<Map<String, dynamic>> assignedChecklists = [
    {
      'title': 'Initial Mentorship Setup',
      'description': 'Essential tasks for starting the mentorship relationship',
      'progress': 0.4,
      'assignedBy': 'Sarah Martinez',
      'assignedDate': 'Feb 15, 2024',
      'dueDate': 'Mar 15, 2024',
      'priority': 'High',
      'items': [
        {
          'title': 'First Meeting Completed',
          'description': 'Introductory meeting with mentor',
          'completed': true,
        },
        {
          'title': 'Program Overview Discussed',
          'description': 'Review program expectations and guidelines',
          'completed': true,
        },
        {
          'title': 'Goals Established',
          'description': 'Set academic and personal development goals',
          'completed': false,
        },
        {
          'title': 'Communication Preferences Set',
          'description': 'Establish preferred contact methods and times',
          'completed': false,
        },
        {
          'title': 'Resource Access Confirmed',
          'description': 'Ensure access to necessary program resources',
          'completed': false,
        },
      ],
    },
    {
      'title': 'Monthly Progress Review',
      'description': 'Regular check-in items for tracking progress',
      'progress': 0.0,
      'assignedBy': 'Sarah Martinez',
      'assignedDate': 'Feb 20, 2024',
      'dueDate': 'Mar 20, 2024',
      'priority': 'Medium',
      'items': [
        {
          'title': 'Academic Progress Review',
          'description': 'Discuss current academic performance',
          'completed': false,
        },
        {
          'title': 'Goals Progress Check',
          'description': 'Review progress on established goals',
          'completed': false,
        },
        {
          'title': 'Resource Utilization',
          'description': 'Evaluate use of available resources',
          'completed': false,
        },
        {
          'title': 'Challenges Discussion',
          'description': 'Address any current challenges or concerns',
          'completed': false,
        },
      ],
    },
    {
      'title': 'Research Project Guidance',
      'description': 'Steps for completing your research project',
      'progress': 0.25,
      'assignedBy': 'Sarah Martinez',
      'assignedDate': 'Feb 25, 2024',
      'dueDate': 'Apr 25, 2024',
      'priority': 'Low',
      'items': [
        {
          'title': 'Topic Selection',
          'description': 'Choose a research topic',
          'completed': true,
        },
        {
          'title': 'Literature Review',
          'description': 'Complete literature review process',
          'completed': false,
        },
        {
          'title': 'Methodology Planning',
          'description': 'Develop research methodology',
          'completed': false,
        },
        {
          'title': 'Data Collection',
          'description': 'Collect necessary data for your research',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View All Checklists',
            onPressed: () {
              _showAllChecklistsDialog();
            },
          ),
        ],
      ),
      body: assignedChecklists.isEmpty
          ? const Center(
              child: Text(
                'No checklists assigned yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Focus message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Focus on one checklist at a time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'We\'re showing you the most urgent checklist. Tap "View All" to see others.',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Active checklist
                  _buildActiveChecklist(assignedChecklists[_activeChecklistIndex]),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveChecklist(Map<String, dynamic> checklist) {
    // Calculate progress based on completed items
    final totalItems = checklist['items'].length;
    final completedItems = checklist['items'].where((item) => item['completed'] == true).length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    
    // Get priority color
    Color priorityColor;
    switch(checklist['priority']) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checklist header
        Row(
          children: [
            Expanded(
              child: Text(
                checklist['title'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priorityColor),
              ),
              child: Text(
                '${checklist['priority']} Priority',
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          checklist['description'],
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        
        // Due date and assignment info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned by: ${checklist['assignedBy']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Due: ${checklist['dueDate']}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Progress section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}% Complete',
                  style: TextStyle(
                    color: progress == 1.0 ? Colors.green : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.withOpacity(0.1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${completedItems}/${totalItems} tasks completed',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tasks section
        const Text(
          'Tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Task list
        ...checklist['items'].asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              title: Text(
                item['title'],
                style: TextStyle(
                  decoration: item['completed'] ? TextDecoration.lineThrough : null,
                  color: item['completed'] ? Colors.grey : Colors.black,
                  fontWeight: item['completed'] ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['description']),
                  if (item['completed'] == true && item['proof'] == null)
                    TextButton.icon(
                      onPressed: () => _showProofSubmissionDialog(checklist, index),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Submit Proof', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (item['proof'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item['proofStatus'] == 'approved'
                                    ? Icons.check_circle
                                    : item['proofStatus'] == 'rejected'
                                        ? Icons.cancel
                                        : Icons.pending,
                                color: item['proofStatus'] == 'approved'
                                    ? Colors.green
                                    : item['proofStatus'] == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Proof submitted: ${item['proof']} (${item['proofStatus'] == 'approved' ? 'Approved' : item['proofStatus'] == 'rejected' ? 'Rejected' : 'Pending approval'})',
                                  style: TextStyle(
                                    color: item['proofStatus'] == 'approved'
                                        ? Colors.green
                                        : item['proofStatus'] == 'rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item['proofStatus'] == 'rejected' && item['feedback'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 20.0),
                              child: Text(
                                'Mentor feedback: ${item['feedback']}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          if (item['proofStatus'] == 'rejected')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 20.0),
                              child: TextButton.icon(
                                onPressed: () => _showProofSubmissionDialog(checklist, index),
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text('Resubmit Proof', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 24),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
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
              secondary: item['completed']
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.circle_outlined),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        // Save progress button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Save Progress'),
          ),
        ),
      ],
    );
  }

  void _showAllChecklistsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Checklists'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: assignedChecklists.length,
            itemBuilder: (context, index) {
              final checklist = assignedChecklists[index];
              final isActive = index == _activeChecklistIndex;
              
              // Get priority color
              Color priorityColor;
              switch(checklist['priority']) {
                case 'High':
                  priorityColor = Colors.red;
                  break;
                case 'Medium':
                  priorityColor = Colors.orange;
                  break;
                default:
                  priorityColor = Colors.green;
              }
              
              return ListTile(
                title: Text(
                  checklist['title'],
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('Due: ${checklist['dueDate']}'),
                leading: CircleAvatar(
                  backgroundColor: priorityColor.withOpacity(0.2),
                  child: Text(
                    '${(checklist['progress'] * 100).round()}%',
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                trailing: isActive 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                selected: isActive,
                onTap: () {
                  setState(() {
                    _activeChecklistIndex = index;
                  });
                  Navigator.pop(context);
                },
              );
            },
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

  void _showProofSubmissionDialog(Map<String, dynamic> checklist, int itemIndex) {
    final TextEditingController proofController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Proof of Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Task: ${checklist['items'][itemIndex]['title']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please describe how you completed this task or upload evidence:',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: proofController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // In a real app, this would open a file picker
                // For now, we'll just simulate uploading a file
                proofController.text += ' (Screenshot attached)';
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('Attach File'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (proofController.text.isNotEmpty) {
                setState(() {
                  checklist['items'][itemIndex]['proof'] = proofController.text;
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
              } else {
                // Show error if no proof is provided
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide proof of completion.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
} 