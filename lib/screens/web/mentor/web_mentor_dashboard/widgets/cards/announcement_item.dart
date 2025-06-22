import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class AnnouncementItem extends StatefulWidget {
  final String title;
  final String content;
  final String time;
  final String? priority;
  final int index;

  const AnnouncementItem({
    super.key,
    required this.title,
    required this.content,
    required this.time,
    this.priority,
    this.index = 0,
  });

  @override
  State<AnnouncementItem> createState() => _AnnouncementItemState();
}

class _AnnouncementItemState extends State<AnnouncementItem> 
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPriority = widget.priority != null && widget.priority != 'none';
    final priorityColor = DashboardHelpers.getPriorityColor(widget.priority);
    final priorityText = DashboardHelpers.getPriorityText(widget.priority);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: DashboardDurations.hoverAnimation,
        curve: DashboardCurves.defaultCurve,
        margin: const EdgeInsets.only(bottom: DashboardSizes.spacingMedium),
        padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
        decoration: BoxDecoration(
          color: isHovered 
              ? DashboardColors.backgroundLight.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
          border: Border.all(
            color: isHovered 
                ? (hasPriority ? priorityColor.withOpacity(0.3) : DashboardColors.borderLight)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: isHovered ? [
            BoxShadow(
              color: hasPriority 
                  ? priorityColor.withOpacity(0.1)
                  : DashboardColors.shadowLight,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHovered 
                        ? DashboardColors.accentBlue.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    hasPriority ? Icons.priority_high : Icons.campaign,
                    color: hasPriority ? priorityColor : DashboardColors.accentBlueLight,
                    size: isHovered ? 24 : DashboardSizes.iconMedium,
                  ),
                ),
                const SizedBox(width: DashboardSizes.spacingSmall + 4),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: DashboardDurations.microAnimation,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isHovered 
                                ? DashboardSizes.fontLarge + 1
                                : DashboardSizes.fontLarge,
                            color: isHovered 
                                ? DashboardColors.primaryDark
                                : Colors.black87,
                          ),
                          child: Text(widget.title),
                        ),
                      ),
                      if (hasPriority)
                        AnimatedContainer(
                          duration: DashboardDurations.microAnimation,
                          transform: Matrix4.identity()
                            ..scale(isHovered ? 1.1 : 1.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                priorityColor.withOpacity(0.1),
                                priorityColor.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: priorityColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: priorityColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            priorityText,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedContainer(
              duration: DashboardDurations.microAnimation,
              margin: EdgeInsets.only(
                top: isHovered ? 10 : 8,
                bottom: isHovered ? 10 : 8,
                left: isHovered ? 40 : 36,
              ),
              child: AnimatedDefaultTextStyle(
                duration: DashboardDurations.microAnimation,
                style: TextStyle(
                  color: isHovered 
                      ? Colors.black87
                      : DashboardColors.textDarkGrey,
                  fontSize: DashboardSizes.fontMedium,
                  height: 1.5,
                ),
                child: Text(widget.content),
              ),
            ),
            AnimatedContainer(
              duration: DashboardDurations.microAnimation,
              margin: EdgeInsets.only(left: isHovered ? 40 : 36),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isHovered 
                        ? DashboardColors.accentBlue
                        : DashboardColors.textGrey,
                  ),
                  const SizedBox(width: 4),
                  AnimatedDefaultTextStyle(
                    duration: DashboardDurations.microAnimation,
                    style: TextStyle(
                      color: isHovered 
                          ? DashboardColors.accentBlue
                          : DashboardColors.textGrey,
                      fontSize: DashboardSizes.fontSmall,
                      fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
                    ),
                    child: Text(widget.time),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
        delay: Duration(milliseconds: 100 * widget.index),
        duration: const Duration(milliseconds: 600),
        curve: DashboardCurves.smoothCurve,
      )
      .slideX(
        begin: 0.05,
        end: 0,
        delay: Duration(milliseconds: 100 * widget.index),
        duration: const Duration(milliseconds: 600),
        curve: DashboardCurves.smoothCurve,
      );
  }
}