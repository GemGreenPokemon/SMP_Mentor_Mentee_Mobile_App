import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class MenteeListItem extends StatefulWidget {
  final String name;
  final String program;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onMessage;

  const MenteeListItem({
    super.key,
    required this.name,
    required this.program,
    required this.progress,
    required this.onTap,
    required this.onMessage,
  });

  @override
  State<MenteeListItem> createState() => _MenteeListItemState();
}

class _MenteeListItemState extends State<MenteeListItem> 
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DashboardDurations.counterAnimation,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DashboardCurves.smoothCurve,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DashboardDurations.hoverAnimation,
          curve: DashboardCurves.defaultCurve,
          transform: Matrix4.identity()
            ..translate(0.0, isHovered ? -4.0 : 0.0),
          padding: const EdgeInsets.all(DashboardSizes.cardPadding),
          decoration: BoxDecoration(
            color: DashboardColors.backgroundWhite,
            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
            border: Border.all(
              color: isHovered 
                  ? DashboardColors.accentBlue.withOpacity(0.3)
                  : DashboardColors.borderLight,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered 
                ? DashboardShadows.cardHoverShadow 
                : DashboardShadows.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: DashboardDurations.microAnimation,
                    transform: Matrix4.identity()
                      ..scale(isHovered ? 1.1 : 1.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isHovered)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  DashboardColors.accentBlue.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        CircleAvatar(
                          backgroundColor: isHovered 
                              ? DashboardColors.accentBlue
                              : DashboardColors.primaryLight,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: isHovered ? 24 : 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingSmall + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
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
                          child: Text(widget.name),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: DashboardDurations.microAnimation,
                          style: TextStyle(
                            color: isHovered 
                                ? DashboardColors.accentBlue 
                                : DashboardColors.textDarkGrey,
                            fontSize: DashboardSizes.fontMedium,
                          ),
                          child: Text(widget.program),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: DashboardDurations.microAnimation,
                    transform: Matrix4.identity()
                      ..scale(isHovered ? 1.2 : 1.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onMessage,
                        borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
                        splashColor: DashboardColors.accentBlue.withOpacity(0.2),
                        child: Container(
                          padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
                          decoration: BoxDecoration(
                            color: isHovered 
                                ? DashboardColors.accentBlue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
                          ),
                          child: Icon(
                            Icons.message,
                            color: isHovered 
                                ? DashboardColors.accentBlue 
                                : DashboardColors.textGrey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashboardSizes.spacingMedium),
              Row(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: DashboardDurations.microAnimation,
                    style: TextStyle(
                      color: isHovered 
                          ? DashboardColors.primaryDark 
                          : DashboardColors.textDarkGrey,
                      fontSize: DashboardSizes.fontSmall,
                      fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
                    ),
                    child: const Text(DashboardStrings.progress),
                  ),
                  const SizedBox(width: DashboardSizes.spacingSmall),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: DashboardColors.borderGrey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isHovered ? [
                                      DashboardColors.accentBlue,
                                      DashboardColors.accentBlueLight,
                                    ] : [
                                      DashboardColors.primaryDark,
                                      DashboardColors.primaryLight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: isHovered ? [
                                    BoxShadow(
                                      color: DashboardColors.accentBlue.withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ] : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingSmall),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return AnimatedDefaultTextStyle(
                        duration: DashboardDurations.microAnimation,
                        style: TextStyle(
                          color: isHovered 
                              ? DashboardColors.accentBlue 
                              : DashboardColors.textDarkGrey,
                          fontSize: DashboardSizes.fontSmall,
                          fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
                        ),
                        child: Text(
                          DashboardHelpers.formatPercentage(_progressAnimation.value),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}