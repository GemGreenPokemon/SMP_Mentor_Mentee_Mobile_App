import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class MeetingItem extends StatefulWidget {
  final String id;
  final String title;
  final String menteeName;
  final String time;
  final String location;
  final Color color;
  final String? status;
  final String? createdBy;
  final String? currentUserId;
  final String? cancellationReason;
  final String? cancelledBy;
  final VoidCallback onTap;
  final Function(String)? onAccept;
  final Function(String)? onReject;
  final Function(String)? onClear;
  final Function(String)? onCancel;
  final Function(String)? onReschedule;

  const MeetingItem({
    super.key,
    required this.id,
    required this.title,
    required this.menteeName,
    required this.time,
    required this.location,
    required this.color,
    this.status,
    this.createdBy,
    this.currentUserId,
    this.cancellationReason,
    this.cancelledBy,
    required this.onTap,
    this.onAccept,
    this.onReject,
    this.onClear,
    this.onCancel,
    this.onReschedule,
  });

  @override
  State<MeetingItem> createState() => _MeetingItemState();
}

class _MeetingItemState extends State<MeetingItem> 
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: DashboardDurations.hoverAnimation,
        curve: DashboardCurves.defaultCurve,
        transform: Matrix4.identity()
          ..translate(0.0, isHovered ? -6.0 : 0.0)
          ..scale(isHovered ? 1.02 : 1.0),
        padding: const EdgeInsets.all(DashboardSizes.cardPadding),
        decoration: BoxDecoration(
          color: DashboardColors.backgroundWhite,
          gradient: isHovered ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DashboardColors.backgroundWhite,
              widget.color.withOpacity(0.05),
            ],
          ) : null,
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
          border: Border.all(
            color: isHovered 
                ? widget.color.withOpacity(0.4)
                : DashboardColors.borderLight,
            width: isHovered ? 2 : 1,
          ),
          boxShadow: isHovered 
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: DashboardColors.shadowDark,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : DashboardShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.6),
                            blurRadius: isHovered ? 8.0 * _pulseAnimation.value : 0,
                            spreadRadius: isHovered ? 2.0 : 0,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: DashboardSizes.spacingSmall),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: DashboardDurations.microAnimation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isHovered 
                          ? DashboardSizes.fontLarge + 2
                          : DashboardSizes.fontLarge,
                      color: isHovered 
                          ? DashboardColors.primaryDark
                          : Colors.black87,
                    ),
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DashboardSizes.spacingMedium),
            _buildInfoRow(Icons.person, widget.menteeName, isHovered),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.access_time, widget.time, isHovered),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on, widget.location, isHovered),
            const SizedBox(height: DashboardSizes.spacingMedium),
            if (widget.status == 'pending' && widget.createdBy != widget.currentUserId && widget.onAccept != null && widget.onReject != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: DashboardDurations.microAnimation,
                    transform: Matrix4.identity()
                      ..scale(isHovered ? 1.05 : 1.0),
                    child: OutlinedButton(
                      onPressed: () => widget.onReject!(widget.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DashboardColors.statusRed,
                        side: BorderSide(
                          color: isHovered 
                              ? DashboardColors.statusRed
                              : DashboardColors.statusRed.withOpacity(0.6),
                          width: isHovered ? 2 : 1,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isHovered ? 20 : 16,
                          vertical: isHovered ? 10 : 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingSmall),
                  AnimatedContainer(
                    duration: DashboardDurations.microAnimation,
                    transform: Matrix4.identity()
                      ..scale(isHovered ? 1.05 : 1.0),
                    child: ElevatedButton(
                      onPressed: () => widget.onAccept!(widget.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHovered 
                            ? DashboardColors.statusGreen
                            : DashboardColors.statusGreen.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isHovered ? 20 : 16,
                          vertical: isHovered ? 10 : 8,
                        ),
                        elevation: isHovered ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else if (widget.status == 'rejected' && widget.onClear != null)
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedContainer(
                  duration: DashboardDurations.microAnimation,
                  transform: Matrix4.identity()
                    ..scale(isHovered ? 1.05 : 1.0),
                  child: OutlinedButton(
                    onPressed: () => widget.onClear!(widget.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DashboardColors.statusRed,
                      side: BorderSide(
                        color: isHovered 
                            ? DashboardColors.statusRed
                            : DashboardColors.statusRed.withOpacity(0.6),
                        width: isHovered ? 2 : 1,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isHovered ? 20 : 16,
                        vertical: isHovered ? 10 : 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              )
            else if (widget.status == 'cancelled')
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.cancellationReason != null && widget.cancellationReason!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DashboardColors.statusRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                        border: Border.all(
                          color: DashboardColors.statusRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancelled by ${widget.cancelledBy == widget.currentUserId ? "you" : "other party"}',
                            style: TextStyle(
                              color: DashboardColors.statusRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${widget.cancellationReason}',
                            style: TextStyle(
                              color: DashboardColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DashboardColors.statusRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                        border: Border.all(
                          color: DashboardColors.statusRed.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Meeting Cancelled',
                        style: TextStyle(
                          color: DashboardColors.statusRed,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (widget.onClear != null)
                    AnimatedContainer(
                      duration: DashboardDurations.microAnimation,
                      transform: Matrix4.identity()
                        ..scale(isHovered ? 1.05 : 1.0),
                      child: OutlinedButton(
                        onPressed: () => widget.onClear!(widget.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DashboardColors.statusRed,
                          side: BorderSide(
                            color: isHovered 
                                ? DashboardColors.statusRed
                                : DashboardColors.statusRed.withOpacity(0.6),
                            width: isHovered ? 2 : 1,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isHovered ? 20 : 16,
                            vertical: isHovered ? 10 : 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                ],
              )
            else if (widget.status == 'pending' && widget.createdBy == widget.currentUserId)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: DashboardColors.statusOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                    border: Border.all(
                      color: DashboardColors.statusOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: DashboardColors.statusOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for response',
                        style: TextStyle(
                          color: DashboardColors.statusOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if ((widget.status == 'accepted' || widget.status == 'confirmed') && (widget.onCancel != null || widget.onReschedule != null))
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onCancel != null)
                    AnimatedContainer(
                      duration: DashboardDurations.microAnimation,
                      transform: Matrix4.identity()
                        ..scale(isHovered ? 1.05 : 1.0),
                      child: OutlinedButton(
                        onPressed: () => widget.onCancel!(widget.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DashboardColors.statusRed,
                          side: BorderSide(
                            color: isHovered 
                                ? DashboardColors.statusRed
                                : DashboardColors.statusRed.withOpacity(0.6),
                            width: isHovered ? 2 : 1,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isHovered ? 20 : 16,
                            vertical: isHovered ? 10 : 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  if (widget.onCancel != null && widget.onReschedule != null)
                    const SizedBox(width: DashboardSizes.spacingSmall),
                  if (widget.onReschedule != null)
                    AnimatedContainer(
                      duration: DashboardDurations.microAnimation,
                      transform: Matrix4.identity()
                        ..scale(isHovered ? 1.05 : 1.0),
                      child: ElevatedButton(
                        onPressed: () => widget.onReschedule!(widget.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHovered 
                              ? DashboardColors.accentBlue
                              : DashboardColors.accentBlue.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isHovered ? 20 : 16,
                            vertical: isHovered ? 10 : 8,
                          ),
                          elevation: isHovered ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                          ),
                        ),
                        child: const Text('Reschedule'),
                      ),
                    ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedContainer(
                  duration: DashboardDurations.microAnimation,
                  transform: Matrix4.identity()
                    ..scale(isHovered ? 1.05 : 1.0),
                  child: ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHovered 
                          ? widget.color
                          : DashboardColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isHovered ? 20 : 16,
                        vertical: isHovered ? 10 : 8,
                      ),
                      elevation: isHovered ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusSmall),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: DashboardDurations.microAnimation,
                          margin: EdgeInsets.only(right: isHovered ? 8 : 4),
                          child: Icon(
                            Icons.video_call,
                            size: isHovered ? 18 : 16,
                          ),
                        ),
                        const Text(DashboardStrings.checkIn),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isHovered) {
    return AnimatedContainer(
      duration: DashboardDurations.microAnimation,
      transform: Matrix4.identity()
        ..translate(isHovered ? 4.0 : 0.0, 0.0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: DashboardDurations.microAnimation,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isHovered 
                  ? widget.color.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: isHovered 
                  ? DashboardSizes.iconSmall
                  : DashboardSizes.iconSmall - 2,
              color: isHovered 
                  ? widget.color
                  : DashboardColors.textGrey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: DashboardDurations.microAnimation,
              style: TextStyle(
                fontSize: DashboardSizes.fontMedium,
                color: isHovered 
                    ? Colors.black87
                    : DashboardColors.textDarkGrey,
                fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
              ),
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}