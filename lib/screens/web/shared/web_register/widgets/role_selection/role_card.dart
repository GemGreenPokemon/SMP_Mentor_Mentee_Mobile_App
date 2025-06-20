import 'package:flutter/material.dart';
import '../../models/role_selection.dart';
import '../../utils/registration_constants.dart';

class RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;
  
  const RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? RegistrationConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: RegistrationConstants.primaryColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: RegistrationConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  RoleConfig.getIcon(role),
                  color: isSelected ? Colors.white : RegistrationConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  RoleConfig.getTitle(role),
                  style: TextStyle(
                    color: isSelected ? Colors.white : RegistrationConstants.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              RoleConfig.getDescription(role),
              style: TextStyle(
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}