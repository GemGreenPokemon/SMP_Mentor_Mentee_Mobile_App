class ChecklistFilter {
  final String? menteeId;
  final String? menteeName;
  final bool showCompleted;
  final bool showInProgress;
  final bool showNotStarted;
  final bool showCustomOnly;
  final bool showDefaultOnly;

  const ChecklistFilter({
    this.menteeId,
    this.menteeName,
    this.showCompleted = true,
    this.showInProgress = true,
    this.showNotStarted = true,
    this.showCustomOnly = false,
    this.showDefaultOnly = false,
  });

  static const ChecklistFilter allMentees = ChecklistFilter(
    menteeName: 'All Mentees',
  );

  bool get hasActiveFilters =>
      menteeId != null ||
      !showCompleted ||
      !showInProgress ||
      !showNotStarted ||
      showCustomOnly ||
      showDefaultOnly;

  ChecklistFilter copyWith({
    String? menteeId,
    String? menteeName,
    bool? showCompleted,
    bool? showInProgress,
    bool? showNotStarted,
    bool? showCustomOnly,
    bool? showDefaultOnly,
  }) {
    return ChecklistFilter(
      menteeId: menteeId ?? this.menteeId,
      menteeName: menteeName ?? this.menteeName,
      showCompleted: showCompleted ?? this.showCompleted,
      showInProgress: showInProgress ?? this.showInProgress,
      showNotStarted: showNotStarted ?? this.showNotStarted,
      showCustomOnly: showCustomOnly ?? this.showCustomOnly,
      showDefaultOnly: showDefaultOnly ?? this.showDefaultOnly,
    );
  }

  ChecklistFilter clearMenteeFilter() {
    return copyWith(
      menteeId: null,
      menteeName: 'All Mentees',
    );
  }
}