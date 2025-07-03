import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import '../../utils/user_management_constants.dart';
import '../../utils/user_management_helpers.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    Key? key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: UserManagementConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UserManagementConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(UserManagementConstants.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: UserManagementHelpers.getUserTypeColor(user.userType).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(UserManagementConstants.borderRadius),
                  topRight: Radius.circular(UserManagementConstants.borderRadius),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: UserManagementHelpers.getUserTypeColor(user.userType).withOpacity(0.2),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: UserManagementHelpers.getUserTypeColor(user.userType),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // User Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Email
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // User Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: UserManagementHelpers.getUserTypeColor(user.userType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            UserManagementHelpers.getUserTypeIcon(user.userType),
                            size: 14,
                            color: UserManagementHelpers.getUserTypeColor(user.userType),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.userType.toUpperCase(),
                            style: TextStyle(
                              color: UserManagementHelpers.getUserTypeColor(user.userType),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Footer with additional info
                    Column(
                      children: [
                        if (user.studentId != null) ...[
                          Row(
                            children: [
                              Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                user.studentId!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (user.department != null) ...[
                          Row(
                            children: [
                              Icon(Icons.business, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user.department!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: UserManagementHelpers.getStatusColor(user).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                (user.acknowledgmentSigned != 'not_applicable' && 
                                 user.acknowledgmentSigned != 'No') ? Icons.check_circle : Icons.pending,
                                size: 16,
                                color: UserManagementHelpers.getStatusColor(user),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (user.acknowledgmentSigned != 'not_applicable' && 
                                 user.acknowledgmentSigned != 'No') ? 'Acknowledged' : 'Pending',
                                style: TextStyle(
                                  color: UserManagementHelpers.getStatusColor(user),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}