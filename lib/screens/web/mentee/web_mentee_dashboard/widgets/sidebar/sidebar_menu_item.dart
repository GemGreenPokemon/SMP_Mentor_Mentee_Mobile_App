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
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: DashboardDurations.quick,
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (isHovered) {
                setState(() {
                  _isHovered = isHovered;
                  if (isHovered) {
                    _hoverController.forward();
                  } else {
                    _hoverController.reverse();
                  }
                });
              },
              borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardSizes.spacingMedium,
                  vertical: DashboardSizes.spacingSmall + 4,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? DashboardColors.accentBlue.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05 * _hoverAnimation.value),
                  borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                  border: Border.all(
                    color: widget.isSelected
                        ? DashboardColors.accentBlue.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Animated icon container
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? DashboardColors.accentBlue.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05 + (0.05 * _hoverAnimation.value)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          widget.isSelected && widget.item.selectedIcon != null
                              ? widget.item.selectedIcon
                              : widget.item.icon,
                          color: widget.isSelected
                              ? DashboardColors.accentBlue
                              : DashboardColors.textLight.withOpacity(0.7 + (0.3 * _hoverAnimation.value)),
                          size: DashboardSizes.iconSizeMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: DashboardSizes.spacingSmall + 4),
                    // Text
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: DashboardTextStyles.body.copyWith(
                          color: widget.isSelected
                              ? DashboardColors.textLight
                              : DashboardColors.textLight.withOpacity(0.7 + (0.3 * _hoverAnimation.value)),
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Badge if exists
                    if (widget.item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.badgeColor ?? DashboardColors.accentRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.item.badge!,
                          style: DashboardTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Selection indicator
                    if (widget.isSelected)
                      Container(
                        width: 3,
                        height: 24,
                        margin: const EdgeInsets.only(left: DashboardSizes.spacingSmall),
                        decoration: BoxDecoration(
                          color: DashboardColors.accentBlue,
                          borderRadius: BorderRadius.circular(1.5),
                          boxShadow: [
                            BoxShadow(
                              color: DashboardColors.accentBlue.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(-1, 0),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}