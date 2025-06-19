class AnnouncementFilter {
  final String searchQuery;
  final List<String> selectedFilters;
  final String sortBy;

  AnnouncementFilter({
    this.searchQuery = '',
    this.selectedFilters = const ['All'],
    this.sortBy = 'newest',
  });

  AnnouncementFilter copyWith({
    String? searchQuery,
    List<String>? selectedFilters,
    String? sortBy,
  }) {
    return AnnouncementFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}