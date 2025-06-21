enum TimePeriod {
  currentSemester('Current Semester'),
  lastSemester('Last Semester'),
  last30Days('Last 30 Days'),
  last90Days('Last 90 Days'),
  allTime('All Time');

  final String displayName;
  const TimePeriod(this.displayName);
  
  DateTime getStartDate() {
    final now = DateTime.now();
    switch (this) {
      case TimePeriod.currentSemester:
        // Assuming semester starts in January or August
        if (now.month >= 8) {
          return DateTime(now.year, 8, 1);
        } else {
          return DateTime(now.year, 1, 1);
        }
      case TimePeriod.lastSemester:
        if (now.month >= 8) {
          return DateTime(now.year, 1, 1);
        } else {
          return DateTime(now.year - 1, 8, 1);
        }
      case TimePeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case TimePeriod.last90Days:
        return now.subtract(const Duration(days: 90));
      case TimePeriod.allTime:
        return DateTime(2000); // Arbitrary old date
    }
  }
}