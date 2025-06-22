import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class TopbarActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const TopbarActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<TopbarActionButton> createState() => _TopbarActionButtonState();
}

class _TopbarActionButtonState extends State<TopbarActionButton> 
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  bool isPressed = false;
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
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DashboardCurves.smoothCurve,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
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
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: isPressed ? 0.95 : _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: AnimatedContainer(
                  duration: DashboardDurations.microAnimation,
                  decoration: BoxDecoration(
                    color: isHovered 
                        ? DashboardColors.accentBlue.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                    border: Border.all(
                      color: isHovered 
                          ? DashboardColors.accentBlue.withOpacity(0.2)
                          : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isHovered ? [
                      BoxShadow(
                        color: DashboardColors.accentBlue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Add ripple effect on tap
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        widget.onPressed();
                      },
                      borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                      splashColor: DashboardColors.accentBlue.withOpacity(0.2),
                      highlightColor: DashboardColors.accentBlue.withOpacity(0.1),
                      child: Tooltip(
                        message: widget.tooltip,
                        preferBelow: false,
                        verticalOffset: 20,
                        decoration: BoxDecoration(
                          color: DashboardColors.primaryDark,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: DashboardColors.shadowDark,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: DashboardSizes.fontSmall,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: AnimatedContainer(
                            duration: DashboardDurations.microAnimation,
                            child: Icon(
                              widget.icon,
                              size: isHovered ? 24 : 22,
                              color: isHovered 
                                  ? DashboardColors.accentBlue
                                  : DashboardColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}