class UserImportResult {
  final int successCount;
  final int failureCount;
  final List<String> successfulEmails;
  final Map<String, String> failedEmails; // email -> error message
  final int mentorshipAssignmentsCreated;
  final DateTime importedAt;

  UserImportResult({
    required this.successCount,
    required this.failureCount,
    required this.successfulEmails,
    required this.failedEmails,
    required this.mentorshipAssignmentsCreated,
    required this.importedAt,
  });

  int get totalProcessed => successCount + failureCount;
  bool get hasFailures => failureCount > 0;
  bool get isFullSuccess => failureCount == 0 && successCount > 0;

  String get summaryMessage {
    if (isFullSuccess) {
      return 'Successfully imported $successCount users and created $mentorshipAssignmentsCreated mentor assignments.';
    } else if (successCount == 0) {
      return 'Failed to import any users. Please check the errors and try again.';
    } else {
      return 'Imported $successCount users successfully, but $failureCount failed. Created $mentorshipAssignmentsCreated mentor assignments.';
    }
  }
}