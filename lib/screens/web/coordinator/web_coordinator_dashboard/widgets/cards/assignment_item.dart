import 'package:flutter/material.dart';

class AssignmentItem extends StatefulWidget {
  final String mentorName;
  final String menteeName;
  final String assignmentDate;
  final bool isCoordinatorAssigned;

  const AssignmentItem({
    super.key,
    required this.mentorName,
    required this.menteeName,
    required this.assignmentDate,
    required this.isCoordinatorAssigned,
  });

  @override
  State<AssignmentItem> createState() => _AssignmentItemState();
}

class _AssignmentItemState extends State<AssignmentItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? Colors.grey.shade200 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: widget.isCoordinatorAssigned ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.mentorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.menteeName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.assignmentDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isCoordinatorAssigned
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isCoordinatorAssigned
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isCoordinatorAssigned ? Icons.check_circle : Icons.person,
                    size: 14,
                    color: widget.isCoordinatorAssigned ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.isCoordinatorAssigned ? 'Coordinator' : 'Self-selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isCoordinatorAssigned ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: _isHovered ? Colors.grey[700] : Colors.grey[400],
              ),
              onPressed: () {
                // TODO: Show assignment options
              },
            ),
          ],
        ),
      ),
    );
  }
}