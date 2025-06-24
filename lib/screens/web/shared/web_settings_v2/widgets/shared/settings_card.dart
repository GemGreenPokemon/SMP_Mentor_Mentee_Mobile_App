import 'package:flutter/material.dart';
import '../../utils/settings_constants.dart';

class SettingsCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showHoverEffect;

  const SettingsCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.showHoverEffect = true,
  });

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard>
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
        return Transform.translate(
          offset: Offset(0, widget.showHoverEffect && _isHovered ? -2 : 0),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? SettingsDashboardConstants.cardBackgroundColor,
              borderRadius: BorderRadius.circular(SettingsDashboardConstants.cardBorderRadius),
              boxShadow: [
                if (widget.showHoverEffect && _isHovered)
                  SettingsDashboardConstants.elevatedShadow
                else
                  SettingsDashboardConstants.cardShadow,
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHover: widget.onTap != null
                    ? (hover) {
                        setState(() => _isHovered = hover);
                        if (hover) {
                          _hoverController.forward();
                        } else {
                          _hoverController.reverse();
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(SettingsDashboardConstants.cardBorderRadius),
                child: Padding(
                  padding: widget.padding ?? SettingsDashboardConstants.cardCompactPadding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}