import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/services/announcement_service.dart';
import '../utils/announcement_helpers.dart';

class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final AnnouncementService announcementService;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.announcementService,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priority = announcement['priority'] ?? 'none';
    final priorityColor = AnnouncementHelpers.getPriorityColor(priority);
    final priorityText = AnnouncementHelpers.getPriorityText(priority);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Priority accent strip
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  announcement['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2D52),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: priorityColor, width: 1),
                                ),
                                child: Text(
                                  priorityText,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Text(
                              announcement['content'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF0F2D52).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Color(0xFF0F2D52),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    announcement['time'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              FutureBuilder<bool>(
                                future: announcementService.canEditAnnouncement(announcement['created_by'] ?? ''),
                                builder: (context, snapshot) {
                                  if (snapshot.data == true) {
                                    return Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          color: Colors.grey[600],
                                          onPressed: onEdit,
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          color: Colors.red[400],
                                          onPressed: onDelete,
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}