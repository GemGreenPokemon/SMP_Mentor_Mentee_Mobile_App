import 'package:flutter/material.dart';
import 'local_db_table_screen.dart';
import 'local_db_explorer_screen.dart';
import '../services/local_database_service.dart';
import '../services/mock_data_generator.dart';
import '../utils/messaging_debug.dart';

class LocalDbManagerScreen extends StatefulWidget {
  const LocalDbManagerScreen({Key? key}) : super(key: key);

  @override
  State<LocalDbManagerScreen> createState() => _LocalDbManagerScreenState();
}

class _LocalDbManagerScreenState extends State<LocalDbManagerScreen> {
  int _usersCount = 0;
  int _mentorshipsCount = 0;
  int _availabilityCount = 0;
  int _meetingsCount = 0;
  bool _isLoading = false;

  final _localDb = LocalDatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    
    try {
      final usersCount = await _localDb.getUsersCount();
      final mentorshipsCount = await _localDb.getMentorshipsCount();
      final availabilityCount = await _localDb.getAvailabilityCount();
      final meetingsCount = await _localDb.getMeetingsCount();

      setState(() {
        _usersCount = usersCount;
        _mentorshipsCount = mentorshipsCount;
        _availabilityCount = availabilityCount;
        _meetingsCount = meetingsCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading counts: $e')),
        );
      }
    }
  }

  Future<void> _addMockData() async {
    // Show dialog to select mock data options
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (BuildContext context) {
        bool includeCoordinators = true;
        bool includeMentors = true;
        bool includeMentees = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Generate Mock Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Include Coordinators'),
                    subtitle: const Text('2 coordinators'),
                    value: includeCoordinators,
                    onChanged: (value) {
                      setState(() => includeCoordinators = value ?? true);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Include Mentors'),
                    subtitle: const Text('5 mentors with availability'),
                    value: includeMentors,
                    onChanged: (value) {
                      setState(() => includeMentors = value ?? true);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Include Mentees'),
                    subtitle: const Text('Up to 3 mentees per mentor'),
                    value: includeMentees,
                    onChanged: (value) {
                      setState(() => includeMentees = value ?? true);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'includeCoordinators': includeCoordinators,
                      'includeMentors': includeMentors,
                      'includeMentees': includeMentees,
                    });
                  },
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    
    try {
      await MockDataGenerator.generateMockData(
        includeCoordinators: result['includeCoordinators'] ?? true,
        includeMentors: result['includeMentors'] ?? true,
        includeMentees: result['includeMentees'] ?? true,
        clearExisting: false,  // Never clear existing data from this dialog
      );
      await _loadCounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock data added successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding mock data: $e')),
        );
      }
    }
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$count', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all data from the local database? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      await _localDb.clearAllTables();
      await _loadCounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local DB Manager'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Users', _usersCount, Icons.person)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Mentorships', _mentorshipsCount, Icons.group)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Availability', _availabilityCount, Icons.event_available)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Meetings', _meetingsCount, Icons.event_note)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addMockData,
                    icon: const Icon(Icons.add),
                    label: const Text('Generate Mock Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteAllData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocalDbExplorerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Database Explorer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagingDebugScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Messaging Debug'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                'users',
                'mentorships',
                'availability',
                'meetings',
                'resources',
                'messages',
                'meeting_notes',
                'meeting_ratings',
                'checklists',
                'announcements',
                'events'
              ].map(
                (table) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocalDbTableScreen(tableName: table),
                      ),
                    );
                  },
                  child: Text(table),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
