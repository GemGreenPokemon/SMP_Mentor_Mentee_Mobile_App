import 'package:flutter/material.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor-Mentee Assignments'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Active Mentors', '12'),
                  _buildStatItem('Active Mentees', '36'),
                  _buildStatItem('Unassigned', '5'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mentors List
          ...mentors.map((mentor) => _buildMentorCard(mentor)).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignmentDialog(),
        label: const Text('New Assignment'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(mentor['name'].substring(0, 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mentor['role'],
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMenteeCountColor(mentor['mentees'].length),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${mentor['mentees'].length}/3 Mentees',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (mentor['mentees'].isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...mentor['mentees'].map<Widget>((mentee) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mentee['name']),
                          Text(
                            mentee['program'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      mentee['assignedDate'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMenteeCountColor(int count) {
    if (count >= 3) return Colors.red;
    if (count >= 2) return Colors.orange;
    return Colors.green;
  }

  void _showAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Mentor-Mentee Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Mentor',
                border: OutlineInputBorder(),
              ),
              items: mentors
                  .where((mentor) => mentor['mentees'].length < 3)
                  .map((mentor) => DropdownMenuItem(
                        value: mentor['name'],
                        child: Text(
                            '${mentor['name']} (${mentor['mentees'].length}/3 mentees)'),
                      ))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Mentee',
                border: OutlineInputBorder(),
              ),
              items: unassignedMentees
                  .map((mentee) => DropdownMenuItem(
                        value: mentee['name'],
                        child: Text(
                            '${mentee['name']} - ${mentee['program']}'),
                      ))
                  .toList(),
              onChanged: (_) {},
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
              // TODO: Implement assignment logic
              Navigator.pop(context);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // Mock data
  final List<Map<String, dynamic>> mentors = [
    {
      'name': 'Sarah Martinez',
      'role': '3rd Year, Computer Science Major',
      'mentees': [
        {
          'name': 'Alice Johnson',
          'program': '1st Year, Biology Major',
          'assignedDate': 'Feb 1, 2024',
        },
        {
          'name': 'Tom Wilson',
          'program': '1st Year, Computer Science',
          'assignedDate': 'Jan 15, 2024',
        },
      ],
    },
    {
      'name': 'John Davis',
      'role': '4th Year, Biology Major',
      'mentees': [
        {
          'name': 'Bob Wilson',
          'program': '2nd Year, Psychology Major',
          'assignedDate': 'Feb 5, 2024',
        },
      ],
    },
    {
      'name': 'Emily Wilson',
      'role': '3rd Year, Psychology Major',
      'mentees': [
        {
          'name': 'James Smith',
          'program': '1st Year, Psychology Major',
          'assignedDate': 'Jan 20, 2024',
        },
        {
          'name': 'Maria Garcia',
          'program': '2nd Year, Biology Major',
          'assignedDate': 'Feb 3, 2024',
        },
        {
          'name': 'David Lee',
          'program': '1st Year, Computer Science',
          'assignedDate': 'Feb 7, 2024',
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> unassignedMentees = [
    {
      'name': 'Michael Brown',
      'program': '1st Year, Computer Science',
    },
    {
      'name': 'Lisa Chen',
      'program': '2nd Year, Biology',
    },
    {
      'name': 'James Wilson',
      'program': '1st Year, Psychology',
    },
  ];
} 