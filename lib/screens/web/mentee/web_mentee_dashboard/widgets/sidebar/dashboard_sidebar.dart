import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/dashboard_data.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';
import 'sidebar_header.dart';
import 'sidebar_profile.dart';
import 'sidebar_menu_item.dart';
import 'sidebar_footer.dart';

class DashboardSidebar extends StatefulWidget {
  final Animation<double> animation;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final MenteeProfile? menteeProfile;

  const DashboardSidebar({
    super.key,
    required this.animation,
    required this.selectedIndex,
    required this.onItemSelected,
    this.menteeProfile,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

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
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(DashboardSizes.sidebarAnimationOffset * (1 - widget.animation.value), 0),
          child: Container(
            width: DashboardSizes.sidebarWidth,
            decoration: BoxDecoration(
              boxShadow: DashboardShadows.sidebarShadow,
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: DashboardBlur.backdrop,
                  sigmaY: DashboardBlur.backdrop,
                ),
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            DashboardColors.primaryDark.withOpacity(0.95),
                            DashboardColors.primaryDarkSecondary.withOpacity(0.98),
                          ],
                        ),
                        border: Border(
                          right: BorderSide(
                            color: DashboardColors.accentBlue.withOpacity(0.1 + (_glowAnimation.value * 0.1)),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Subtle animated gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0.8, -0.5),
                                  radius: 1.5,
                                  colors: [
                                    DashboardColors.accentBlue.withOpacity(0.03 + (_glowAnimation.value * 0.02)),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              const SidebarHeader(),
                              SidebarProfile(profile: widget.menteeProfile),
                              const SizedBox(height: DashboardSizes.spacingLarge),
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: DashboardSizes.spacingSmall + 4),
                                  itemCount: SidebarItems.items.length,
                                  itemBuilder: (context, index) {
                                    final item = SidebarItems.items[index];
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: Duration(milliseconds: 300 + (index * 50)),
                                      curve: DashboardCurves.smoothCurve,
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(-20 * (1 - value), 0),
                                          child: Opacity(
                                            opacity: value,
                                            child: SidebarMenuItem(
                                              item: item,
                                              isSelected: widget.selectedIndex == index,
                                              onTap: () => widget.onItemSelected(index),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SidebarFooter(),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}