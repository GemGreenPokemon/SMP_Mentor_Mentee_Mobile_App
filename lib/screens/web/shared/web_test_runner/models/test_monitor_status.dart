import 'test_result.dart';

class TestMonitorStatus {
  final bool allPassing;
  final DateTime? lastRun;
  final double passRate;
  final int totalTests;
  final int passingTests;
  final int failingTests;
  final Map<String, TestResult> suiteResults;

  TestMonitorStatus({
    required this.allPassing,
    this.lastRun,
    required this.passRate,
    required this.totalTests,
    required this.passingTests,
    required this.failingTests,
    required this.suiteResults,
  });

  factory TestMonitorStatus.empty() {
    return TestMonitorStatus(
      allPassing: true,
      passRate: 100,
      totalTests: 0,
      passingTests: 0,
      failingTests: 0,
      suiteResults: {},
    );
  }
}