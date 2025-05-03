import 'package:flutter/material.dart';
import 'local_db_table_screen.dart';
// TODO: Use LocalDatabaseService for real counts

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

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void _loadCounts() async {
    // TODO: Fetch counts from local DB via LocalDatabaseService
    // e.g. final db = LocalDatabaseService.instance;
    // _usersCount = await db.getUsersCount();
    // _mentorshipsCount = await db.getMentorshipsCount();
    // etc.
    setState(() {});
  }

  void _initializeLocalDb() {
    // TODO: Run migrations, seed tables, or clear DB as needed.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local DB initialized (TODO)')),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local DB Manager')),
      body: Padding(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock data added (TODO)')),
                  );
                },
                child: const Text('Add Mock Data'),
              ),
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
                'meeting_ratings'
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
            const SizedBox(height: 16),
            const Text(
              'TODO: Integrate LocalDatabaseService to populate counts and handle DB setup.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
