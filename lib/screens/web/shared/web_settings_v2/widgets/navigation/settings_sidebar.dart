import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/settings_navigation_item.dart';
import '../../utils/settings_constants.dart';
import 'settings_nav_item.dart';
import '../../../../../../services/auth_service.dart';

class SettingsSidebar extends StatefulWidget {
  final List<SettingsNavigationItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Animation<double>? animation;

  const SettingsSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.animation,
  });

  @override
  State<SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.isCollapsed
        ? SettingsDashboardConstants.sidebarCollapsedWidth
        : SettingsDashboardConstants.sidebarWidth;

    return AnimatedBuilder(
      animation: widget.animation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            -width * (1 - (widget.animation?.value ?? 1.0)),
            0,
          ),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: SettingsDashboardConstants.sidebarAnimationDuration,
        curve: SettingsDashboardConstants.defaultAnimationCurve,
        width: width,
        height: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: SettingsDashboardConstants.primaryGradient,
              ),
            ),
            
            // Glassmorphism overlay
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1 * _glowAnimation.value),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Content
            Column(
              children: [
                // Header
                _buildHeader(),
                
                // Navigation items
                Expanded(
                  child: _buildNavigationItems(),
                ),
                
                // Footer
                _buildFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: SettingsDashboardConstants.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!widget.isCollapsed) ...[
            const Icon(
              Icons.settings,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.settings,
              color: Colors.white,
              size: 24,
            ),
          ],
          if (!widget.isCollapsed) const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              widget.isCollapsed ? Icons.menu : Icons.menu_open,
              color: Colors.white,
              size: 20,
            ),
            onPressed: widget.onToggleCollapse,
            tooltip: widget.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    final clickableItems = widget.items.where((item) => item.isClickable).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        
        if (item.isDivider) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: Colors.white.withOpacity(0.2),
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
          );
        }
        
        if (item.isHeader) {
          if (widget.isCollapsed) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Text(
              item.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          );
        }
        
        // Find the actual index among clickable items
        final clickableIndex = clickableItems.indexOf(item);
        final isSelected = clickableIndex == widget.selectedIndex;
        
        return SettingsNavItem(
          item: item,
          isSelected: isSelected,
          isCollapsed: widget.isCollapsed,
          onTap: () => widget.onItemSelected(clickableIndex),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? 8 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: widget.isCollapsed
          ? Center(child: _buildCollapsedUserInfo())
          : _buildExpandedUserInfo(),
    );
  }

  Widget _buildCollapsedUserInfo() {
    final user = _authService.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final initials = _getInitials(userName);
    return CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.2),
          radius: 20,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
  }

  Widget _buildExpandedUserInfo() {
    return FutureBuilder<Map<String, String?>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final userName = snapshot.data?['name'] ?? 'Loading...';
        final userEmail = snapshot.data?['email'] ?? '';
        final userRole = snapshot.data?['role'] ?? '';
        
        return Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              radius: 20,
              child: Text(
                _getInitials(userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userRole.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String?>> _getUserInfo() async {
    final user = _authService.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email;
    final role = await _authService.getUserRole();
    
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'
        .toUpperCase();
  }
}