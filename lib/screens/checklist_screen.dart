import 'package:flutter/material.dart';

class ChecklistScreen extends StatefulWidget {
  final bool isMentor;
  const ChecklistScreen({super.key, this.isMentor = true});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  String selectedMentee = 'All Mentees';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklists'),
        actions: [
          if (widget.isMentor)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create Custom Checklist',
              onPressed: () => _showCreateChecklistDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isMentor)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Mentee',
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
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSection('Default Checklists', defaultChecklists),
                const SizedBox(height: 24),
                if (widget.isMentor) _buildSection('Custom Checklists', customChecklists),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> checklists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...checklists.map((checklist) => _buildChecklistCard(checklist)).toList(),
      ],
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(checklist['title']),
            subtitle: Text(checklist['description']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isMentor && checklist['isCustom'] == true)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditChecklistDialog(checklist),
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _showChecklistDetails(checklist),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: checklist['progress'],
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${(checklist['progress'] * 100).round()}% Complete',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showChecklistDetails(Map<String, dynamic> checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checklist['title']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...checklist['items'].map<Widget>((item) => CheckboxListTile(
                title: Text(item['title']),
                subtitle: Text(item['description']),
                value: item['completed'],
                onChanged: widget.isMentor ? (bool? value) {
                  // TODO: Implement checkbox state
                } : null,
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (widget.isMentor)
            ElevatedButton(
              onPressed: () {
                // TODO: Save checklist state
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );
  }

  void _showCreateChecklistDialog() {
    List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Custom Checklist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Checklist Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Checklist Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showAddItemDialog(context, (title, description) {
                          setState(() {
                            items.add({
                              'title': title,
                              'description': description,
                              'completed': false,
                            });
                          });
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No items added yet. Click "Add Item" to create your first checklist item.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item['title']),
                        subtitle: Text(
                          item['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditItemDialog(
                                    context,
                                    item['title'],
                                    item['description'],
                                    (title, description) {
                                      setState(() {
                                        items[index]['title'] = title;
                                        items[index]['description'] = description;
                                      });
                                    },
                                  );
                                },
                                constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    items.removeAt(index);
                                  });
                                },
                                constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: items.isEmpty
                  ? null
                  : () {
                      // Add the new checklist to customChecklists
                      final newChecklist = {
                        'title': _titleController.text,
                        'description': _descriptionController.text,
                        'progress': 0.0,
                        'isCustom': true,
                        'items': items,
                      };
                      setState(() {
                        customChecklists.add(newChecklist);
                      });
                      _titleController.clear();
                      _descriptionController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checklist created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(
    BuildContext context,
    Function(String title, String description) onAdd,
  ) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Checklist Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (titleController.text.isNotEmpty) {
                onAdd(titleController.text, descriptionController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    String currentTitle,
    String currentDescription,
    Function(String title, String description) onEdit,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Checklist Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (titleController.text.isNotEmpty) {
                onEdit(titleController.text, descriptionController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditChecklistDialog(Map<String, dynamic> checklist) {
    // Similar to create dialog but pre-filled
  }

  // Mock data
  final List<Map<String, dynamic>> defaultChecklists = [
    {
      'title': 'Initial Mentorship Setup',
      'description': 'Essential tasks for starting the mentorship relationship',
      'progress': 0.4,
      'isCustom': false,
      'items': [
        {
          'title': 'First Meeting Completed',
          'description': 'Introductory meeting with mentee',
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
      'isCustom': false,
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
  ];

  final List<Map<String, dynamic>> customChecklists = [
    {
      'title': 'Research Project Guidance',
      'description': 'Steps for mentoring through research project',
      'progress': 0.6,
      'isCustom': true,
      'items': [
        {
          'title': 'Topic Selection',
          'description': 'Help mentee choose research topic',
          'completed': true,
        },
        {
          'title': 'Literature Review',
          'description': 'Guide through literature review process',
          'completed': true,
        },
        {
          'title': 'Methodology Planning',
          'description': 'Assist with research methodology',
          'completed': false,
        },
        {
          'title': 'Data Collection',
          'description': 'Support during data collection phase',
          'completed': false,
        },
      ],
    },
  ];
} 