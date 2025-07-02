import 'package:flutter/material.dart';

class MenteeListItem extends StatelessWidget {
  final String name;
  final String program;
  final String status;
  final Color statusColor;
  final VoidCallback? onManage;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;
  final VoidCallback? onReactivate;

  const MenteeListItem({
    super.key,
    required this.name,
    required this.program,
    required this.status,
    required this.statusColor,
    this.onManage,
    this.onApprove,
    this.onDeny,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    
    if (status == 'Available' && onManage != null) {
      trailing = IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: onManage,
      );
    } else if (status.startsWith('Requested')) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onApprove != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onApprove,
              tooltip: 'Approve',
            ),
          if (onDeny != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onDeny,
              tooltip: 'Deny',
            ),
        ],
      );
    } else if (status == 'Inactive' && onReactivate != null) {
      trailing = TextButton(
        onPressed: onReactivate,
        child: const Text('Reactivate'),
      );
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.2),
        radius: 18,
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.startsWith('Requested') ? 'Requested' : status,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: status.startsWith('Requested') 
        ? Text(
            '$program • ${status.substring(status.indexOf(':') + 1).trim()}',
            style: const TextStyle(fontSize: 12),
          )
        : Text(
            program,
            style: const TextStyle(fontSize: 12),
          ),
      trailing: trailing,
    );
  }
}