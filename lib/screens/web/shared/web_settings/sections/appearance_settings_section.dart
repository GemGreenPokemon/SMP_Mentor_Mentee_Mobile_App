import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';

class AppearanceSettingsSection extends StatelessWidget {
  final bool darkMode;
  final String language;
  final Function(bool) onDarkModeChanged;
  final VoidCallback onLanguagePressed;

  const AppearanceSettingsSection({
    super.key,
    required this.darkMode,
    required this.language,
    required this.onDarkModeChanged,
    required this.onLanguagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        _buildSwitchTile(
          'Dark Mode',
          'Toggle dark/light theme',
          darkMode,
          onDarkModeChanged,
        ),
        _buildListTile(
          'Language',
          language,
          Icons.language,
          onLanguagePressed,
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