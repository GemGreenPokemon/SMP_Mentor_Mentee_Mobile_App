import 'package:flutter/material.dart';
import '../../web_settings/sections/help_support_section.dart';
import '../utils/settings_constants.dart';
import '../widgets/shared/settings_card.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

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
          child: Column(
            children: [
              // Quick help section
              _buildQuickHelp(context),
              const SizedBox(height: 24),
              
              // Original help section
              const HelpSupportSection(),
              const SizedBox(height: 24),
              
              // About section
              _buildAboutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickHelp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Help',
          style: SettingsDashboardConstants.subheadingStyle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SettingsCard(
                onTap: () {
                  // TODO: Open documentation
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      color: SettingsDashboardConstants.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documentation',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Browse guides and tutorials',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SettingsCard(
                onTap: () {
                  // TODO: Open FAQ
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.question_answer_outlined,
                      color: SettingsDashboardConstants.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FAQ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Common questions answered',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: SettingsDashboardConstants.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMP Mentor-Mentee App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Version 2.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'About',
            style: SettingsDashboardConstants.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The SMP Mentor-Mentee Mobile App is designed to facilitate connections '
            'between mentors and mentees in educational institutions. This platform '
            'enables seamless communication, scheduling, and progress tracking.',
            style: SettingsDashboardConstants.bodyStyle.copyWith(
              color: SettingsDashboardConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: Open privacy policy
                },
                icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                label: const Text('Privacy Policy'),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Open terms of service
                },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Terms of Service'),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Open licenses
                },
                icon: const Icon(Icons.article_outlined, size: 16),
                label: const Text('Licenses'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}