class TestRunConfiguration {
  final bool runInParallel;
  final bool showDetailedLogs;
  final bool stopOnFirstFailure;
  final int timeout;

  TestRunConfiguration({
    this.runInParallel = false,
    this.showDetailedLogs = true,
    this.stopOnFirstFailure = false,
    this.timeout = 60000, // 60 seconds default
  });
}