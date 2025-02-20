import 'package:flutter/material.dart';

class ProgressReportsScreen extends StatefulWidget {
  const ProgressReportsScreen({super.key});

  @override
  State<ProgressReportsScreen> createState() => _ProgressReportsScreenState();
}

class _ProgressReportsScreenState extends State<ProgressReportsScreen> {
  String selectedMentee = 'All Mentees';
  String selectedPeriod = 'Current Semester';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Progress Reports'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress reports help you track your mentees\' development over time. Use them to:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• Document achievements and challenges'),
                      Text('• Set and track goals'),
                      Text('• Identify areas needing more support'),
                      Text('• Share updates with the program coordinator'),
                      SizedBox(height: 16),
                      Text(
                        'Regular updates help ensure your mentees are getting the most out of the mentoring program.',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
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
                    value: selectedPeriod,
                    items: [
                      'Current Semester',
                      'Last Semester',
                      'Academic Year',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPeriod = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Progress Reports List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: mockProgressReports.length,
              itemBuilder: (context, index) {
                final report = mockProgressReports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(report['mentee'].substring(0, 1)),
                        ),
                        title: Text(report['mentee']),
                        subtitle: Text('Report for ${report['period']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusChip(report['status']),
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
                                        title: const Text('Edit Report'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showEditReportDialog(report);
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
                                        leading: const Icon(Icons.print),
                                        title: const Text('Export as PDF'),
                                        onTap: () {
                                          // TODO: Implement PDF export
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
                            _buildProgressSection(
                              'Academic Progress',
                              report['academicProgress'],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressSection(
                              'Goals Progress',
                              report['goalsProgress'],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressSection(
                              'Areas of Growth',
                              report['areasOfGrowth'],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressSection(
                              'Areas Needing Support',
                              report['areasNeedingSupport'],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Next Steps:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...report['nextSteps'].map<Widget>((step) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(step)),
                                ],
                              ),
                            )).toList(),
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
        onPressed: () => _showAddReportDialog(),
        label: const Text('New Report'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'on track':
        chipColor = Colors.green;
        break;
      case 'needs attention':
        chipColor = Colors.orange;
        break;
      case 'at risk':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          status,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: chipColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildProgressSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(item)),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showAddReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Progress Report'),
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
                  labelText: 'Overall Status',
                  border: OutlineInputBorder(),
                ),
                items: ['On Track', 'Needs Attention', 'At Risk']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Academic Progress',
                  hintText: 'How is your mentee doing academically?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Goals Progress',
                  hintText: 'Progress on previously set goals',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Areas of Growth',
                  hintText: 'What improvements have you observed?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Areas Needing Support',
                  hintText: 'Where does your mentee need more help?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Next Steps',
                  hintText: 'What are the next goals/actions?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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

  void _showEditReportDialog(Map<String, dynamic> report) {
    // Similar to _showAddReportDialog but pre-filled with report data
    // TODO: Implement edit dialog
  }

  // Mock data
  final List<Map<String, dynamic>> mockProgressReports = [
    {
      'mentee': 'Alice Johnson',
      'period': 'February 2024',
      'status': 'On Track',
      'academicProgress': [
        'Maintaining strong grades in Biology courses',
        'Successfully managing lab work and assignments',
        'Active participation in study groups'
      ],
      'goalsProgress': [
        'Achieved goal of joining Biology Club',
        'Improved time management skills',
        'Building stronger relationships with professors'
      ],
      'areasOfGrowth': [
        'More confident in lab sessions',
        'Taking initiative in group projects',
        'Better at balancing academics and activities'
      ],
      'areasNeedingSupport': [
        'Could use help with research paper formatting',
        'Wants to explore research opportunities',
        'Seeking advice on summer internships'
      ],
      'nextSteps': [
        'Help review research paper draft',
        'Connect with Biology department about research openings',
        'Share internship application tips'
      ]
    },
    {
      'mentee': 'Bob Wilson',
      'period': 'February 2024',
      'status': 'Needs Attention',
      'academicProgress': [
        'Good understanding of Psychology concepts',
        'Struggling with statistics component',
        'Regular attendance in all classes'
      ],
      'goalsProgress': [
        'Applied for Psychology Student Association',
        'Started attending department seminars',
        'Working on research skills'
      ],
      'areasOfGrowth': [
        'More engaged in class discussions',
        'Developing better study habits',
        'Growing interest in research methodology'
      ],
      'areasNeedingSupport': [
        'Needs help with statistics coursework',
        'Looking for study group for Research Methods class',
        'Wants to improve academic writing'
      ],
      'nextSteps': [
        'Set up weekly statistics study sessions',
        'Introduce to my study group',
        'Share academic writing resources'
      ]
    }
  ];
} 