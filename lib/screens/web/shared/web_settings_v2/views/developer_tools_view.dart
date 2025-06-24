import 'package:flutter/material.dart';
import '../../web_settings/sections/developer_tools_section.dart';
import '../utils/settings_constants.dart';

class DeveloperToolsView extends StatelessWidget {
  const DeveloperToolsView({super.key});

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
          child: const DeveloperToolsSection(),
        ),
      ),
    );
  }
}