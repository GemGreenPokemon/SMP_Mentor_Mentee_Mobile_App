import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/test_result.dart';
import '../models/test_monitor_status.dart';

class TestMonitorService {
  static final TestMonitorService _instance = TestMonitorService._internal();
  factory TestMonitorService() => _instance;
  TestMonitorService._internal();

  final _statusStreamController = StreamController<TestMonitorStatus>.broadcast();
  Stream<TestMonitorStatus> get statusStream => _statusStreamController.stream;

  TestMonitorStatus _currentStatus = TestMonitorStatus.empty();
  final Map<String, TestResult> _testResults = {};
  Timer? _periodicCheckTimer;

  TestMonitorStatus get currentStatus => _currentStatus;

  void initialize() {
    // Start periodic check every 5 minutes
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkTestHealth(),
    );
  }

  void dispose() {
    _periodicCheckTimer?.cancel();
    _statusStreamController.close();
  }

  void updateTestResult(String suiteName, TestResult result) {
    _testResults[suiteName] = result;
    _updateStatus();
  }

  void updateMultipleResults(Map<String, TestResult> results) {
    _testResults.addAll(results);
    _updateStatus();
  }

  void clearResults() {
    _testResults.clear();
    _updateStatus();
  }

  void _updateStatus() {
    int totalPassed = 0;
    int totalFailed = 0;
    int totalTests = 0;
    DateTime? lastRun;

    for (final result in _testResults.values) {
      totalPassed += result.passed;
      totalFailed += result.failed;
      totalTests += result.passed + result.failed;
      
      if (lastRun == null || result.timestamp.isAfter(lastRun)) {
        lastRun = result.timestamp;
      }
    }

    final passRate = totalTests > 0 ? (totalPassed / totalTests) * 100.0 : 100.0;
    final allPassing = totalFailed == 0 && totalTests > 0;

    _currentStatus = TestMonitorStatus(
      allPassing: allPassing,
      lastRun: lastRun,
      passRate: passRate,
      totalTests: totalTests,
      passingTests: totalPassed,
      failingTests: totalFailed,
      suiteResults: Map.from(_testResults),
    );

    _statusStreamController.add(_currentStatus);
  }

  Future<void> _checkTestHealth() async {
    // This could be extended to automatically run critical tests
    // or fetch test results from CI/CD pipeline
    if (kDebugMode) {
      print('TestMonitorService: Performing periodic health check');
    }
  }

  // Helper methods for quick status checks
  bool get hasFailingTests => _currentStatus.failingTests > 0;
  
  bool get hasRecentTests {
    final lastRun = _currentStatus.lastRun;
    if (lastRun == null) return false;
    
    final hoursSinceLastRun = DateTime.now().difference(lastRun).inHours;
    return hoursSinceLastRun < 24; // Tests run within last 24 hours
  }

  List<String> get failingSuites {
    return _testResults.entries
        .where((entry) => entry.value.failed > 0)
        .map((entry) => entry.key)
        .toList();
  }

  String getStatusSummary() {
    if (_testResults.isEmpty) {
      return 'No tests have been run yet';
    }

    final lastRunStr = _currentStatus.lastRun != null
        ? _formatTimeAgo(_currentStatus.lastRun!)
        : 'Never';

    if (_currentStatus.allPassing) {
      return 'All tests passing • Last run: $lastRunStr';
    } else {
      return '${_currentStatus.failingTests} tests failing • Last run: $lastRunStr';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Global instance for easy access
final testMonitor = TestMonitorService();