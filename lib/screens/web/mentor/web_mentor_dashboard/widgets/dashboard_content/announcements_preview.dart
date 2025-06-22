import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/announcement_item.dart';

class AnnouncementsPreview extends StatefulWidget {
  final List<Announcement> announcements;
  final VoidCallback onViewAll;

  const AnnouncementsPreview({
    super.key,
    required this.announcements,
    required this.onViewAll,
  });

  @override
  State<AnnouncementsPreview> createState() => _AnnouncementsPreviewState();
}

class _AnnouncementsPreviewState extends State<AnnouncementsPreview> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: DashboardDurations.hoverAnimation,
        curve: DashboardCurves.defaultCurve,
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.01 : 1.0),
        decoration: BoxDecoration(
          color: DashboardColors.backgroundWhite,
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
          boxShadow: isHovered 
              ? [
                  BoxShadow(
                    color: DashboardColors.accentBlue.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: DashboardColors.shadowMedium,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : DashboardShadows.cardShadow,
          border: Border.all(
            color: isHovered 
                ? DashboardColors.accentBlue.withOpacity(0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
          child: Stack(
            children: [
              // Gradient background overlay
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: DashboardDurations.hoverAnimation,
                  opacity: isHovered ? 0.03 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DashboardColors.accentBlue,
                          DashboardColors.primaryLight,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DashboardSizes.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    DashboardColors.accentBlue.withOpacity(0.1),
                                    DashboardColors.accentBlueLight.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
                              ),
                              child: Icon(
                                Icons.campaign,
                                color: DashboardColors.accentBlue,
                                size: 24,
                              ),
                            ).animate()
                              .scale(
                                delay: const Duration(milliseconds: 200),
                                duration: const Duration(milliseconds: 600),
                                curve: DashboardCurves.bounceCurve,
                              ),
                            const SizedBox(width: DashboardSizes.spacingMedium),
                            Text(
                              DashboardStrings.announcements,
                              style: TextStyle(
                                fontSize: DashboardSizes.fontXLarge,
                                fontWeight: FontWeight.bold,
                                color: DashboardColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onViewAll,
                            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isHovered 
                                      ? DashboardColors.accentBlue
                                      : DashboardColors.borderLight,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                                color: isHovered 
                                    ? DashboardColors.accentBlue.withOpacity(0.05)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DashboardStrings.viewAll,
                                    style: TextStyle(
                                      color: isHovered 
                                          ? DashboardColors.accentBlue
                                          : DashboardColors.textDarkGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: isHovered 
                                        ? DashboardColors.accentBlue
                                        : DashboardColors.textDarkGrey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DashboardSizes.spacingLarge),
                    if (widget.announcements.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(DashboardSizes.spacingXLarge),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: DashboardColors.textGrey,
                              ),
                              const SizedBox(height: DashboardSizes.spacingMedium),
                              Text(
                                'No announcements yet',
                                style: TextStyle(
                                  color: DashboardColors.textGrey,
                                  fontSize: DashboardSizes.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...widget.announcements.take(3).toList().asMap().entries.map(
                        (entry) => AnnouncementItem(
                          title: entry.value.title,
                          content: entry.value.content,
                          time: entry.value.time,
                          priority: entry.value.priority,
                          index: entry.key,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}