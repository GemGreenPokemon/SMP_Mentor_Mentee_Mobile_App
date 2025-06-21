import 'resource_category.dart';

class ResourceFilter {
  final String searchQuery;
  final ResourceCategory category;
  final bool showMentorOnly;
  final bool showCoordinatorOnly;

  const ResourceFilter({
    this.searchQuery = '',
    this.category = ResourceCategory.all,
    this.showMentorOnly = false,
    this.showCoordinatorOnly = false,
  });

  ResourceFilter copyWith({
    String? searchQuery,
    ResourceCategory? category,
    bool? showMentorOnly,
    bool? showCoordinatorOnly,
  }) {
    return ResourceFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      showMentorOnly: showMentorOnly ?? this.showMentorOnly,
      showCoordinatorOnly: showCoordinatorOnly ?? this.showCoordinatorOnly,
    );
  }
}