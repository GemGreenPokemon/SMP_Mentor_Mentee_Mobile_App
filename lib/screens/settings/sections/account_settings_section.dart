import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Account',
      icon: Icons.person,
      children: [
        _buildListTile(
          'Change Password',
          null,
          Icons.lock,
          () {
            // TODO: Implement change password
          },
        ),
        _buildListTile(
          'Privacy Settings',
          null,
          Icons.privacy_tip,
          () {
            // TODO: Implement privacy settings
          },
        ),
        _buildListTile(
          'Connected Accounts',
          'Google Drive, OneDrive',
          Icons.cloud,
          () {
            // TODO: Implement connected accounts
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
        leading: Icon(icon, color: const Color(0xFF0F2D52)),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}