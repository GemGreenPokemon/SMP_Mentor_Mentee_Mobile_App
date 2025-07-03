enum UserTypeFilter {
  all,
  mentee,
  mentor,
  coordinator,
}

enum UserStatusFilter {
  all,
  acknowledged,
  notAcknowledged,
  pendingVerification,
}

class UserFilter {
  final UserTypeFilter typeFilter;
  final UserStatusFilter statusFilter;
  final String searchQuery;
  final bool showOnlyWithMentors;
  final bool showOnlyWithoutMentors;

  UserFilter({
    this.typeFilter = UserTypeFilter.all,
    this.statusFilter = UserStatusFilter.all,
    this.searchQuery = '',
    this.showOnlyWithMentors = false,
    this.showOnlyWithoutMentors = false,
  });

  UserFilter copyWith({
    UserTypeFilter? typeFilter,
    UserStatusFilter? statusFilter,
    String? searchQuery,
    bool? showOnlyWithMentors,
    bool? showOnlyWithoutMentors,
  }) {
    return UserFilter(
      typeFilter: typeFilter ?? this.typeFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      showOnlyWithMentors: showOnlyWithMentors ?? this.showOnlyWithMentors,
      showOnlyWithoutMentors: showOnlyWithoutMentors ?? this.showOnlyWithoutMentors,
    );
  }

  bool get hasActiveFilters =>
      typeFilter != UserTypeFilter.all ||
      statusFilter != UserStatusFilter.all ||
      searchQuery.isNotEmpty ||
      showOnlyWithMentors ||
      showOnlyWithoutMentors;

  void reset() {
    // This would be used with a state management solution
  }
}