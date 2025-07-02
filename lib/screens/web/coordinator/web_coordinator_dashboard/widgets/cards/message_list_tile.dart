import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class MessageListTile extends StatefulWidget {
  final String name;
  final String description;
  final String role;

  const MessageListTile({
    super.key,
    required this.name,
    required this.description,
    required this.role,
  });

  @override
  State<MessageListTile> createState() => _MessageListTileState();
}

class _MessageListTileState extends State<MessageListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? Colors.grey.shade200 : Colors.transparent,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CoordinatorDashboardColors.primaryDark,
                  CoordinatorDashboardColors.primaryDark.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: CoordinatorDashboardColors.primaryDark.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                widget.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Text(
            widget.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            widget.description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..translate(_isHovered ? 5.0 : 0.0, 0.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _isHovered ? CoordinatorDashboardColors.primaryDark : Colors.grey,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/chat');
          },
        ),
      ),
    );
  }
}