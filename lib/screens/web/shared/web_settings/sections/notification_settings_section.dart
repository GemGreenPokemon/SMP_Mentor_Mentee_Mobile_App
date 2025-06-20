import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';

class NotificationSettingsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final Function(bool) onNotificationsChanged;
  final Function(bool) onEmailNotificationsChanged;

  const NotificationSettingsSection({
    super.key,
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.onNotificationsChanged,
    required this.onEmailNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          'Push Notifications',
          'Receive app notifications',
          notificationsEnabled,
          onNotificationsChanged,
        ),
        _buildSwitchTile(
          'Email Notifications',
          'Receive email updates',
          emailNotifications,
          onEmailNotificationsChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F2D52),
      ),
    );
  }
}