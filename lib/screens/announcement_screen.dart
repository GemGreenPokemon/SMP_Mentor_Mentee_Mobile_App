import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_function_service.dart';
import 'package:provider/provider.dart';

class AnnouncementScreen extends StatefulWidget {
  final bool isCoordinator;
  
  const AnnouncementScreen({
    super.key,
    this.isCoordinator = true,
  });

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'High Priority', 'Medium Priority', 'Low Priority', 'General'];
  final AnnouncementService _announcementService = AnnouncementService();
  String? _userRole;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    // Get user role
    final authService = AuthService();
    _userRole = await authService.getUserRole();
    
    // Fetch announcements
    await _announcementService.fetchAnnouncements();
    
    if (mounted) {
      setState(() {});
    }
  }
  
  bool get _canCreateAnnouncements => _userRole == 'coordinator' || _userRole == 'mentor';
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _announcementService,
      child: Consumer<AnnouncementService>(
        builder: (context, announcementService, child) {
          final announcements = announcementService.announcements;
    
          // Filter announcements based on selected filter
          final filteredAnnouncements = _selectedFilter == 'All'
              ? announcements
              : _selectedFilter == 'General'
                  ? announcements.where((a) => a['priority'] == null || a['priority'] == 'none').toList()
                  : announcements.where((a) => 
                      a['priority'] == _selectedFilter.split(' ')[0].toLowerCase()).toList();
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('Announcements'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    announcementService.fetchAnnouncements(forceRefresh: true);
                  },
                ),
                if (_canCreateAnnouncements)
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      _showFilterDialog();
                    },
                  ),
                // Temporary sync button for debugging
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync Permissions',
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Syncing permissions...'),
                          ],
                        ),
                      ),
                    );
                    
                    try {
                      final cloudFunctions = CloudFunctionService();
                      final result = await cloudFunctions.syncUserClaimsOnLogin();
                      
                      // Force token refresh
                      final user = AuthService().currentUser;
                      if (user != null) {
                        await user.getIdToken(true);
                        await Future.delayed(const Duration(seconds: 1));
                      }
                      
                      Navigator.pop(context); // Close loading dialog
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['success'] == true 
                            ? 'Permissions synced successfully! Try creating an announcement now.'
                            : 'Sync failed: ${result['message'] ?? 'Unknown error'}'),
                          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                        ),
                      );
                      
                      // Refresh the screen
                      _initializeScreen();
                    } catch (e) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Error display
                if (announcementService.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade100,
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            announcementService.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        TextButton(
                          onPressed: () => announcementService.clearError(),
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  ),
                
                // Loading indicator
                if (announcementService.isLoading)
                  const LinearProgressIndicator(),
                
                // Filter chip section
                if (_canCreateAnnouncements)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedFilter = filter;
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          
                
                // Announcements list
                Expanded(
                  child: filteredAnnouncements.isEmpty && !announcementService.isLoading
                      ? const Center(
                          child: Text(
                            'No announcements found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            final announcement = filteredAnnouncements[index];
                            return _buildAnnouncementCard(
                              context,
                              announcement,
                              announcementService,
                            );
                          },
                        ),
                ),
              ],
            ),
            floatingActionButton: _canCreateAnnouncements
                ? FloatingActionButton(
                    onPressed: () {
                      _showAddAnnouncementDialog(context, announcementService);
                    },
                    child: const Icon(Icons.add),
                    tooltip: 'Add Announcement',
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Map<String, dynamic> announcement,
    AnnouncementService announcementService,
  ) {
    // Check if announcement has a priority
    final hasPriority = announcement['priority'] != null && 
                        announcement['priority'] != 'none';
    
    // Set priority color based on priority value
    Color priorityColor = Colors.blue;
    String priorityText = 'GENERAL';
    
    if (hasPriority) {
      switch (announcement['priority']) {
        case 'high':
          priorityColor = Colors.red;
          priorityText = 'HIGH PRIORITY';
          break;
        case 'medium':
          priorityColor = Colors.orange;
          priorityText = 'MEDIUM PRIORITY';
          break;
        case 'low':
          priorityColor = Colors.green;
          priorityText = 'LOW PRIORITY';
          break;
        default:
          priorityColor = Colors.blue;
          priorityText = 'GENERAL';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Always show priority badge, using "General" for no priority
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
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
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  announcement['time'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              announcement['title'],
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              announcement['content'],
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
            // Show edit/delete buttons if user can edit this announcement
            FutureBuilder<bool>(
              future: announcementService.canEditAnnouncement(announcement['created_by'] ?? ''),
              builder: (context, snapshot) {
                final canEdit = snapshot.data == true;
                if (!canEdit) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('Edit'),
                          onPressed: () {
                            _showEditAnnouncementDialog(
                              context,
                              announcement,
                              announcementService,
                            );
                          },
                        ),
                        const SizedBox(width: 8.0),
                        TextButton.icon(
                          icon: const Icon(Icons.delete, size: 20),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(
                              context,
                              announcement,
                              announcementService,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Announcements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
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

  void _showAddAnnouncementDialog(
    BuildContext context,
    AnnouncementService announcementService,
  ) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'none';
    String targetAudience = 'both';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Priority:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('General'),
                        value: 'none',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('High Priority'),
                        value: 'high',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Medium Priority'),
                        value: 'medium',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Low Priority'),
                        value: 'low',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                    ],
                  );
                },
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
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                  ),
                );
                return;
              }

              final newAnnouncement = {
                'title': titleController.text,
                'content': contentController.text,
                'time': 'Just now',
              };
              
              // Only add priority if it's not 'none'
              if (priority != 'none') {
                newAnnouncement['priority'] = priority;
              }

              // Create announcement using Firebase
              announcementService.createAnnouncement(
                title: titleController.text,
                content: contentController.text,
                priority: priority,
                targetAudience: targetAudience,
              ).then((success) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create announcement: ${announcementService.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAnnouncementDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
    AnnouncementService announcementService,
  ) {
    final titleController = TextEditingController(text: announcement['title']);
    final contentController = TextEditingController(text: announcement['content']);
    String priority = announcement['priority'] ?? 'none';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Priority:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('General'),
                        value: 'none',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('High Priority'),
                        value: 'high',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Medium Priority'),
                        value: 'medium',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Low Priority'),
                        value: 'low',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value ?? 'none';
                          });
                        },
                      ),
                    ],
                  );
                },
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
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                  ),
                );
                return;
              }

              // Update announcement using Firebase
              announcementService.updateAnnouncement(
                announcementId: announcement['id'],
                title: titleController.text,
                content: contentController.text,
                priority: priority,
              ).then((success) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update announcement: ${announcementService.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
    AnnouncementService announcementService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete the announcement "${announcement['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete announcement using Firebase
              announcementService.deleteAnnouncement(announcement['id']).then((success) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete announcement: ${announcementService.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 