import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/settings_controller.dart';
import 'widgets/navigation/settings_sidebar.dart';
import 'utils/settings_constants.dart';
import 'views/overview_view.dart';
import 'views/account_view.dart';
import 'views/notifications_view.dart';
import 'views/appearance_view.dart';
import 'views/storage_view.dart';
import 'views/data_management_view.dart';
import 'views/user_management_view.dart';
import 'views/database_admin_view.dart';
import 'views/developer_tools_view.dart';
import 'views/help_support_view.dart';
import '../../../../utils/responsive.dart';
import '../web_settings/widgets/auth_overlay.dart';

class WebSettingsDashboard extends StatefulWidget {
  const WebSettingsDashboard({super.key});

  @override
  State<WebSettingsDashboard> createState() => _WebSettingsDashboardState();
}

class _WebSettingsDashboardState extends State<WebSettingsDashboard>
    with TickerProviderStateMixin {
  late SettingsController _controller;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;
  
  // Auth overlay state
  bool _showAuthOverlayFlag = false;
  bool _isAuthenticated = false;
  Function()? _pendingAuthAction;

  @override
  void initState() {
    super.initState();
    
    _controller = SettingsController();
    
    // Initialize animations
    _sidebarAnimationController = AnimationController(
      duration: SettingsDashboardConstants.sidebarAnimationDuration,
      vsync: this,
    );
    
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: SettingsDashboardConstants.defaultAnimationCurve,
    );
    
    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<SettingsController>(
        builder: (context, controller, _) {
          return Stack(
            children: [
              Scaffold(
                backgroundColor: SettingsDashboardConstants.backgroundColor,
                body: Row(
                  children: [
                    // Sidebar
                    if (!isMobile || controller.isSidebarCollapsed)
                      SettingsSidebar(
                        items: controller.navigationItems,
                        selectedIndex: controller.selectedIndex,
                        onItemSelected: (index) {
                          controller.navigateToIndex(index);
                          if (isMobile) {
                            controller.setSidebarCollapsed(true);
                          }
                        },
                        isCollapsed: isMobile ? false : controller.isSidebarCollapsed,
                        onToggleCollapse: () => controller.toggleSidebar(),
                        animation: _sidebarAnimation,
                      ),
                    
                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // Top bar
                          _buildTopBar(context, controller, isMobile),
                          
                          // Content
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: SettingsDashboardConstants.pageTransitionDuration,
                              child: _buildContent(controller),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Mobile menu button
                floatingActionButton: isMobile && controller.isSidebarCollapsed
                    ? FloatingActionButton(
                        onPressed: () => controller.setSidebarCollapsed(false),
                        backgroundColor: SettingsDashboardConstants.primaryColor,
                        child: const Icon(Icons.menu),
                      )
                    : null,
              ),
              
              // Auth overlay
              if (_showAuthOverlayFlag)
                AuthOverlay(
                  onAuthSuccess: () {
                    setState(() {
                      _isAuthenticated = true;
                      _showAuthOverlayFlag = false;
                    });
                    
                    if (_pendingAuthAction != null) {
                      _pendingAuthAction!();
                      _pendingAuthAction = null;
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged in successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onCancel: () {
                    setState(() {
                      _showAuthOverlayFlag = false;
                      _pendingAuthAction = null;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, SettingsController controller, bool isMobile) {
    return Container(
      height: SettingsDashboardConstants.topBarHeight,
      decoration: BoxDecoration(
        color: SettingsDashboardConstants.cardBackgroundColor,
        boxShadow: [SettingsDashboardConstants.cardShadow],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? SettingsDashboardConstants.compactPadding
            : SettingsDashboardConstants.defaultPadding,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            tooltip: 'Back',
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Text(
            _getPageTitle(controller),
            style: SettingsDashboardConstants.headingStyle,
          ),
          
          const Spacer(),
          
          // Search
          if (!isMobile) ...[
            SizedBox(
              width: 300,
              height: 40,
              child: TextField(
                onChanged: controller.setSearchQuery,
                decoration: SettingsDashboardConstants.getInputDecoration(
                  labelText: 'Search settings...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                ).copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Search icon for mobile
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context, controller),
              tooltip: 'Search',
            ),
          
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => controller.navigateById('help_support'),
            tooltip: 'Help',
          ),
        ],
      ),
    );
  }

  String _getPageTitle(SettingsController controller) {
    final currentItem = controller.navigationItems.firstWhere(
      (item) => item.route == controller.currentRoute && item.isClickable,
      orElse: () => controller.navigationItems.first,
    );
    return currentItem.label;
  }

  Widget _buildContent(SettingsController controller) {
    // Get current navigation item
    final currentItem = controller.navigationItems.firstWhere(
      (item) => item.route == controller.currentRoute && item.isClickable,
      orElse: () => controller.navigationItems.first,
    );
    
    // Return appropriate view based on current route
    switch (currentItem.id) {
      case 'overview':
        return OverviewView(key: const ValueKey('overview'));
      case 'account':
        return AccountView(key: const ValueKey('account'));
      case 'notifications':
        return NotificationsView(key: const ValueKey('notifications'));
      case 'appearance':
        return AppearanceView(key: const ValueKey('appearance'));
      case 'file_storage':
        return StorageView(key: const ValueKey('storage'));
      case 'data_management':
        return DataManagementView(key: const ValueKey('data_management'));
      case 'user_management':
        return UserManagementView(
          key: const ValueKey('user_management'),
          onShowAuthOverlay: _showAuthOverlay,
          isAuthenticated: _isAuthenticated,
        );
      case 'database_admin':
        return DatabaseAdminView(
          key: const ValueKey('database_admin'),
          onShowAuthOverlay: _showAuthOverlay,
          isAuthenticated: _isAuthenticated,
        );
      case 'developer_tools':
        return DeveloperToolsView(key: const ValueKey('developer_tools'));
      case 'help_support':
        return HelpSupportView(key: const ValueKey('help_support'));
      default:
        return OverviewView(key: const ValueKey('default'));
    }
  }

  void _showSearchDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Settings'),
        content: TextField(
          autofocus: true,
          onChanged: controller.setSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAuthOverlay({Function()? onSuccess}) {
    setState(() {
      _showAuthOverlayFlag = true;
      _pendingAuthAction = onSuccess;
    });
  }
}