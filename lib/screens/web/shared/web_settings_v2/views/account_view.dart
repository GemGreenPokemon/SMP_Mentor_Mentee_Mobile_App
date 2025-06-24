import 'package:flutter/material.dart';
import '../../web_settings/sections/account_settings_section.dart';
import '../utils/settings_constants.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

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
          child: const AccountSettingsSection(),
        ),
      ),
    );
  }
}