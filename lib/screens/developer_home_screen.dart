import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/test_mode_manager.dart';

class DeveloperHomeScreen extends StatelessWidget {
  const DeveloperHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routes = [
      {'label': 'Mentee',     'route': '/mentee'},
      {'label': 'Mentor',     'route': '/mentor'},
      {'label': 'Coordinator','route': '/coordinator'},
      {'label': 'Qualtrics',  'route': '/qualtrics'},
      {'label': 'Settings',   'route': '/settings'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Mode')),
      body: Consumer<TestModeManager>(
        builder: (context, testModeManager, child) {
          return Column(
            children: [
              // Test Mode Status Card
              if (testModeManager.isTestModeInstance)
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bug_report, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Test Mode Active',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (testModeManager.currentTestMentorInstance != null)
                          Text('Mentor: ${testModeManager.currentTestMentorInstance!.name}'),
                        if (testModeManager.currentTestMenteeInstance != null)
                          Text('Mentee: ${testModeManager.currentTestMenteeInstance!.name}'),
                        const SizedBox(height: 12),
                        const Text(
                          'Tip: Navigate to Mentor or Mentee dashboard to see test data',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Navigation List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final item = routes[i];
                    
                    // Add subtitle for mentor/mentee if test mode is active
                    String? subtitle;
                    if (testModeManager.isTestModeInstance) {
                      if (item['label'] == 'Mentor' && testModeManager.currentTestMentorInstance != null) {
                        subtitle = 'Test as: ${testModeManager.currentTestMentorInstance!.name}';
                      } else if (item['label'] == 'Mentee' && testModeManager.currentTestMenteeInstance != null) {
                        subtitle = 'Test as: ${testModeManager.currentTestMenteeInstance!.name}';
                      }
                    }
                    
                    return ListTile(
                      title: Text(item['label']!),
                      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.blue[600])) : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pushNamed(context, item['route']!),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}