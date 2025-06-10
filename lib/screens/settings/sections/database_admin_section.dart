import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';

class DatabaseAdminSection extends StatelessWidget {
  final VoidCallback onInitializeDatabase;

  const DatabaseAdminSection({
    super.key,
    required this.onInitializeDatabase,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Database Administration',
      icon: Icons.admin_panel_settings,
      children: [
        _buildListTile(
          'Initialize Firestore Database',
          'Configure state, city, and campus',
          Icons.add_circle_outline,
          onInitializeDatabase,
        ),
      ],
    );
  }

  Widget _buildListTile(String title, String? subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F2D52)),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}