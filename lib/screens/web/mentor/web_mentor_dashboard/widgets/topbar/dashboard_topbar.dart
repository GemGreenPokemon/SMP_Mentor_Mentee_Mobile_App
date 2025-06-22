import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';
import '../dialogs/notifications_panel.dart';
import 'topbar_action_button.dart';

class DashboardTopbar extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onSearch;
  final VoidCallback onContactCoordinator;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final DateTime? lastRefresh;

  const DashboardTopbar({
    super.key,
    required this.selectedIndex,
    required this.onSearch,
    required this.onContactCoordinator,
    this.onRefresh,
    this.isRefreshing = false,
    this.lastRefresh,
  });

  @override
  State<DashboardTopbar> createState() => _DashboardTopbarState();
}

class _DashboardTopbarState extends State<DashboardTopbar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _notificationPulse;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _notificationPulse = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _notificationPulse,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _notificationPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DashboardBlur.medium,
          sigmaY: DashboardBlur.medium,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            DashboardSizes.spacingXLarge,
            20,
            DashboardSizes.spacingXLarge,
            20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DashboardColors.backgroundWhite.withOpacity(0.9),
                DashboardColors.backgroundLight.withOpacity(0.85),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: DashboardColors.borderLight.withOpacity(0.5),
                width: 1,
              ),
            ),
            boxShadow: DashboardShadows.topbarShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: DashboardDurations.fadeAnimation,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: DashboardCurves.smoothCurve)),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        SidebarItems.titles[widget.selectedIndex],
                        key: ValueKey(widget.selectedIndex),
                        style: const TextStyle(
                          fontSize: DashboardSizes.fontTitle,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ).animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideX(
                          begin: -0.05,
                          end: 0,
                          curve: DashboardCurves.smoothCurve,
                        ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: DashboardDurations.fadeAnimation,
                      child: Text(
                        SidebarItems.getPageDescription(widget.selectedIndex),
                        key: ValueKey('${widget.selectedIndex}_desc'),
                        style: TextStyle(
                          fontSize: DashboardSizes.fontMedium,
                          color: DashboardColors.textDarkGrey,
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate()
                        .fadeIn(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 400),
                        ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DashboardColors.backgroundLight.withOpacity(0.8),
                      DashboardColors.backgroundWhite.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
                  border: Border.all(
                    color: DashboardColors.borderLight.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    TopbarActionButton(
                      icon: Icons.search,
                      tooltip: DashboardStrings.search,
                      onPressed: widget.onSearch,
                    ).animate()
                      .scale(
                        delay: const Duration(milliseconds: 300),
                        duration: const Duration(milliseconds: 400),
                        curve: DashboardCurves.bounceCurve,
                      ),
                    const SizedBox(width: 8),
                    if (widget.onRefresh != null) ...[
                      if (widget.isRefreshing)
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DashboardColors.accentBlue,
                              ),
                            ),
                          ),
                        ).animate(
                          onPlay: (controller) => controller.repeat(),
                        ).rotate(
                          duration: const Duration(seconds: 1),
                          curve: Curves.linear,
                        )
                      else
                        TopbarActionButton(
                          icon: Icons.refresh,
                          tooltip: 'Refresh Dashboard',
                          onPressed: widget.onRefresh!,
                        ).animate()
                          .scale(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 400),
                            curve: DashboardCurves.bounceCurve,
                          ),
                      const SizedBox(width: 8),
                    ],
                    TopbarActionButton(
                      icon: Icons.support_agent,
                      tooltip: DashboardStrings.coordinator,
                      onPressed: widget.onContactCoordinator,
                    ).animate()
                      .scale(
                        delay: const Duration(milliseconds: 500),
                        duration: const Duration(milliseconds: 400),
                        curve: DashboardCurves.bounceCurve,
                      ),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        TopbarActionButton(
                          icon: Icons.notifications_outlined,
                          tooltip: DashboardStrings.notifications,
                          onPressed: () => NotificationsPanel.show(context),
                        ).animate()
                          .scale(
                            delay: const Duration(milliseconds: 600),
                            duration: const Duration(milliseconds: 400),
                            curve: DashboardCurves.bounceCurve,
                          ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: DashboardColors.statusRed,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: DashboardColors.statusRed.withOpacity(0.6),
                                      blurRadius: 4 * _pulseAnimation.value,
                                      spreadRadius: 1 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}