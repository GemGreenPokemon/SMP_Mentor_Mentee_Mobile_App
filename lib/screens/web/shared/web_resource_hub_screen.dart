import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/mentor_service.dart';
import 'web_settings_screen.dart';

class WebResourceHubScreen extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  
  const WebResourceHubScreen({
    super.key,
    this.isMentor = true,
    this.isCoordinator = false,
  });

  @override
  State<WebResourceHubScreen> createState() => _WebResourceHubScreenState();
}

class _WebResourceHubScreenState extends State<WebResourceHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'All Resources';
  String searchQuery = '';
  Set<String> selectedDocumentIds = {};
  bool isSelectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 1200;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Row(
        children: [
          if (isWideScreen && widget.isCoordinator)
            _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralResourcesTab(),
                      _buildDocumentsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('Resource Hub'),
          if (isSelectionMode) ...[
            const SizedBox(width: 16),
            Chip(
              label: Text('${selectedDocumentIds.length} selected'),
              onDeleted: () {
                setState(() {
                  isSelectionMode = false;
                  selectedDocumentIds.clear();
                });
              },
            ),
          ],
        ],
      ),
      actions: [
        // Search bar
        Container(
          width: 300,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search resources...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),
        if (widget.isMentor || widget.isCoordinator) ...[
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Resource',
            onPressed: _showUploadDialog,
          ),
          if (widget.isCoordinator)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Manage Resources',
              onPressed: _showResourceManagementDialog,
            ),
        ],
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebSettingsScreen(isMentor: widget.isMentor),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'General Resources'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text('Add Resource'),
            onTap: () => _showAddResourceDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.blue),
            title: const Text('Manage Categories'),
            onTap: () => _showManageCategoriesDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.purple),
            title: const Text('Usage Analytics'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics feature coming soon')),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All Resources',
      'Program Documents',
      'Templates',
      'Worksheets',
      'Study Materials',
      'Mentor Materials',
    ];
    
    return Column(
      children: categories.map((category) {
        return RadioListTile<String>(
          title: Text(category),
          value: category,
          groupValue: selectedCategory,
          onChanged: (value) {
            setState(() {
              selectedCategory = value!;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGeneralResourcesTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isCoordinator)
            _buildCoordinatorControls(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 4 :
                                      constraints.maxWidth > 800 ? 3 :
                                      constraints.maxWidth > 600 ? 2 : 1;
                
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'Quick Links',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildListDelegate([
                        _buildResourceCard(
                          'Academic Calendar',
                          'Important dates and deadlines',
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                        _buildResourceCard(
                          'Campus Resources',
                          'Links to various campus support services',
                          Icons.school,
                          Colors.green,
                        ),
                        _buildResourceCard(
                          'Student Success Center',
                          'Academic support and tutoring services',
                          Icons.psychology,
                          Colors.orange,
                        ),
                        _buildResourceCard(
                          'Library Resources',
                          'Access to digital libraries and research tools',
                          Icons.local_library,
                          Colors.purple,
                        ),
                      ]),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 48),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'Program Resources',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildListDelegate([
                        _buildResourceCard(
                          'Program Overview',
                          'Introduction to the Student Mentorship Program',
                          Icons.info_outline,
                          Colors.teal,
                        ),
                        _buildResourceCard(
                          'Academic Success Guide',
                          'Essential tips and strategies for excellence',
                          Icons.school,
                          Colors.indigo,
                        ),
                        _buildResourceCard(
                          'Goal Setting Workshop',
                          'Resources from the goal setting workshops',
                          Icons.track_changes,
                          Colors.amber,
                        ),
                        _buildResourceCard(
                          'Campus Life Guide',
                          'Making the most of your university experience',
                          Icons.emoji_people,
                          Colors.pink,
                        ),
                      ]),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: Handle resource click
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final filteredDocuments = mockDocuments.where((doc) {
      final matchesCategory = selectedCategory == 'All Resources' || 
                            doc['category'] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
                          doc['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                          doc['description'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = widget.isCoordinator ||
                        (widget.isMentor && doc['audience'] != 'Coordinators') ||
                        (!widget.isMentor && (doc['audience'] == 'All' || doc['audience'] == 'Mentees'));
      
      return matchesCategory && matchesSearch && matchesRole;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (widget.isCoordinator || isSelectionMode)
            _buildDocumentControls(),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false, // Disable built-in checkbox column
                  dataRowMinHeight: 48, // Minimum row height
                  dataRowMaxHeight: 56, // Maximum row height to contain chips
                  columns: [
                    if (widget.isCoordinator || widget.isMentor)
                      DataColumn(
                        label: Checkbox(
                          value: selectedDocumentIds.length == filteredDocuments.length && 
                                filteredDocuments.isNotEmpty,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedDocumentIds = filteredDocuments
                                    .map((doc) => doc['title'] as String)
                                    .toSet();
                                isSelectionMode = true;
                              } else {
                                selectedDocumentIds.clear();
                                isSelectionMode = false;
                              }
                            });
                          },
                        ),
                      ),
                    const DataColumn(label: Text('Title')),
                    const DataColumn(label: Text('Description')),
                    const DataColumn(label: Text('Type')),
                    const DataColumn(label: Text('Category')),
                    const DataColumn(label: Text('Date Added')),
                    if (widget.isMentor || widget.isCoordinator)
                      const DataColumn(label: Text('Assigned To')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredDocuments.map((doc) {
                    final isSelected = selectedDocumentIds.contains(doc['title']);
                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: widget.isCoordinator || widget.isMentor
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  selectedDocumentIds.add(doc['title']);
                                  isSelectionMode = true;
                                } else {
                                  selectedDocumentIds.remove(doc['title']);
                                  if (selectedDocumentIds.isEmpty) {
                                    isSelectionMode = false;
                                  }
                                }
                              });
                            }
                          : null,
                      cells: [
                        if (widget.isCoordinator || widget.isMentor)
                          DataCell(
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedDocumentIds.add(doc['title']);
                                    isSelectionMode = true;
                                  } else {
                                    selectedDocumentIds.remove(doc['title']);
                                    if (selectedDocumentIds.isEmpty) {
                                      isSelectionMode = false;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        DataCell(
                          Row(
                            children: [
                              Icon(_getFileIcon(doc['type']), size: 20, color: _getFileColor(doc['type'])),
                              const SizedBox(width: 8),
                              Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(
                              doc['description'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Chip(
                            label: Text(doc['type'], style: const TextStyle(fontSize: 12)),
                            backgroundColor: _getFileColor(doc['type']).withOpacity(0.2),
                          ),
                        ),
                        DataCell(Text(doc['category'])),
                        DataCell(Text(doc['dateAdded'])),
                        if (widget.isMentor || widget.isCoordinator)
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: (doc['assignedTo'] as List).isEmpty
                                  ? const Text('-')
                                  : Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      clipBehavior: Clip.hardEdge,
                                      children: (doc['assignedTo'] as List).map((mentee) {
                                        return Container(
                                          height: 24, // Fixed height to prevent overflow
                                          child: Chip(
                                            label: Text(
                                              mentee, 
                                              style: const TextStyle(fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            backgroundColor: Colors.green[100],
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Downloading ${doc['title']}...')),
                                  );
                                },
                              ),
                              if (widget.isMentor)
                                IconButton(
                                  icon: const Icon(Icons.person_add, size: 20),
                                  onPressed: () => _showAssignToMenteesDialog(doc),
                                ),
                              if (widget.isCoordinator) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showEditDocumentDialog(doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _showDeleteDocumentConfirmation(doc),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Resource'),
            onPressed: () => _showAddResourceDialog(),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder),
            label: const Text('Manage Categories'),
            onPressed: () => _showManageCategoriesDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isSelectionMode) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: Text('Delete (${selectedDocumentIds.length})'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _showBulkDeleteConfirmation(),
            ),
            const SizedBox(width: 16),
            if (widget.isMentor)
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: Text('Assign to Mentees (${selectedDocumentIds.length})'),
                onPressed: () => _showBulkAssignDialog(),
              ),
          ],
          const Spacer(),
          DropdownButton<String>(
            value: selectedCategory,
            items: [
              'All Resources',
              'Program Documents',
              'Templates',
              'Worksheets',
              'Study Materials',
              'Mentor Materials',
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
        ],
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
      case 'link':
        return Icons.link;
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
      case 'link':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _ResourceUploadDialog(
        isMentor: widget.isMentor,
        isCoordinator: widget.isCoordinator,
      ),
    );
  }

  void _showAddResourceDialog({String? category}) {
    showDialog(
      context: context,
      builder: (context) => _ResourceUploadDialog(
        isMentor: widget.isMentor,
        isCoordinator: widget.isCoordinator,
        initialCategory: category,
      ),
    );
  }

  void _showEditDocumentDialog(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) => _ResourceEditDialog(
        document: document,
        isMentor: widget.isMentor,
        isCoordinator: widget.isCoordinator,
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
                const SnackBar(content: Text('Document deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Multiple Documents'),
        content: Text('Are you sure you want to delete ${selectedDocumentIds.length} documents? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement bulk deletion
              Navigator.pop(context);
              setState(() {
                selectedDocumentIds.clear();
                isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Documents deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showBulkAssignDialog() {
    final mentorService = Provider.of<MentorService>(context, listen: false);
    Map<String, bool> selectedMentees = {};
    
    for (var mentee in mentorService.mentees) {
      selectedMentees[mentee['name']] = false;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Assign ${selectedDocumentIds.length} Resources to Mentees'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select mentees to assign these resources to:'),
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
                    );
                  }).toList(),
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
                  List<String> assignedMentees = [];
                  selectedMentees.forEach((mentee, isSelected) {
                    if (isSelected) {
                      assignedMentees.add(mentee);
                    }
                  });
                  
                  Navigator.pop(context);
                  setState(() {
                    selectedDocumentIds.clear();
                    isSelectionMode = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Resources assigned to ${assignedMentees.length} mentee(s)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignToMenteesDialog(Map<String, dynamic> document) {
    final mentorService = Provider.of<MentorService>(context, listen: false);
    Map<String, bool> selectedMentees = {};
    
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
                const Text('Assign Resource to Mentees'),
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
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select mentees to assign this resource to:'),
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
                    );
                  }).toList(),
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
                  List<String> assignedMentees = [];
                  selectedMentees.forEach((mentee, isSelected) {
                    if (isSelected) {
                      assignedMentees.add(mentee);
                    }
                  });
                  
                  document['assignedTo'] = assignedMentees;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        assignedMentees.isEmpty
                            ? 'Resource unassigned from all mentees'
                            : 'Resource assigned to ${assignedMentees.length} mentee(s)',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  setState(() {});
                },
                child: const Text('Save Assignments'),
              ),
            ],
          );
        },
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
                    const SnackBar(content: Text('Resource analytics feature coming soon')),
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
                    const SnackBar(content: Text('Resource history feature coming soon')),
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
          width: 400,
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
                        // TODO: Implement edit category
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Implement delete category
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
              // TODO: Implement add category
            },
          ),
        ],
      ),
    );
  }

  // Mock data
  final List<Map<String, dynamic>> mockDocuments = [
    {
      'title': 'Program Handbook 2023',
      'description': 'Complete guide to the mentorship program including policies and procedures.',
      'type': 'PDF',
      'category': 'Program Documents',
      'dateAdded': 'Jan 15, 2023',
      'audience': 'All',
      'url': 'assets/documents/handbook.pdf',
      'assignedTo': [],
    },
    {
      'title': 'Mentorship Agreement Template',
      'description': 'Standard agreement to be signed by mentors and mentees at the beginning of the program.',
      'type': 'DOCX',
      'category': 'Templates',
      'dateAdded': 'Feb 3, 2023',
      'audience': 'Mentors',
      'url': 'assets/documents/agreement.docx',
      'assignedTo': ['Alice Johnson'],
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
      'assignedTo': ['Alice Johnson', 'Bob Wilson'],
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
      'title': 'Career Development Resources',
      'description': 'Collection of resources for career planning and professional development.',
      'type': 'Link',
      'category': 'Study Materials',
      'dateAdded': 'Aug 22, 2023',
      'audience': 'Mentees',
      'url': 'https://example.com/career-resources',
      'assignedTo': ['Bob Wilson'],
    },
  ];
}

// Upload Dialog Widget
class _ResourceUploadDialog extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  final String? initialCategory;

  const _ResourceUploadDialog({
    required this.isMentor,
    required this.isCoordinator,
    this.initialCategory,
  });

  @override
  State<_ResourceUploadDialog> createState() => _ResourceUploadDialogState();
}

class _ResourceUploadDialogState extends State<_ResourceUploadDialog> {
  String? selectedCategory;
  String? selectedType;
  Map<String, bool> selectedMentees = {};
  
  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    
    if (widget.isMentor) {
      final mentorService = Provider.of<MentorService>(context, listen: false);
      for (var mentee in mentorService.mentees) {
        selectedMentees[mentee['name']] = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = widget.isMentor ? Provider.of<MentorService>(context, listen: false) : null;
    
    return AlertDialog(
      title: const Text('Upload Resource'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
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
                  setState(() {
                    selectedCategory = value;
                  });
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
                  setState(() {
                    selectedType = value;
                  });
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
              
              if (widget.isMentor && mentorService != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assign to Mentees',
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement upload
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
                      ? 'Resource uploaded successfully'
                      : 'Resource uploaded and assigned to ${assignedMentees.length} mentee(s)',
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}

// Edit Dialog Widget
class _ResourceEditDialog extends StatefulWidget {
  final Map<String, dynamic> document;
  final bool isMentor;
  final bool isCoordinator;

  const _ResourceEditDialog({
    required this.document,
    required this.isMentor,
    required this.isCoordinator,
  });

  @override
  State<_ResourceEditDialog> createState() => _ResourceEditDialogState();
}

class _ResourceEditDialogState extends State<_ResourceEditDialog> {
  late String selectedCategory;
  late String selectedType;
  Map<String, bool> selectedMentees = {};
  
  @override
  void initState() {
    super.initState();
    selectedCategory = widget.document['category'];
    selectedType = widget.document['type'];
    
    if (widget.isMentor) {
      final mentorService = Provider.of<MentorService>(context, listen: false);
      for (var mentee in mentorService.mentees) {
        String menteeName = mentee['name'];
        selectedMentees[menteeName] = (widget.document['assignedTo'] as List).contains(menteeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = widget.isMentor ? Provider.of<MentorService>(context, listen: false) : null;
    
    return AlertDialog(
      title: const Text('Edit Document'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
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
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: widget.document['title']),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: widget.document['description']),
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
                  setState(() {
                    selectedType = value!;
                  });
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
              
              if (widget.isMentor && mentorService != null) ...[
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
              ],
            ],
          ),
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
            List<String> assignedMentees = [];
            if (widget.isMentor) {
              selectedMentees.forEach((mentee, isSelected) {
                if (isSelected) {
                  assignedMentees.add(mentee);
                }
              });
              widget.document['assignedTo'] = assignedMentees;
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
  }
}