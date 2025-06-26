import 'test_status.dart';

class TestResult {
  final int passed;
  final int failed;
  final int skipped;
  final int duration;
  final String logs;
  final TestStatus status;
  final String? errorMessage;
  final DateTime timestamp;

  TestResult({
    required this.passed,
    required this.failed,
    this.skipped = 0,
    required this.duration,
    required this.logs,
    required this.status,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TestResult.running() {
    return TestResult(
      passed: 0,
      failed: 0,
      duration: 0,
      logs: 'Running tests...',
      status: TestStatus.running,
    );
  }

  factory TestResult.error(String errorMessage) {
    return TestResult(
      passed: 0,
      failed: 0,
      duration: 0,
      logs: '',
      status: TestStatus.error,
      errorMessage: errorMessage,
    );
  }

  bool get isSuccess => failed == 0 && status == TestStatus.completed;
  
  String get summary => '$passed passed, $failed failed${skipped > 0 ? ', $skipped skipped' : ''}';
  
  double get passRate => passed + failed > 0 ? (passed / (passed + failed)) * 100 : 0;
}