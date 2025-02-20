import 'package:flutter/material.dart';
import 'settings_screen.dart';

class ResourceHubScreen extends StatefulWidget {
  final bool isMentor;
  const ResourceHubScreen({super.key, this.isMentor = true});

  @override
  State<ResourceHubScreen> createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen> with SingleTickerProviderStateMixin {
  String selectedCategory = 'All Resources';
  late TabController _tabController;
  final List<String> _tabTitles = ['General Resources', 'Documents', 'Newsletter'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitles[_tabController.index]),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Documents'),
              Tab(text: 'Newsletter'),
            ],
          ),
          actions: [
            if (widget.isMentor)
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Upload Resource',
                onPressed: () => _showUploadDialog(),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(isMentor: widget.isMentor),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // General Resources Tab (available to all)
            _buildGeneralResourcesTab(),
            
            // Documents Tab (filtered based on role)
            _buildDocumentsTab(),
            
            // Newsletter Tab (available to all)
            _buildNewsletterTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralResourcesTab() {
    if (!widget.isMentor) {
      // Mentee view
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'Quick Links',
            [
              _buildResourceCard(
                'Academic Calendar',
                'Important dates and deadlines',
                Icons.calendar_today,
                'Link',
                onTap: () {
                  // TODO: Open calendar link
                },
              ),
              _buildResourceCard(
                'Campus Resources',
                'Links to various campus support services',
                Icons.school,
                'Link',
                onTap: () {
                  // TODO: Open campus resources
                },
              ),
              _buildResourceCard(
                'Student Success Center',
                'Academic support and tutoring services',
                Icons.psychology,
                'Link',
                onTap: () {
                  // TODO: Open success center link
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Program Resources',
            [
              _buildResourceCard(
                'Program Overview',
                'Introduction to the Student Mentorship Program and its benefits',
                Icons.info_outline,
                'PDF',
                onTap: () {
                  // TODO: Open program overview
                },
              ),
              _buildResourceCard(
                'Academic Success Guide',
                'Essential tips and strategies for academic excellence',
                Icons.school,
                'PDF',
                onTap: () {
                  // TODO: Open academic guide
                },
              ),
              _buildResourceCard(
                'Goal Setting Workshop Materials',
                'Resources from the goal setting workshops',
                Icons.track_changes,
                'PDF',
                onTap: () {
                  // TODO: Open goal setting materials
                },
              ),
              _buildResourceCard(
                'Campus Life Guide',
                'Making the most of your university experience',
                Icons.emoji_people,
                'PDF',
                onTap: () {
                  // TODO: Open campus life guide
                },
              ),
            ],
          ),
        ],
      );
    }

    // Original mentor view remains unchanged
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSection(
          'Program Guide',
          [
            _buildResourceCard(
              'Mentor-Mentee Guide',
              'Comprehensive guide about the mentorship program, roles, and expectations',
              Icons.menu_book,
              'PDF',
              onTap: () {
                // TODO: Open guide
              },
            ),
            _buildResourceCard(
              'Best Practices',
              'Tips and strategies for effective mentoring relationships',
              Icons.lightbulb,
              'PDF',
              onTap: () {
                // TODO: Open best practices
              },
            ),
            _buildResourceCard(
              'FAQs',
              'Common questions and answers about the program',
              Icons.help,
              'PDF',
              onTap: () {
                // TODO: Open FAQs
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          'Quick Links',
          [
            _buildResourceCard(
              'Academic Calendar',
              'Important dates and deadlines',
              Icons.calendar_today,
              'Link',
              onTap: () {
                // TODO: Open calendar link
              },
            ),
            _buildResourceCard(
              'Campus Resources',
              'Links to various campus support services',
              Icons.school,
              'Link',
              onTap: () {
                // TODO: Open campus resources
              },
            ),
            _buildResourceCard(
              'Student Success Center',
              'Academic support and tutoring services',
              Icons.psychology,
              'Link',
              onTap: () {
                // TODO: Open success center link
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    if (!widget.isMentor) {
      // Mentee view of documents
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'From Your Mentor',
            mockDocuments
                .where((doc) => doc['uploadedBy'] == 'Your Mentor')
                .map((doc) => _buildDocumentCard(doc))
                .toList(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'General Resources',
            mockDocuments
                .where((doc) => 
                    doc['uploadedBy'] == 'Program Coordinator' && 
                    doc['category'] != 'Mentor Materials')
                .map((doc) => _buildDocumentCard(doc))
                .toList(),
          ),
        ],
      );
    }

    // Original mentor view with filter section
    return Column(
      children: [
        if (widget.isMentor)
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
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: selectedCategory,
              items: [
                'All Resources',
                'Study Materials',
                'Program Documents',
                'Templates',
                'Worksheets',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: mockDocuments
                .where((doc) => selectedCategory == 'All Resources' || 
                              doc['category'] == selectedCategory)
                .map((doc) => _buildDocumentCard(doc))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsletterTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: mockNewsletters.length,
      itemBuilder: (context, index) {
        final newsletter = mockNewsletters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(newsletter['title']),
                subtitle: Text(newsletter['date']),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Implement download
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(newsletter['description']),
              ),
              if (newsletter['highlights'] != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Highlights:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...newsletter['highlights'].map<Widget>((highlight) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(highlight)),
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
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildResourceCard(
    String title,
    String description,
    IconData icon,
    String type, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getFileIcon(doc['type']),
          color: _getFileColor(doc['type']),
          size: 32,
        ),
        title: Text(doc['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc['description']),
            const SizedBox(height: 4),
            Text(
              'Uploaded by ${doc['uploadedBy']} • ${doc['date']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isMentor && doc['uploadedBy'] == 'You')
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDocumentDialog(doc),
              ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // TODO: Implement download
              },
            ),
            IconButton(
              icon: const Icon(Icons.drive_folder_upload),
              tooltip: 'Export to Google Drive',
              onPressed: () => _showDriveExportDialog(doc),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
        return Colors.blue;
      case 'xlsx':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Resource'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Study Materials',
                  'Program Documents',
                  'Templates',
                  'Worksheets',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement file picker
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Choose File'),
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
              // TODO: Implement upload
              Navigator.pop(context);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _showEditDocumentDialog(Map<String, dynamic> doc) {
    // TODO: Implement edit dialog
  }

  void _showDriveExportDialog(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export "${doc['name']}" to:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('SMP Resources'),
              subtitle: const Text('Default program folder'),
              onTap: () {
                // TODO: Implement export to default folder
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exporting to Google Drive...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder, color: Colors.blue),
              title: const Text('New Folder'),
              subtitle: const Text('Create a new folder'),
              onTap: () {
                Navigator.pop(context);
                _showNewFolderDialog(doc);
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
  }

  void _showNewFolderDialog(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
            hintText: 'Enter folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement new folder creation and export
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Creating folder and exporting...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Create & Export'),
          ),
        ],
      ),
    );
  }

  // Updated mock data to include mentor-specific resources
  final List<Map<String, dynamic>> mockDocuments = [
    {
      'name': 'Study Tips for First-Year Students',
      'description': 'A comprehensive guide to effective study habits and time management',
      'type': 'PDF',
      'uploadedBy': 'Your Mentor',
      'date': 'Feb 15, 2024',
      'category': 'Study Materials'
    },
    {
      'name': 'Research Project Template',
      'description': 'Template for organizing research projects and papers',
      'type': 'DOCX',
      'uploadedBy': 'Program Coordinator',
      'date': 'Feb 10, 2024',
      'category': 'Templates'
    },
    {
      'name': 'Academic Progress Tracker',
      'description': 'Spreadsheet template for tracking academic goals and achievements',
      'type': 'XLSX',
      'uploadedBy': 'Your Mentor',
      'date': 'Feb 8, 2024',
      'category': 'Templates'
    },
    {
      'name': 'Time Management Worksheet',
      'description': 'Interactive worksheet for planning weekly schedules',
      'type': 'PDF',
      'uploadedBy': 'Program Coordinator',
      'date': 'Feb 5, 2024',
      'category': 'Worksheets'
    },
    {
      'name': 'Mentoring Best Practices Guide',
      'description': 'Guide for effective mentoring strategies',
      'type': 'PDF',
      'uploadedBy': 'Program Coordinator',
      'date': 'Feb 1, 2024',
      'category': 'Mentor Materials'
    },
    {
      'name': 'First Year Student Guide',
      'description': 'Essential information for first-year students',
      'type': 'PDF',
      'uploadedBy': 'Program Coordinator',
      'date': 'Feb 1, 2024',
      'category': 'Program Documents'
    }
  ];

  final List<Map<String, dynamic>> mockNewsletters = [
    {
      'title': 'February 2024 SMP Newsletter',
      'date': 'Feb 15, 2024',
      'description': 'Important updates and upcoming events for SMP mentees.',
      'highlights': [
        'Academic Success Workshop - Feb 20 at Student Center',
        'Peer Study Groups forming for Biology and Chemistry',
        'Career Development Series starting next month',
        'New tutoring hours available at Learning Commons'
      ]
    },
    {
      'title': 'January 2024 SMP Newsletter',
      'date': 'Jan 15, 2024',
      'description': 'Welcome back! Here\'s what\'s happening in the Student Mentorship Program.',
      'highlights': [
        'Welcome Social - Meet other mentees on Jan 25',
        'Time Management Workshop Series - Starting Feb 1',
        'New Study Resources available in the Resource Hub',
        'Student Success Stories: Meet last semester\'s top achievers'
      ]
    },
    {
      'title': 'December 2023 SMP Newsletter',
      'date': 'Dec 1, 2023',
      'description': 'End of semester updates and preparation for finals.',
      'highlights': [
        'Finals Week Study Sessions - Schedule and Locations',
        'Stress Management Workshop - Dec 5',
        'Holiday Social Event - Dec 8',
        'Spring Semester Program Preview'
      ]
    }
  ];
} 