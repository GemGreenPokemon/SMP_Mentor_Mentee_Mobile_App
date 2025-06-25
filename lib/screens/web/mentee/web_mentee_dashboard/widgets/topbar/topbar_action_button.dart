import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class TopbarActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isPrimary;

  const TopbarActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<TopbarActionButton> createState() => _TopbarActionButtonState();
}

class _TopbarActionButtonState extends State<TopbarActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DashboardDurations.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: DashboardSizes.buttonHoverScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onHover: (isHovered) {
                  setState(() {
                    _isHovered = isHovered;
                    if (isHovered) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                child: AnimatedContainer(
                  duration: DashboardDurations.quick,
                  padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? (_isHovered
                            ? DashboardColors.accentBlue
                            : DashboardColors.accentBlue.withOpacity(0.1))
                        : (_isHovered
                            ? DashboardColors.borderLight
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                    border: Border.all(
                      color: widget.isPrimary
                          ? DashboardColors.accentBlue
                          : (_isHovered
                              ? DashboardColors.borderMedium
                              : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isPrimary
                        ? (_isHovered
                            ? Colors.white
                            : DashboardColors.accentBlue)
                        : (_isHovered
                            ? DashboardColors.textPrimary
                            : DashboardColors.textSecondary),
                    size: DashboardSizes.iconSizeMedium,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}