import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class ActionItemTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ActionItemTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<ActionItemTile> createState() => _ActionItemTileState();
}

class _ActionItemTileState extends State<ActionItemTile> {
  bool _isHovered = false;

  Color _getIconColor() {
    switch (widget.icon) {
      case Icons.person_add:
        return Colors.purple;
      case Icons.assessment:
        return Colors.orange;
      case Icons.update:
        return Colors.blue;
      default:
        return CoordinatorDashboardColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _isHovered ? iconColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? iconColor.withOpacity(0.2) : Colors.transparent,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.2),
                  iconColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: iconColor,
              size: 22,
            ),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isHovered ? iconColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 16,
              color: _isHovered ? iconColor : Colors.grey,
            ),
          ),
          onTap: () {
            // TODO: Handle action item tap
          },
        ),
      ),
    );
  }
}