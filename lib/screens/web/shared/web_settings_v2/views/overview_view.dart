import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../utils/settings_constants.dart';
import '../widgets/shared/settings_card.dart';
import '../../../../../services/auth_service.dart';

class OverviewView extends StatefulWidget {
  const OverviewView({super.key});

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  final AuthService _authService = AuthService();
  
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < SettingsDashboardConstants.mobileBreakpoint;
    final isTablet = screenWidth < SettingsDashboardConstants.tabletBreakpoint;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? SettingsDashboardConstants.compactPadding
            : SettingsDashboardConstants.defaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeSection(),
          const SizedBox(height: 32),
          
          // Quick settings grid
          _buildQuickSettingsGrid(controller, isMobile, isTablet),
          const SizedBox(height: 32),
          
          // Recent activity
          _buildRecentActivity(),
          const SizedBox(height: 32),
          
          // System status
          _buildSystemStatus(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = _authService.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    
    return Container(
          padding: SettingsDashboardConstants.cardPadding,
          decoration: SettingsDashboardConstants.elevatedCardDecoration,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: SettingsDashboardConstants.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: SettingsDashboardConstants.headingStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your application settings and preferences',
                      style: SettingsDashboardConstants.bodyStyle.copyWith(
                        color: SettingsDashboardConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildQuickSettingsGrid(
    SettingsController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    
    final quickSettings = [
      _QuickSettingItem(
        title: 'Notifications',
        subtitle: 'Manage notification preferences',
        icon: Icons.notifications_outlined,
        color: Colors.blue,
        value: controller.getSetting('notificationsEnabled') ?? true,
        onTap: () => controller.navigateById('notifications'),
      ),
      _QuickSettingItem(
        title: 'Appearance',
        subtitle: 'Theme and display settings',
        icon: Icons.palette_outlined,
        color: Colors.purple,
        value: controller.getSetting('darkMode') ?? false,
        onTap: () => controller.navigateById('appearance'),
      ),
      _QuickSettingItem(
        title: 'Account',
        subtitle: 'Profile and security',
        icon: Icons.person_outline,
        color: Colors.green,
        onTap: () => controller.navigateById('account'),
      ),
      _QuickSettingItem(
        title: 'Storage',
        subtitle: 'File management',
        icon: Icons.folder_outlined,
        color: Colors.orange,
        onTap: () => controller.navigateById('file_storage'),
      ),
      _QuickSettingItem(
        title: 'Data Import/Export',
        subtitle: 'Manage your data',
        icon: Icons.import_export,
        color: Colors.teal,
        onTap: () => controller.navigateById('data_management'),
      ),
      _QuickSettingItem(
        title: 'Help & Support',
        subtitle: 'Get assistance',
        icon: Icons.help_outline,
        color: Colors.red,
        onTap: () => controller.navigateById('help_support'),
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Settings',
          style: SettingsDashboardConstants.subheadingStyle,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 1.5 : 1.3,
          ),
          itemCount: quickSettings.length,
          itemBuilder: (context, index) {
            final item = quickSettings[index];
            return _buildQuickSettingCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildQuickSettingCard(_QuickSettingItem item) {
    return SettingsCard(
      onTap: item.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (item.value != null)
                _buildStatusIndicator(item.value as bool),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: SettingsDashboardConstants.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: SettingsDashboardConstants.captionStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isEnabled) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: SettingsDashboardConstants.subheadingStyle,
        ),
        const SizedBox(height: 16),
        SettingsCard(
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.person,
                title: 'Profile Updated',
                subtitle: 'You updated your profile information',
                time: '2 hours ago',
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.notifications,
                title: 'Notifications Disabled',
                subtitle: 'Email notifications were turned off',
                time: 'Yesterday',
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.upload,
                title: 'Data Exported',
                subtitle: 'User data was exported successfully',
                time: '3 days ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SettingsDashboardConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: SettingsDashboardConstants.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SettingsDashboardConstants.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: SettingsDashboardConstants.captionStyle,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: SettingsDashboardConstants.captionStyle,
        ),
      ],
    );
  }

  Widget _buildSystemStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: SettingsDashboardConstants.subheadingStyle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                title: 'Storage Used',
                value: '2.3 GB',
                subtitle: 'of 10 GB',
                icon: Icons.storage,
                color: Colors.blue,
                progress: 0.23,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusCard(
                title: 'Active Users',
                value: '156',
                subtitle: 'Currently online',
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusCard(
                title: 'System Health',
                value: 'Good',
                subtitle: 'All services running',
                icon: Icons.favorite,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: SettingsDashboardConstants.captionStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: SettingsDashboardConstants.headingStyle.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: SettingsDashboardConstants.captionStyle,
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickSettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final dynamic value;
  final VoidCallback onTap;

  const _QuickSettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.value,
    required this.onTap,
  });
}