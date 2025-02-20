import 'package:flutter/material.dart';

class MeetingNotesScreen extends StatefulWidget {
  final bool isMentor;
  const MeetingNotesScreen({super.key, this.isMentor = true});

  @override
  State<MeetingNotesScreen> createState() => _MeetingNotesScreenState();
}

class _MeetingNotesScreenState extends State<MeetingNotesScreen> {
  String selectedMentee = 'All Mentees';
  String selectedMonth = 'All Time';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement advanced filtering
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Mentee',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedMentee,
                    items: [
                      'All Mentees',
                      'Alice Johnson',
                      'Bob Wilson',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMentee = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedMonth,
                    items: [
                      'All Time',
                      'This Month',
                      'Last Month',
                      'Last 3 Months',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Meeting Notes List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: mockMeetingNotes.length,
              itemBuilder: (context, index) {
                final note = mockMeetingNotes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(note['mentee'].substring(0, 1)),
                        ),
                        title: Text(note['mentee']),
                        subtitle: Text(note['date']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMeetingTypeChip(note['type']),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit),
                                        title: const Text('Edit Notes'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showEditNoteDialog(note);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.share),
                                        title: const Text('Share with Coordinator'),
                                        onTap: () {
                                          // TODO: Implement sharing
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete),
                                        title: const Text('Delete'),
                                        onTap: () {
                                          // TODO: Implement delete
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discussion Topics:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...note['topics'].map<Widget>((topic) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(topic)),
                                ],
                              ),
                            )).toList(),
                            const SizedBox(height: 16),
                            Text(
                              'Action Items (For Me):',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...note['actionItems'].map<Widget>((item) => CheckboxListTile(
                              title: Text(item['task']),
                              subtitle: Text('Due: ${item['dueDate']}'),
                              value: item['completed'],
                              onChanged: (bool? value) {
                                // TODO: Implement checkbox state
                              },
                            )).toList(),
                            if (note['feedback'] != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Feedback:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(note['feedback']),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(),
        label: const Text('New Note'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMeetingTypeChip(String type) {
    Color chipColor;
    switch (type.toLowerCase()) {
      case 'weekly check-in':
        chipColor = Colors.blue;
        break;
      case 'progress review':
        chipColor = Colors.green;
        break;
      case 'urgent meeting':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          type,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: chipColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Meeting Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Mentee',
                  border: OutlineInputBorder(),
                ),
                items: ['Alice Johnson', 'Bob Wilson']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Meeting Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Weekly Check-in', 'Progress Review', 'Urgent Meeting']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Discussion Topics',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Action Items (For Me)',
                  hintText: 'What do I need to do to help my mentee?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(Map<String, dynamic> note) {
    // Similar to _showAddNoteDialog but pre-filled with note data
    // TODO: Implement edit dialog
  }

  // Mock data
  final List<Map<String, dynamic>> mockMeetingNotes = [
    {
      'mentee': 'Alice Johnson',
      'date': 'Feb 15, 2024',
      'type': 'Weekly Check-in',
      'topics': [
        'Discussed progress in Biology coursework',
        'Shared my experience with similar Biology classes',
        'Talked about balancing coursework with campus activities'
      ],
      'actionItems': [
        {
          'task': 'Share my old study guides for BIO201',
          'dueDate': 'Feb 20, 2024',
          'completed': false,
        },
        {
          'task': 'Connect Alice with my Biology study group',
          'dueDate': 'Feb 18, 2024',
          'completed': true,
        }
      ],
      'feedback': 'Alice is adapting well to university life. She reminds me of myself in my first year.',
    },
    {
      'mentee': 'Bob Wilson',
      'date': 'Feb 14, 2024',
      'type': 'Progress Review',
      'topics': [
        'Discussed his transition into Psychology program',
        'Shared my experience with research assistant positions',
        'Talked about joining Psychology Student Association'
      ],
      'actionItems': [
        {
          'task': 'Introduce Bob to Dr. Smith from my research lab',
          'dueDate': 'Feb 28, 2024',
          'completed': false,
        },
        {
          'task': 'Send Bob the link to PSA membership application',
          'dueDate': 'Feb 16, 2024',
          'completed': false,
        }
      ],
      'feedback': 'Bob shows the same enthusiasm for research that I developed in my second year. Excited to help him explore opportunities.',
    },
    {
      'mentee': 'Alice Johnson',
      'date': 'Feb 8, 2024',
      'type': 'Urgent Meeting',
      'topics': [
        'Discussed concerns about group project deadline',
        'Shared my experience with similar group projects',
        'Helped create a workable timeline'
      ],
      'actionItems': [
        {
          'task': 'Share my group project management template',
          'dueDate': 'Feb 9, 2024',
          'completed': true,
        },
        {
          'task': 'Review Alice\'s part of project before group meeting',
          'dueDate': 'Feb 12, 2024',
          'completed': true,
        }
      ],
      'feedback': 'Alice is handling the situation well. Glad I could share my experience with similar group project challenges.',
    },
  ];
} 