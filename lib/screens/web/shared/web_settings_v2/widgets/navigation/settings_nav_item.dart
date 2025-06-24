import 'package:flutter/material.dart';
import '../../models/settings_navigation_item.dart';
import '../../utils/settings_constants.dart';

class SettingsNavItem extends StatefulWidget {
  final SettingsNavigationItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const SettingsNavItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<SettingsNavItem> createState() => _SettingsNavItemState();
}

class _SettingsNavItemState extends State<SettingsNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: SettingsDashboardConstants.hoverAnimationDuration,
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
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
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isSelected
                ? Colors.white.withOpacity(0.15)
                : _isHovered
                    ? Colors.white.withOpacity(0.08 * _hoverAnimation.value)
                    : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (hover) {
                setState(() => _isHovered = hover);
                if (hover) {
                  _hoverController.forward();
                } else {
                  _hoverController.reverse();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: widget.isCollapsed
                    ? const EdgeInsets.all(12)
                    : SettingsDashboardConstants.navItemPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Leading indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 3,
                      height: widget.isSelected ? 24 : 0,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Icon
                    Icon(
                      widget.item.icon,
                      color: widget.isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      size: SettingsDashboardConstants.iconSizeMedium,
                    ),
                    
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 16),
                      
                      // Label
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            color: widget.isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Trailing widget for selected item
                      if (widget.isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
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