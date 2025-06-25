import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class DashboardCardContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool showHoverEffect;

  const DashboardCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.showHoverEffect = true,
  });

  @override
  State<DashboardCardContainer> createState() => _DashboardCardContainerState();
}

class _DashboardCardContainerState extends State<DashboardCardContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: DashboardDurations.normal,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: DashboardSizes.cardHoverScale,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
    return MouseRegion(
      onEnter: widget.showHoverEffect ? (_) => _onHover(true) : null,
      onExit: widget.showHoverEffect ? (_) => _onHover(false) : null,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: DashboardColors.backgroundCard,
                borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
                boxShadow: [
                  ...DashboardShadows.cardShadow,
                  if (_shadowAnimation.value > 0)
                    BoxShadow(
                      color: DashboardColors.accentBlue.withOpacity(0.08 * _shadowAnimation.value),
                      blurRadius: 20 * _shadowAnimation.value,
                      offset: Offset(0, 6 * _shadowAnimation.value),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(DashboardSizes.spacingLarge),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    });
  }
}