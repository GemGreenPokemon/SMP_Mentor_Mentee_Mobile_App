import 'package:flutter/material.dart';
import '../models/user_filter.dart';
import '../utils/user_management_constants.dart';

class UserFilters extends StatelessWidget {
  final UserFilter filter;
  final Function(UserFilter) onFilterChanged;
  final int totalUsers;
  final int filteredUsers;

  const UserFilters({
    Key? key,
    required this.filter,
    required this.onFilterChanged,
    required this.totalUsers,
    required this.filteredUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Type Filter
        _buildFilterSection(
          'User Type',
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypeFilterChip(
                  'All',
                  UserTypeFilter.all,
                  Icons.groups,
                ),
                _buildTypeFilterChip(
                  'Mentees',
                  UserTypeFilter.mentee,
                  UserManagementConstants.menteeIcon,
                ),
                _buildTypeFilterChip(
                  'Mentors',
                  UserTypeFilter.mentor,
                  UserManagementConstants.mentorIcon,
                ),
                _buildTypeFilterChip(
                  'Coordinators',
                  UserTypeFilter.coordinator,
                  UserManagementConstants.coordinatorIcon,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Status Filter
            Expanded(
              child: _buildFilterSection(
                'Status',
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusFilterChip(
                        'All',
                        UserStatusFilter.all,
                        Icons.all_inclusive,
                      ),
                      _buildStatusFilterChip(
                        'Acknowledged',
                        UserStatusFilter.acknowledged,
                        Icons.check_circle,
                      ),
                      _buildStatusFilterChip(
                        'Pending',
                        UserStatusFilter.notAcknowledged,
                        Icons.pending,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            
            // Mentor Assignment Filter (for mentees)
            if (filter.typeFilter == UserTypeFilter.mentee ||
                filter.typeFilter == UserTypeFilter.all) ...[
              _buildMentorFilterChips(),
            ],
            
            const Spacer(),
            
            // Results Count and Clear Button
            Row(
              children: [
                if (filter.hasActiveFilters) ...[
                  TextButton.icon(
                    onPressed: () => onFilterChanged(UserFilter()),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 16,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$filteredUsers of $totalUsers users',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTypeFilterChip(
    String label,
    UserTypeFilter value,
    IconData icon,
  ) {
    final isSelected = filter.typeFilter == value;
    return GestureDetector(
      onTap: () {
        onFilterChanged(filter.copyWith(typeFilter: value));
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(
    String label,
    UserStatusFilter value,
    IconData icon,
  ) {
    final isSelected = filter.statusFilter == value;
    return GestureDetector(
      onTap: () {
        onFilterChanged(filter.copyWith(statusFilter: value));
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorFilterChips() {
    return Row(
      children: [
        _buildFilterSection(
          'Mentor Status',
          Row(
            children: [
              _buildMentorChip(
                'Has Mentor',
                filter.showOnlyWithMentors,
                Icons.check,
                const Color(0xFF3B82F6),
                () {
                  onFilterChanged(
                    filter.copyWith(
                      showOnlyWithMentors: !filter.showOnlyWithMentors,
                      showOnlyWithoutMentors: false,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildMentorChip(
                'No Mentor',
                filter.showOnlyWithoutMentors,
                Icons.close,
                const Color(0xFFF59E0B),
                () {
                  onFilterChanged(
                    filter.copyWith(
                      showOnlyWithoutMentors: !filter.showOnlyWithoutMentors,
                      showOnlyWithMentors: false,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMentorChip(
    String label,
    bool isSelected,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}