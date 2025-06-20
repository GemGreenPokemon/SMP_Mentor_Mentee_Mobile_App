import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';
import '../utils/settings_constants.dart';

class HelpSupportSection extends StatelessWidget {
  const HelpSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Help & Support',
      icon: Icons.help,
      children: [
        _buildListTile(
          'FAQ',
          null,
          Icons.question_answer,
          () {
            // TODO: Show FAQ
          },
        ),
        _buildListTile(
          'Contact Support',
          null,
          Icons.support_agent,
          () {
            // TODO: Show contact support options
          },
        ),
        _buildListTile(
          'About',
          'Version 1.0.0',
          Icons.info,
          () {
            // TODO: Show about dialog
          },
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
        leading: Icon(icon, color: SettingsConstants.primaryColor),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}