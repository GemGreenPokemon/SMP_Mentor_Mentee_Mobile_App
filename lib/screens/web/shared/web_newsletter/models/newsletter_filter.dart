enum TimePeriod {
  allTime('All Time'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  lastThreeMonths('Last 3 Months'),
  year2024('2024'),
  year2023('2023');

  final String displayName;
  const TimePeriod(this.displayName);
}

class NewsletterFilter {
  final String searchQuery;
  final TimePeriod timePeriod;

  const NewsletterFilter({
    this.searchQuery = '',
    this.timePeriod = TimePeriod.allTime,
  });

  NewsletterFilter copyWith({
    String? searchQuery,
    TimePeriod? timePeriod,
  }) {
    return NewsletterFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      timePeriod: timePeriod ?? this.timePeriod,
    );
  }

  bool matchesNewsletter(String title, String description, DateTime date) {
    // Check search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final matchesTitle = title.toLowerCase().contains(query);
      final matchesDescription = description.toLowerCase().contains(query);
      if (!matchesTitle && !matchesDescription) {
        return false;
      }
    }

    // Check time period
    final now = DateTime.now();
    switch (timePeriod) {
      case TimePeriod.allTime:
        return true;
      case TimePeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case TimePeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        return date.year == lastMonth.year && date.month == lastMonth.month;
      case TimePeriod.lastThreeMonths:
        final threeMonthsAgo = DateTime(now.year, now.month - 3);
        return date.isAfter(threeMonthsAgo);
      case TimePeriod.year2024:
        return date.year == 2024;
      case TimePeriod.year2023:
        return date.year == 2023;
    }
  }
}