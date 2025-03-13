import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../services/mentor_service.dart';

class ResourceHubScreen extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  const ResourceHubScreen({
    super.key, 
    this.isMentor = true, 
    this.isCoordinator = false
  });

  @override
  State<ResourceHubScreen> createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen> with SingleTickerProviderStateMixin {
  String selectedCategory = 'All Resources';
  late TabController _tabController;
  final List<String> _tabTitles = ['General Resources', 'Documents'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitles[_tabController.index]),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Documents'),
            ],
          ),
          actions: [
            if (widget.isMentor || widget.isCoordinator)
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: widget.isCoordinator ? 'Manage Resources' : 'Upload Resource',
                onPressed: () => widget.isCoordinator ? _showResourceManagementDialog() : _showUploadDialog(),
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
          ],
        ),
        floatingActionButton: widget.isCoordinator ? FloatingActionButton(
          onPressed: () => _showAddResourceDialog(),
          child: const Icon(Icons.add),
          tooltip: 'Add New Resource',
        ) : null,
      ),
    );
  }

  Widget _buildGeneralResourcesTab() {
    if (widget.isCoordinator) {
      // Coordinator view
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCoordinatorSection(
            'Program Resources',
            [
              _buildResourceCardWithActions(
                'Program Overview',
                'Introduction to the Student Mentorship Program and its benefits',
                Icons.info_outline,
                'PDF',
                onTap: () {
                  // TODO: Open program overview
                },
              ),
              _buildResourceCardWithActions(
                'Academic Success Guide',
                'Essential tips and strategies for academic excellence',
                Icons.school,
                'PDF',
                onTap: () {
                  // TODO: Open academic guide
                },
              ),
              _buildResourceCardWithActions(
                'Goal Setting Workshop Materials',
                'Resources from the goal setting workshops',
                Icons.track_changes,
                'PDF',
                onTap: () {
                  // TODO: Open goal setting materials
                },
              ),
              _buildResourceCardWithActions(
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
          const SizedBox(height: 24),
          _buildCoordinatorSection(
            'Quick Links',
            [
              _buildResourceCardWithActions(
                'Academic Calendar',
                'Important dates and deadlines',
                Icons.calendar_today,
                'Link',
                onTap: () {
                  // TODO: Open calendar link
                },
              ),
              _buildResourceCardWithActions(
                'Campus Resources',
                'Links to various campus support services',
                Icons.school,
                'Link',
                onTap: () {
                  // TODO: Open campus resources
                },
              ),
              _buildResourceCardWithActions(
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
    } else if (!widget.isMentor) {
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
    if (widget.isCoordinator) {
      // Coordinator view of documents
      return Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Documents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                    onPressed: () {
                      // TODO: Implement filter dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Filter functionality coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                'Program Resources',
                mockDocuments
                    .where((doc) => doc['category'] == 'Program Documents')
                    .map((doc) => _buildDocumentCardWithActions(doc))
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Templates & Worksheets',
                mockDocuments
                    .where((doc) => doc['category'] == 'Templates' || doc['category'] == 'Worksheets')
                    .map((doc) => _buildDocumentCardWithActions(doc))
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Study Materials',
                mockDocuments
                    .where((doc) => doc['category'] == 'Study Materials')
                    .map((doc) => _buildDocumentCardWithActions(doc))
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Mentor Materials',
                mockDocuments
                    .where((doc) => doc['category'] == 'Mentor Materials')
                    .map((doc) => _buildDocumentCardWithActions(doc))
                    .toList(),
              ),
              // Add extra space at the bottom for the FAB
              const SizedBox(height: 80),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddDocumentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Document'),
            ),
          ),
        ],
      );
    } else if (!widget.isMentor) {
      // Mentee view of documents
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'From Your Mentor',
            mockDocuments
                .where((doc) => doc['audience'] == 'Mentees' || doc['audience'] == 'All')
                .map((doc) => _buildDocumentCard(doc))
                .toList(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'General Resources',
            mockDocuments
                .where((doc) => 
                    doc['category'] != 'Mentor Materials' && 
                    (doc['audience'] == 'All' || doc['audience'] == 'Mentees'))
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
            children: [
              // For mentors, add a section showing resources assigned to mentees
              if (widget.isMentor) ...[
                const Text(
                  'Resources Assigned to Mentees',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Resources you have assigned to specific mentees',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ...mockDocuments
                    .where((doc) => (doc['assignedTo'] as List).isNotEmpty)
                    .map((doc) => _buildDocumentCard(doc))
                    .toList(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'All Resources',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Filtered resources based on selected category
              ...mockDocuments
                  .where((doc) => selectedCategory == 'All Resources' || 
                                doc['category'] == selectedCategory)
                  .map((doc) => _buildDocumentCard(doc))
                  .toList(),
            ],
          ),
        ),
      ],
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

  Widget _buildResourceCardWithActions(
    String title,
    String description,
    IconData icon,
    String type, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
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
          if (widget.isCoordinator)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () => _showEditResourceDialog(title, description, type),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _showDeleteConfirmationDialog(title),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
              onPressed: () => _showAddResourceDialog(category: title),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document icon based on type
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFileColor(doc['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(doc['type']),
                    color: _getFileColor(doc['type']),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                // Document details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc['description'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Display assigned mentees if this is a mentor view and document is assigned to mentees
                      if (widget.isMentor && doc['assignedTo'] != null && (doc['assignedTo'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Assigned to: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (doc['assignedTo'] as List).map<Widget>((mentee) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mentee,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Added: ${doc['dateAdded']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Implement download
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${doc['title']}...'),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Add Assign to Mentee button for mentors
            if (widget.isMentor)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAssignToMenteesDialog(doc),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Assign to Mentee'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCardWithActions(Map<String, dynamic> document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document icon based on type
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(document['type']),
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                // Document details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document['description'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              document['type'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              document['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Show assignment information if this is a mentor view and document is assigned to mentees
                      if (widget.isMentor && document['assignedTo'] != null && (document['assignedTo'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned to:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (document['assignedTo'] as List).map<Widget>((mentee) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      mentee,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons for coordinators
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDocumentDialog(document),
                      tooltip: 'Edit Document',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDocumentConfirmation(document),
                      tooltip: 'Delete Document',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Added: ${document['dateAdded']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    if (widget.isMentor)
                      TextButton.icon(
                        onPressed: () => _showAssignToMenteesDialog(document),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Assign to Mentees'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement document download/view
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening ${document['title']}'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
    String? selectedCategory;
    
    // Get the MentorService to access the list of mentees
    final mentorService = Provider.of<MentorService>(context, listen: false);
    
    // Create a map to track which mentees are selected
    Map<String, bool> selectedMentees = {};
    
    // Initialize all mentees as unselected
    for (var mentee in mentorService.mentees) {
      selectedMentees[mentee['name']] = false;
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                    onChanged: (value) {
                      selectedCategory = value;
                    },
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
                  
                  // Only show mentee assignment section for mentors
                  if (widget.isMentor) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Assign to Mentee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...mentorService.mentees.map((mentee) {
                      String menteeName = mentee['name'];
                      return CheckboxListTile(
                        title: Text(menteeName),
                        subtitle: Text(mentee['program']),
                        value: selectedMentees[menteeName] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedMentees[menteeName] = value ?? false;
                          });
                        },
                        secondary: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        dense: true,
                      );
                    }).toList(),
                  ],
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
                  
                  // Create list of assigned mentees
                  List<String> assignedMentees = [];
                  if (widget.isMentor) {
                    selectedMentees.forEach((mentee, isSelected) {
                      if (isSelected) {
                        assignedMentees.add(mentee);
                      }
                    });
                  }
                  
                  Navigator.pop(context);
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        assignedMentees.isEmpty
                            ? 'Resource uploaded successfully'
                            : 'Resource uploaded and assigned to ${assignedMentees.length} mentee(s): ${assignedMentees.join(', ')}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDocumentDialog(Map<String, dynamic> document) {
    String? selectedCategory = document['category'];
    String? selectedType = document['type'];
    
    // Get the MentorService to access the list of mentees
    final mentorService = Provider.of<MentorService>(context, listen: false);
    
    // Create a map to track which mentees are selected
    Map<String, bool> selectedMentees = {};
    
    // Initialize with current assignments
    for (var mentee in mentorService.mentees) {
      String menteeName = mentee['name'];
      selectedMentees[menteeName] = (document['assignedTo'] as List).contains(menteeName);
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Document'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: [
                      'Program Documents',
                      'Templates',
                      'Worksheets',
                      'Study Materials',
                      'Mentor Materials',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {
                      selectedCategory = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Document Title',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: document['title']),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: document['description']),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedType,
                    items: [
                      'PDF',
                      'DOCX',
                      'XLSX',
                      'Link',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {
                      selectedType = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement file picker
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Replace File'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Target Audience',
                      border: OutlineInputBorder(),
                      hintText: 'All, Mentors, Mentees, or specific groups',
                    ),
                    controller: TextEditingController(text: document['audience'] ?? 'All'),
                  ),
                  
                  // Only show mentee assignment section for mentors
                  if (widget.isMentor) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Assign to Specific Mentees',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select mentees to assign this resource to:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...mentorService.mentees.map((mentee) {
                      String menteeName = mentee['name'];
                      return CheckboxListTile(
                        title: Text(menteeName),
                        subtitle: Text(mentee['program']),
                        value: selectedMentees[menteeName] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedMentees[menteeName] = value ?? false;
                          });
                        },
                        dense: true,
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Assigned resources will appear in the "From Your Mentor" section of the mentee\'s Resource Hub.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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
                  // TODO: Implement document update
                  
                  // Update assigned mentees
                  List<String> assignedMentees = [];
                  if (widget.isMentor) {
                    selectedMentees.forEach((mentee, isSelected) {
                      if (isSelected) {
                        assignedMentees.add(mentee);
                      }
                    });
                    document['assignedTo'] = assignedMentees;
                  }
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        assignedMentees.isEmpty
                            ? 'Document updated successfully'
                            : 'Document updated and assigned to ${assignedMentees.length} mentee(s)',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDocumentConfirmation(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement document deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document deleted successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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

  void _showResourceManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resource Management'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('Add New Resource'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddResourceDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: const Text('Manage Categories'),
                onTap: () {
                  Navigator.pop(context);
                  _showManageCategoriesDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.purple),
                title: const Text('Resource Usage Analytics'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resource analytics feature coming soon'),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text('Resource History'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resource history feature coming soon'),
                    ),
                  );
                },
              ),
            ],
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

  void _showAddResourceDialog({String? category}) {
    String? selectedCategory = category;
    String? selectedType;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Resource'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedCategory == null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Program Resources',
                    'Quick Links',
                    'Study Materials',
                    'Templates',
                    'Worksheets',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                ),
              if (selectedCategory == null)
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Resource Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'PDF',
                  'DOCX',
                  'XLSX',
                  'Link',
                  'Video',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  selectedType = value;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement file picker
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Choose File'),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(),
                  hintText: 'All, Mentors, Mentees, or specific groups',
                ),
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
              // TODO: Implement resource addition
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource added successfully'),
                ),
              );
            },
            child: const Text('Add Resource'),
          ),
        ],
      ),
    );
  }

  void _showEditResourceDialog(String title, String description, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Resource'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: title),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: description),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Resource Type',
                  border: OutlineInputBorder(),
                ),
                value: type,
                items: [
                  'PDF',
                  'DOCX',
                  'XLSX',
                  'Link',
                  'Video',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement file picker
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Replace File'),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(),
                  hintText: 'All, Mentors, Mentees, or specific groups',
                ),
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
              // TODO: Implement resource update
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource updated successfully'),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement resource deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Resource "$title" deleted'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog() {
    final List<String> categories = [
      'Program Resources',
      'Quick Links',
      'Study Materials',
      'Templates',
      'Worksheets',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Categories'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(categories[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditCategoryDialog(categories[index]);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteCategoryDialog(categories[index]);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            onPressed: () {
              Navigator.pop(context);
              _showAddCategoryDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement category addition
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category added successfully'),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: category),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement category update
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category updated successfully'),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the "$category" category? All resources in this category will be moved to "Uncategorized".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement category deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "$category" deleted'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Updated mock data to include mentor-specific resources
  final List<Map<String, dynamic>> mockDocuments = [
    {
      'title': 'Program Handbook 2023',
      'description': 'Complete guide to the mentorship program including policies and procedures.',
      'type': 'PDF',
      'category': 'Program Documents',
      'dateAdded': 'Jan 15, 2023',
      'audience': 'All',
      'url': 'assets/documents/handbook.pdf',
      'assignedTo': [], // Empty array means not assigned to specific mentees
    },
    {
      'title': 'Mentorship Agreement Template',
      'description': 'Standard agreement to be signed by mentors and mentees at the beginning of the program.',
      'type': 'DOCX',
      'category': 'Templates',
      'dateAdded': 'Feb 3, 2023',
      'audience': 'Mentors',
      'url': 'assets/documents/agreement.docx',
      'assignedTo': ['Alice Johnson'], // Assigned to specific mentee
    },
    {
      'title': 'Monthly Progress Report',
      'description': 'Template for tracking mentee progress on a monthly basis.',
      'type': 'XLSX',
      'category': 'Templates',
      'dateAdded': 'Feb 10, 2023',
      'audience': 'Mentors',
      'url': 'assets/documents/progress.xlsx',
      'assignedTo': [],
    },
    {
      'title': 'Goal Setting Worksheet',
      'description': 'Worksheet to help mentees set SMART goals for their development.',
      'type': 'PDF',
      'category': 'Worksheets',
      'dateAdded': 'Mar 5, 2023',
      'audience': 'Mentees',
      'url': 'assets/documents/goals.pdf',
      'assignedTo': ['Alice Johnson', 'Bob Wilson'], // Assigned to multiple mentees
    },
    {
      'title': 'Effective Communication Guide',
      'description': 'Resource for improving communication skills in mentorship relationships.',
      'type': 'PDF',
      'category': 'Study Materials',
      'dateAdded': 'Apr 12, 2023',
      'audience': 'All',
      'url': 'assets/documents/communication.pdf',
      'assignedTo': [],
    },
    {
      'title': 'Mentor Training Slides',
      'description': 'Presentation slides from the mentor training workshop.',
      'type': 'PDF',
      'category': 'Mentor Materials',
      'dateAdded': 'May 20, 2023',
      'audience': 'Mentors',
      'url': 'assets/documents/training.pdf',
      'assignedTo': [],
    },
    {
      'title': 'Conflict Resolution Strategies',
      'description': 'Guide for addressing and resolving conflicts in mentorship relationships.',
      'type': 'PDF',
      'category': 'Study Materials',
      'dateAdded': 'Jun 8, 2023',
      'audience': 'All',
      'url': 'assets/documents/conflict.pdf',
      'assignedTo': [],
    },
    {
      'title': 'Program Evaluation Form',
      'description': 'End-of-program evaluation form for participants to provide feedback.',
      'type': 'PDF',
      'category': 'Program Documents',
      'dateAdded': 'Jul 15, 2023',
      'audience': 'All',
      'url': 'assets/documents/evaluation.pdf',
      'assignedTo': [],
    },
    {
      'title': 'Career Development Resources',
      'description': 'Collection of resources for career planning and professional development.',
      'type': 'Link',
      'category': 'Study Materials',
      'dateAdded': 'Aug 22, 2023',
      'audience': 'Mentees',
      'url': 'https://example.com/career-resources',
      'assignedTo': ['Bob Wilson'], // Assigned to specific mentee
    },
    {
      'title': 'Mentorship Best Practices',
      'description': 'Comprehensive guide to effective mentoring techniques and approaches.',
      'type': 'PDF',
      'category': 'Mentor Materials',
      'dateAdded': 'Sep 10, 2023',
      'audience': 'Mentors',
      'url': 'assets/documents/best-practices.pdf',
      'assignedTo': [],
    },
  ];

  void _showAddDocumentDialog() {
    String? selectedCategory;
    String? selectedType;
    
    // Get the MentorService to access the list of mentees
    final mentorService = Provider.of<MentorService>(context, listen: false);
    
    // Create a map to track which mentees are selected
    Map<String, bool> selectedMentees = {};
    
    // Initialize all mentees as unselected
    for (var mentee in mentorService.mentees) {
      selectedMentees[mentee['name']] = false;
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Document'),
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
                      'Program Documents',
                      'Templates',
                      'Worksheets',
                      'Study Materials',
                      'Mentor Materials',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {
                      selectedCategory = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Document Title',
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
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'PDF',
                      'DOCX',
                      'XLSX',
                      'Link',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {
                      selectedType = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement file picker
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Choose File'),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Target Audience',
                      border: OutlineInputBorder(),
                      hintText: 'All, Mentors, Mentees, or specific groups',
                    ),
                  ),
                  
                  // Only show mentee assignment section for mentors
                  if (widget.isMentor) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Assign to Specific Mentees',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select mentees to assign this resource to:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...mentorService.mentees.map((mentee) {
                      String menteeName = mentee['name'];
                      return CheckboxListTile(
                        title: Text(menteeName),
                        subtitle: Text(mentee['program']),
                        value: selectedMentees[menteeName] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedMentees[menteeName] = value ?? false;
                          });
                        },
                        secondary: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Assigned resources will appear in the "From Your Mentor" section of the mentee\'s Resource Hub.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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
                  // TODO: Implement document addition
                  
                  // Create list of assigned mentees
                  List<String> assignedMentees = [];
                  if (widget.isMentor) {
                    selectedMentees.forEach((mentee, isSelected) {
                      if (isSelected) {
                        assignedMentees.add(mentee);
                      }
                    });
                  }
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        assignedMentees.isEmpty
                            ? 'Document added successfully'
                            : 'Document added and assigned to ${assignedMentees.length} mentee(s): ${assignedMentees.join(', ')}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Add Document'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOCX':
        return Icons.description;
      case 'XLSX':
        return Icons.table_chart;
      case 'Link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showAssignToMenteesDialog(Map<String, dynamic> document) {
    // Get the MentorService to access the list of mentees
    final mentorService = Provider.of<MentorService>(context, listen: false);
    
    // Create a map to track which mentees are selected
    Map<String, bool> selectedMentees = {};
    
    // Initialize with current assignments
    for (var mentee in mentorService.mentees) {
      String menteeName = mentee['name'];
      selectedMentees[menteeName] = (document['assignedTo'] as List).contains(menteeName);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assign Resource to Specific Mentees'),
                const SizedBox(height: 4),
                Text(
                  document['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select which mentees should have access to this resource:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ...mentorService.mentees.map((mentee) {
                    String menteeName = mentee['name'];
                    return CheckboxListTile(
                      title: Text(menteeName),
                      subtitle: Text(mentee['program']),
                      value: selectedMentees[menteeName] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          selectedMentees[menteeName] = value ?? false;
                        });
                      },
                      secondary: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Assigned resources will appear in the "From Your Mentor" section of each mentee\'s Resource Hub.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save Assignments'),
                onPressed: () {
                  // Update the document's assignedTo list
                  List<String> assignedMentees = [];
                  selectedMentees.forEach((mentee, isSelected) {
                    if (isSelected) {
                      assignedMentees.add(mentee);
                    }
                  });
                  
                  // Update the document
                  document['assignedTo'] = assignedMentees;
                  
                  // Close the dialog
                  Navigator.pop(context);
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        assignedMentees.isEmpty
                            ? 'Resource unassigned from all mentees'
                            : 'Resource assigned to ${assignedMentees.length} mentee(s): ${assignedMentees.join(', ')}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh the UI
                  setState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 