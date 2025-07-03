import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import '../models/user_filter.dart';
import '../utils/user_management_constants.dart';
import '../utils/user_management_helpers.dart';
import 'user_search_bar.dart';
import 'user_filters.dart';
import 'dialogs/add_user_dialog.dart';
import 'dialogs/edit_user_dialog.dart';
import 'dialogs/delete_user_dialog.dart';
import 'cards/user_card.dart';

class UserListSection extends StatefulWidget {
  final List<User> users;
  final UserFilter filter;
  final Function(UserFilter) onFilterChanged;
  final VoidCallback onRefresh;
  final bool isLoading;

  const UserListSection({
    Key? key,
    required this.users,
    required this.filter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<UserListSection> createState() => _UserListSectionState();
}

class _UserListSectionState extends State<UserListSection> {
  final CloudFunctionService _cloudFunctionService = CloudFunctionService();
  String _sortBy = 'name';
  bool _ascending = true;
  bool _isGridView = false;

  List<User> get filteredAndSortedUsers {
    final filtered = UserManagementHelpers.filterUsers(widget.users, widget.filter);
    return UserManagementHelpers.sortUsers(filtered, _sortBy, _ascending);
  }

  void _handleAddUser() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );

    if (result == true) {
      // User was added, refresh the list
      widget.onRefresh();
    }
  }

  void _handleEditUser(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result == true) {
      // User was edited, refresh the list
      widget.onRefresh();
    }
  }

  void _handleDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteUserDialog(user: user),
    );

    if (confirmed == true) {
      // User was deleted, refresh the list
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUsers = filteredAndSortedUsers;
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    // If loading, show loading state
    if (widget.isLoading) {
      return _buildLoadingState();
    }
    
    // If empty, show empty state
    if (displayUsers.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Statistics Cards
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            childAspectRatio: isDesktop ? 1.8 : 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildPremiumStatCard(
                'Total Users',
                widget.users.length.toString(),
                Icons.groups,
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
              ),
              _buildPremiumStatCard(
                'Mentors',
                widget.users.where((u) => u.userType == 'mentor').length.toString(),
                UserManagementConstants.mentorIcon,
                const Color(0xFF10B981),
                const Color(0xFF34D399),
              ),
              _buildPremiumStatCard(
                'Mentees',
                widget.users.where((u) => u.userType == 'mentee').length.toString(),
                UserManagementConstants.menteeIcon,
                const Color(0xFF3B82F6),
                const Color(0xFF60A5FA),
              ),
              _buildPremiumStatCard(
                'Acknowledged',
                widget.users.where((u) => 
                  u.acknowledgmentSigned != 'not_applicable' && 
                  u.acknowledgmentSigned != 'No'
                ).length.toString(),
                Icons.verified,
                const Color(0xFFF59E0B),
                const Color(0xFFFBBF24),
              ),
            ],
          ),
        ),

        // Header with search and filters
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: UserSearchBar(
                        searchQuery: widget.filter.searchQuery,
                        onSearchChanged: (query) {
                          widget.onFilterChanged(
                            widget.filter.copyWith(searchQuery: query),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add User Button with gradient
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _handleAddUser,
                        icon: const Icon(UserManagementConstants.addUserIcon),
                        label: const Text(UserManagementConstants.addUserButtonLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View Toggle with better styling
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        children: [
                          _buildViewToggleButton(
                            Icons.list,
                            !_isGridView,
                            () => setState(() => _isGridView = false),
                            'List view',
                          ),
                          _buildViewToggleButton(
                            Icons.grid_view,
                            _isGridView,
                            () => setState(() => _isGridView = true),
                            'Grid view',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Refresh Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: widget.isLoading 
                              ? Colors.grey 
                              : const Color(0xFF6366F1),
                        ),
                        onPressed: widget.isLoading ? null : widget.onRefresh,
                        tooltip: 'Refresh',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                UserFilters(
                  filter: widget.filter,
                  onFilterChanged: widget.onFilterChanged,
                  totalUsers: widget.users.length,
                  filteredUsers: displayUsers.length,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Users List/Grid
        if (_isGridView)
          _buildGridView(displayUsers)
        else
          _buildListView(displayUsers),
      ],
    );
  }

  Widget _buildPremiumStatCard(
    String label, 
    String value, 
    IconData icon,
    Color startColor,
    Color endColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton(
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.filter.hasActiveFilters
                ? 'No users match the current filters'
                : UserManagementConstants.noUsersMessage,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.filter.hasActiveFilters
                ? 'Try adjusting your filters to see more results'
                : 'Add users by importing from Excel or creating them manually',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (widget.filter.hasActiveFilters) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => widget.onFilterChanged(UserFilter()),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListView(List<User> users) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSortableHeader('Name', 'name'),
                ),
                Expanded(
                  flex: 3,
                  child: _buildSortableHeader('Email', 'email'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildSortableHeader('Type', 'type'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildSortableHeader('Status', 'status'),
                ),
                const SizedBox(width: 100), // Actions column
              ],
            ),
          ),
          // Table Body
          Container(
            // Set minimum height and let it grow with content
            constraints: BoxConstraints(
              minHeight: 600, // Minimum height to show more users
              maxHeight: double.infinity, // No maximum - let it grow
            ),
            child: ListView.separated(
              shrinkWrap: true, // Important: let ListView size itself
              physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFE5E7EB), // Use const color
              ),
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserRowItem(
                  key: ValueKey(user.id), // Add key for efficient updates
                  user: user,
                  index: index,
                  onEdit: () => _handleEditUser(user),
                  onDelete: () => _handleDeleteUser(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String label, String sortKey) {
    final isActive = _sortBy == sortKey;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortBy == sortKey) {
            _ascending = !_ascending;
          } else {
            _sortBy = sortKey;
            _ascending = true;
          }
        });
      },
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isActive
                ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 16,
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[400],
          ),
        ],
      ),
    );
  }


  Widget _buildGridView(List<User> users) {
    return GridView.builder(
      shrinkWrap: true, // Let GridView size itself
      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserCard(
          key: ValueKey(user.id), // Add key for efficient updates
          user: user,
          onEdit: () => _handleEditUser(user),
          onDelete: () => _handleDeleteUser(user),
        );
      },
    );
  }
}

// Optimized row item widget - separated to prevent unnecessary rebuilds
class _UserRowItem extends StatelessWidget {
  final User user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserRowItem({
    Key? key,
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = index.isEven ? Colors.transparent : Colors.grey[50]!.withOpacity(0.5);
    final userTypeColor = UserManagementHelpers.getUserTypeColor(user.userType);
    
    return Container(
      color: backgroundColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Name and Email
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              userTypeColor,
                              userTypeColor.withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty 
                                ? user.name.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and Student ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (user.studentId != null && user.studentId!.isNotEmpty)
                              Text(
                                'ID: ${user.studentId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Email
                Expanded(
                  flex: 3,
                  child: Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Type
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: userTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: userTypeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      user.userType.substring(0, 1).toUpperCase() + user.userType.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: userTypeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Status
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: user.acknowledgmentSigned.toLowerCase() == 'yes' 
                              ? Colors.green 
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.acknowledgmentSigned.toLowerCase() == 'yes' 
                            ? 'Acknowledged' 
                            : 'Pending',
                        style: TextStyle(
                          fontSize: 13,
                          color: user.acknowledgmentSigned.toLowerCase() == 'yes' 
                              ? Colors.green[700] 
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                        tooltip: 'Edit user',
                        color: Colors.grey[600],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: onDelete,
                        tooltip: 'Delete user',
                        color: Colors.red[400],
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
  }
}