import 'package:flutter/material.dart';
import '../services/mentor_service.dart';
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
  
  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    final announcements = mentorService.announcements;
    
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
          if (widget.isCoordinator)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chip section
          if (widget.isCoordinator)
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
            child: filteredAnnouncements.isEmpty
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
                        mentorService,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.isCoordinator
          ? FloatingActionButton(
              onPressed: () {
                _showAddAnnouncementDialog(context, mentorService);
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Announcement',
            )
          : null,
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Map<String, dynamic> announcement,
    MentorService mentorService,
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
            if (widget.isCoordinator) ...[
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
                        mentorService,
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
                        mentorService,
                      );
                    },
                  ),
                ],
              ),
            ],
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
    MentorService mentorService,
  ) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'none'; // Changed from String? to String

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

              mentorService.addAnnouncement(newAnnouncement);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement added successfully'),
                ),
              );
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
    MentorService mentorService,
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

              // Update the announcement
              announcement['title'] = titleController.text;
              announcement['content'] = contentController.text;
              announcement['time'] = 'Updated just now';
              
              // Handle priority
              if (priority == 'none') {
                // Remove priority if it exists
                announcement.remove('priority');
              } else {
                // Set priority
                announcement['priority'] = priority;
              }

              // Update the state to refresh UI
              setState(() {});
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement updated successfully'),
                ),
              );
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
    MentorService mentorService,
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
              // Remove the announcement from the list
              mentorService.announcements.remove(announcement);
              
              // Update the state to refresh UI
              setState(() {});
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement deleted successfully'),
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
} 