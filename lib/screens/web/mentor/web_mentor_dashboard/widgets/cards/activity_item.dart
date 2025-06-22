import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/dashboard_constants.dart';

class ActivityItem extends StatefulWidget {
  final String text;
  final String time;
  final IconData icon;
  final Color color;
  final int index;

  const ActivityItem({
    super.key,
    required this.text,
    required this.time,
    required this.icon,
    required this.color,
    this.index = 0,
  });

  @override
  State<ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<ActivityItem> 
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _dotAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: DashboardDurations.hoverAnimation,
        curve: DashboardCurves.defaultCurve,
        padding: EdgeInsets.symmetric(
          vertical: isHovered ? 12 : DashboardSizes.spacingSmall,
          horizontal: isHovered ? 12 : 0,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isHovered 
              ? widget.color.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
          border: Border.all(
            color: isHovered 
                ? widget.color.withOpacity(0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Timeline indicator
            AnimatedContainer(
              duration: DashboardDurations.microAnimation,
              padding: EdgeInsets.all(isHovered ? 10 : DashboardSizes.spacingSmall),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    widget.color.withOpacity(isHovered ? 0.2 : 0.1),
                    widget.color.withOpacity(isHovered ? 0.1 : 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: isHovered ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: Icon(
                widget.icon,
                size: isHovered ? 18 : DashboardSizes.iconSmall,
                color: widget.color,
              ),
            ),
            const SizedBox(width: DashboardSizes.spacingSmall + 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: DashboardDurations.microAnimation,
                    style: TextStyle(
                      fontSize: isHovered 
                          ? DashboardSizes.fontMedium + 1
                          : DashboardSizes.fontMedium,
                      color: isHovered 
                          ? Colors.black87
                          : DashboardColors.textDarkGrey,
                      fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
                    ),
                    child: Text(widget.text),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isHovered 
                            ? widget.color
                            : DashboardColors.textGrey,
                      ),
                      const SizedBox(width: 4),
                      AnimatedDefaultTextStyle(
                        duration: DashboardDurations.microAnimation,
                        style: TextStyle(
                          fontSize: DashboardSizes.fontSmall,
                          color: isHovered 
                              ? widget.color
                              : DashboardColors.textGrey,
                          fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
                        ),
                        child: Text(widget.time),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action indicator
            AnimatedOpacity(
              duration: DashboardDurations.microAnimation,
              opacity: isHovered ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: DashboardDurations.microAnimation,
                transform: Matrix4.identity()
                  ..translate(isHovered ? 0.0 : 10.0, 0.0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: widget.color,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
        delay: Duration(milliseconds: 200 + (widget.index * 100)),
        duration: const Duration(milliseconds: 600),
        curve: DashboardCurves.smoothCurve,
      )
      .slideX(
        begin: -0.05,
        end: 0,
        delay: Duration(milliseconds: 200 + (widget.index * 100)),
        duration: const Duration(milliseconds: 600),
        curve: DashboardCurves.smoothCurve,
      )
      .scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        delay: Duration(milliseconds: 200 + (widget.index * 100)),
        duration: const Duration(milliseconds: 600),
        curve: DashboardCurves.smoothCurve,
      );
  }
}