import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

/// A standardized container for dashboard cards that ensures consistent
/// appearance and behavior across all dashboard components
class DashboardCardContainer extends StatefulWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool enableHoverEffects;
  final bool showBorder;
  final double? minHeight;
  final double? maxHeight;
  final bool scrollable;

  const DashboardCardContainer({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.onTap,
    this.actions,
    this.padding,
    this.backgroundColor,
    this.enableHoverEffects = true,
    this.showBorder = false,
    this.minHeight,
    this.maxHeight,
    this.scrollable = false,
  }) : assert(
          title == null || titleWidget == null,
          'Cannot provide both title and titleWidget',
        );

  @override
  State<DashboardCardContainer> createState() => _DashboardCardContainerState();
}

class _DashboardCardContainerState extends State<DashboardCardContainer> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHoverEffects ? (_) => setState(() => isHovered = true) : null,
      onExit: widget.enableHoverEffects ? (_) => setState(() => isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DashboardDurations.hoverAnimation,
          curve: DashboardCurves.defaultCurve,
          constraints: BoxConstraints(
            minHeight: widget.minHeight ?? 0,
            maxHeight: widget.maxHeight ?? double.infinity,
          ),
          transform: Matrix4.identity()
            ..scale(isHovered && widget.enableHoverEffects ? 1.01 : 1.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? DashboardColors.backgroundWhite,
            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
            boxShadow: isHovered && widget.enableHoverEffects
                ? DashboardShadows.cardHoverShadow
                : DashboardShadows.cardShadow,
            border: widget.showBorder || (isHovered && widget.enableHoverEffects)
                ? Border.all(
                    color: isHovered
                        ? DashboardColors.accentBlue.withOpacity(0.2)
                        : DashboardColors.borderLight,
                    width: 1,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.title != null || widget.titleWidget != null || widget.actions != null)
                  _buildHeader(),
                Flexible(
                  child: widget.scrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: widget.padding ?? 
                              const EdgeInsets.all(DashboardSizes.cardPadding),
                          child: widget.child,
                        )
                      : Padding(
                          padding: widget.padding ?? 
                              const EdgeInsets.all(DashboardSizes.cardPadding),
                          child: widget.child,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DashboardSizes.cardPadding,
        DashboardSizes.cardPadding,
        DashboardSizes.spacingMedium,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.titleWidget != null)
            Expanded(child: widget.titleWidget!)
          else if (widget.title != null)
            Expanded(
              child: Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: DashboardSizes.fontXLarge,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.primaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (widget.actions != null) ...[
            const SizedBox(width: DashboardSizes.spacingMedium),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.actions!,
            ),
          ],
        ],
      ),
    );
  }
}

/// A standardized action button for card headers
class DashboardCardAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;

  const DashboardCardAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: DashboardColors.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardSizes.spacingMedium,
            vertical: DashboardSizes.spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: DashboardColors.accentBlue,
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardSizes.spacingMedium,
          vertical: DashboardSizes.spacingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
        ),
      ),
    );
  }
}