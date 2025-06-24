import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_settings/sections/notification_settings_section.dart';
import '../controllers/settings_controller.dart';
import '../utils/settings_constants.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late bool _notificationsEnabled;
  late bool _emailNotifications;

  @override
  void initState() {
    super.initState();
    final controller = context.read<SettingsController>();
    _notificationsEnabled = controller.getSetting('notificationsEnabled') ?? true;
    _emailNotifications = controller.getSetting('emailNotifications') ?? true;
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
          child: NotificationSettingsSection(
            notificationsEnabled: _notificationsEnabled,
            emailNotifications: _emailNotifications,
            onNotificationsChanged: (value) {
              setState(() => _notificationsEnabled = value);
              context.read<SettingsController>().updateSetting('notificationsEnabled', value);
            },
            onEmailNotificationsChanged: (value) {
              setState(() => _emailNotifications = value);
              context.read<SettingsController>().updateSetting('emailNotifications', value);
            },
          ),
        ),
      ),
    );
  }
}