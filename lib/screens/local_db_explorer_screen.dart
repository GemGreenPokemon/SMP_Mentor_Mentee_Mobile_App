import 'package:flutter/material.dart';
import '../services/local_database_service.dart';
import 'local_db_table_screen.dart';

class LocalDbExplorerScreen extends StatefulWidget {
  const LocalDbExplorerScreen({Key? key}) : super(key: key);

  @override
  State<LocalDbExplorerScreen> createState() => _LocalDbExplorerScreenState();
}

class _LocalDbExplorerScreenState extends State<LocalDbExplorerScreen> {
  final _localDb = LocalDatabaseService.instance;
  Map<String, int> _tableCounts = {};
  bool _isLoading = true;

  final List<TableInfo> _tables = [
    TableInfo(
      name: 'users',
      icon: Icons.people,
      color: Colors.blue,
      description: 'Mentors, mentees, and coordinators',
    ),
    TableInfo(
      name: 'mentorships',
      icon: Icons.group,
      color: Colors.green,
      description: 'Mentor-mentee relationships',
    ),
    TableInfo(
      name: 'availability',
      icon: Icons.event_available,
      color: Colors.orange,
      description: 'Mentor availability slots',
    ),
    TableInfo(
      name: 'meetings',
      icon: Icons.event,
      color: Colors.purple,
      description: 'Scheduled and past meetings',
    ),
    TableInfo(
      name: 'messages',
      icon: Icons.message,
      color: Colors.teal,
      description: 'Chat messages between users',
    ),
    TableInfo(
      name: 'announcements',
      icon: Icons.announcement,
      color: Colors.red,
      description: 'System-wide announcements',
    ),
    TableInfo(
      name: 'checklists',
      icon: Icons.checklist,
      color: Colors.indigo,
      description: 'User tasks and to-dos',
    ),
    TableInfo(
      name: 'events',
      icon: Icons.calendar_today,
      color: Colors.deepOrange,
      description: 'Workshops and events',
    ),
    TableInfo(
      name: 'resources',
      icon: Icons.folder,
      color: Colors.brown,
      description: 'Shared files and documents',
    ),
    TableInfo(
      name: 'meeting_notes',
      icon: Icons.note,
      color: Colors.cyan,
      description: 'Meeting notes and summaries',
    ),
    TableInfo(
      name: 'meeting_ratings',
      icon: Icons.star,
      color: Colors.amber,
      description: 'Meeting feedback ratings',
    ),
    TableInfo(
      name: 'newsletters',
      icon: Icons.newspaper,
      color: Colors.pink,
      description: 'Newsletter publications',
    ),
    TableInfo(
      name: 'progress_reports',
      icon: Icons.assessment,
      color: Colors.lime,
      description: 'Mentee progress tracking',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    
    try {
      final counts = <String, int>{};
      for (final table in _tables) {
        counts[table.name] = await _localDb.getTableCount(table.name);
      }
      
      setState(() {
        _tableCounts = counts;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCounts,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjusted to give more height
                ),
                itemCount: _tables.length,
                itemBuilder: (context, index) {
                  final table = _tables[index];
                  final count = _tableCounts[table.name] ?? 0;
                  
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocalDbTableScreen(
                              tableName: table.name,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              table.icon,
                              size: 32,
                              color: table.color,
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                table.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count rows',
                              style: TextStyle(
                                fontSize: 18,
                                color: table.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                table.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class TableInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  TableInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}