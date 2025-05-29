import 'package:flutter/material.dart';

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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final item = routes[i];
          return ListTile(
            title: Text(item['label']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(
              context, item['route']!),
          );
        },
      ),
    );
  }
}
