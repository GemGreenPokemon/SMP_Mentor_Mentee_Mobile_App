import 'package:flutter/material.dart';
import '../../../services/announcement_service.dart';
import 'announcement_card.dart';

class AnnouncementGrid extends StatelessWidget {
  final List<Map<String, dynamic>> announcements;
  final AnnouncementService announcementService;
  final Function(Map<String, dynamic>) onCardTap;
  final Function(Map<String, dynamic>) onEditTap;
  final Function(Map<String, dynamic>) onDeleteTap;

  const AnnouncementGrid({
    super.key,
    required this.announcements,
    required this.announcementService,
    required this.onCardTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return AnnouncementCard(
          announcement: announcement,
          announcementService: announcementService,
          onTap: () => onCardTap(announcement),
          onEdit: () => onEditTap(announcement),
          onDelete: () => onDeleteTap(announcement),
        );
      },
    );
  }
}