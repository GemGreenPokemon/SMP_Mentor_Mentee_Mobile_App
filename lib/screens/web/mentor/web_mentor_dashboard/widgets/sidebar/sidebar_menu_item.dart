import 'package:flutter/material.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';

class SidebarMenuItem extends StatefulWidget {
  final SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> 
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DashboardDurations.microAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DashboardCurves.smoothCurve,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DashboardCurves.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool hover) {
    setState(() => isHovered = hover);
    if (hover) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: DashboardDurations.hoverAnimation,
          curve: DashboardCurves.defaultCurve,
          transform: Matrix4.identity()
            ..translate(isHovered ? 4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.08),
                    ],
                  )
                : null,
            color: !widget.isSelected && isHovered
                ? Colors.white.withOpacity(0.06)
                : null,
            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
            border: widget.isSelected
                ? Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  )
                : null,
            boxShadow: widget.isSelected ? [
              BoxShadow(
                color: DashboardColors.accentBlue.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardSizes.spacingMedium,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: AnimatedContainer(
                              duration: DashboardDurations.hoverAnimation,
                              padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
                              decoration: BoxDecoration(
                                color: widget.isSelected
                                    ? Colors.white.withOpacity(0.15)
                                    : isHovered
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                              ),
                              child: Icon(
                                widget.item.icon,
                                color: widget.isSelected || isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: DashboardSizes.spacingSmall + 4),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: DashboardDurations.microAnimation,
                        style: TextStyle(
                          fontWeight: widget.isSelected || isHovered
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: widget.isSelected || isHovered
                              ? Colors.white
                              : Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          letterSpacing: isHovered ? 0.5 : 0,
                        ),
                        child: Text(widget.item.title),
                      ),
                    ),
                    AnimatedContainer(
                      duration: DashboardDurations.hoverAnimation,
                      width: widget.isSelected ? 4 : 0,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: widget.isSelected ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}