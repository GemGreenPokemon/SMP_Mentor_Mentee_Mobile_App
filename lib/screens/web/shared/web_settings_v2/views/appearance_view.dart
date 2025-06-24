import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_settings/sections/appearance_settings_section.dart';
import '../controllers/settings_controller.dart';
import '../utils/settings_constants.dart';

class AppearanceView extends StatefulWidget {
  const AppearanceView({super.key});

  @override
  State<AppearanceView> createState() => _AppearanceViewState();
}

class _AppearanceViewState extends State<AppearanceView> {
  late bool _darkMode;
  late String _language;

  @override
  void initState() {
    super.initState();
    final controller = context.read<SettingsController>();
    _darkMode = controller.getSetting('darkMode') ?? false;
    _language = controller.getSetting('language') ?? 'English';
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: _language == 'English' 
                  ? Icon(Icons.check, color: SettingsDashboardConstants.primaryColor) 
                  : null,
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                context.read<SettingsController>().updateSetting('language', _language);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: _language == 'Spanish' 
                  ? Icon(Icons.check, color: SettingsDashboardConstants.primaryColor) 
                  : null,
              onTap: () {
                setState(() {
                  _language = 'Spanish';
                });
                context.read<SettingsController>().updateSetting('language', _language);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: _language == 'French' 
                  ? Icon(Icons.check, color: SettingsDashboardConstants.primaryColor) 
                  : null,
              onTap: () {
                setState(() {
                  _language = 'French';
                });
                context.read<SettingsController>().updateSetting('language', _language);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < SettingsDashboardConstants.mobileBreakpoint;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? SettingsDashboardConstants.compactPadding
            : SettingsDashboardConstants.defaultPadding,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: AppearanceSettingsSection(
            darkMode: _darkMode,
            language: _language,
            onDarkModeChanged: (value) {
              setState(() => _darkMode = value);
              context.read<SettingsController>().updateSetting('darkMode', value);
            },
            onLanguagePressed: _showLanguageDialog,
          ),
        ),
      ),
    );
  }
}