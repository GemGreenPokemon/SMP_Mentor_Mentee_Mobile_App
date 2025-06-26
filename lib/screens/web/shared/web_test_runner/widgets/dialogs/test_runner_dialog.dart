import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/test_suite.dart';
import '../../models/test_result.dart';
import '../../models/test_status.dart';
import '../../models/test_configuration.dart';
import '../../services/test_monitor_service.dart';
import '../../../../../../services/cloud_function_service.dart';

class TestRunnerDialog extends StatefulWidget {
  const TestRunnerDialog({Key? key}) : super(key: key);

  @override
  _TestRunnerDialogState createState() => _TestRunnerDialogState();
}

class _TestRunnerDialogState extends State<TestRunnerDialog> {
  final List<TestSuite> testSuites = [
    // Example test that exists
    TestSuite(
      name: 'Example Tests',
      path: 'test/example_test.dart',
      icon: Icons.science,
      description: 'Simple example tests to verify test runner functionality',
    ),
    // Implemented tests
    TestSuite(
      name: 'Auth Service Tests (Simple)',
      path: 'test/features/mentee_registration/unit/services/auth_service_simple_test.dart',
      icon: Icons.security,
      description: 'Tests for authentication service validation logic',
    ),
    TestSuite(
      name: 'Acknowledgment Controller Tests',
      path: 'test/features/mentee_registration/unit/controllers/acknowledgment_controller_test.dart',
      icon: Icons.assignment_turned_in,
      description: 'Tests for mentee acknowledgment controller logic',
    ),
    // Future tests (not yet implemented)
    TestSuite(
      name: 'Auth Service Tests (Full)',
      path: 'test/features/mentee_registration/unit/services/auth_service_test.dart',
      icon: Icons.security,
      description: 'Full auth service tests with mocks (requires build_runner)',
    ),
    TestSuite(
      name: 'Cloud Function Tests',
      path: 'test/features/mentee_registration/unit/services/cloud_function_service_test.dart',
      icon: Icons.cloud_queue,
      description: 'Tests for cloud function integrations (NOT YET IMPLEMENTED)',
    ),
    TestSuite(
      name: 'Auth Wrapper Tests',
      path: 'test/features/mentee_registration/widget/auth_wrapper_test.dart',
      icon: Icons.wrap_text,
      description: 'Widget tests for auth routing logic (NOT YET IMPLEMENTED)',
    ),
    TestSuite(
      name: 'Acknowledgment Screen Tests',
      path: 'test/features/mentee_registration/widget/acknowledgment_screen_test.dart',
      icon: Icons.screen_share,
      description: 'Widget tests for acknowledgment UI (NOT YET IMPLEMENTED)',
    ),
    TestSuite(
      name: 'Integration Tests',
      path: 'test/features/mentee_registration/integration/mentee_registration_flow_test.dart',
      icon: Icons.integration_instructions,
      description: 'End-to-end registration flow tests with Firebase Emulator',
    ),
  ];

  Map<String, TestResult> results = {};
  bool isRunning = false;
  String? currentlyRunning;
  TestRunConfiguration config = TestRunConfiguration();

  Future<void> runTest(TestSuite suite) async {
    setState(() {
      isRunning = true;
      currentlyRunning = suite.name;
      results[suite.name] = TestResult.running();
    });

    try {
      final response = await CloudFunctionService.runUnitTest(
        suite.path,
        timeout: config.timeout,
        showDetailedLogs: config.showDetailedLogs,
      );

      final testResult = TestResult(
        passed: response['passed'] ?? 0,
        failed: response['failed'] ?? 0,
        skipped: response['skipped'] ?? 0,
        duration: response['duration'] ?? 0,
        logs: response['logs'] ?? '',
        status: TestStatus.completed,
      );
      
      setState(() {
        results[suite.name] = testResult;
      });
      
      // Update test monitor service
      testMonitor.updateTestResult(suite.name, testResult);
    } catch (e) {
      final errorResult = TestResult.error(e.toString());
      setState(() {
        results[suite.name] = errorResult;
      });
      
      // Update test monitor service with error
      testMonitor.updateTestResult(suite.name, errorResult);
    } finally {
      setState(() {
        isRunning = false;
        currentlyRunning = null;
      });
    }
  }

  Future<void> runAllTests() async {
    for (final suite in testSuites) {
      if (config.stopOnFirstFailure && 
          results.values.any((r) => r.status == TestStatus.completed && r.failed > 0)) {
        break;
      }
      await runTest(suite);
    }
  }

  Future<void> testRegistrationFlow() async {
    final registrationTests = testSuites.where((s) => 
      s.name.contains('Auth') || s.name.contains('Integration')
    ).toList();
    
    for (final suite in registrationTests) {
      await runTest(suite);
    }
  }

  Future<void> testAcknowledgmentFlow() async {
    final acknowledgmentTests = testSuites.where((s) => 
      s.name.contains('Acknowledgment')
    ).toList();
    
    for (final suite in acknowledgmentTests) {
      await runTest(suite);
    }
  }

  void copyLogsToClipboard(String logs) {
    Clipboard.setData(ClipboardData(text: logs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void copyAllLogsToClipboard() {
    final StringBuffer allLogs = StringBuffer();
    
    // Add header
    allLogs.writeln('===== Test Runner Logs =====');
    allLogs.writeln('Generated at: ${DateTime.now()}');
    allLogs.writeln('');
    
    // Add test configuration
    allLogs.writeln('Configuration:');
    allLogs.writeln('- Show Detailed Logs: ${config.showDetailedLogs}');
    allLogs.writeln('- Stop on First Failure: ${config.stopOnFirstFailure}');
    allLogs.writeln('- Timeout: ${config.timeout}ms');
    allLogs.writeln('');
    
    // Add results summary
    final totalTests = results.length;
    final passedSuites = results.values.where((r) => r.isSuccess).length;
    final failedSuites = results.values.where((r) => r.failed > 0).length;
    
    allLogs.writeln('Summary:');
    allLogs.writeln('- Total Test Suites: $totalTests');
    allLogs.writeln('- Passed Suites: $passedSuites');
    allLogs.writeln('- Failed Suites: $failedSuites');
    allLogs.writeln('');
    
    // Add individual test results
    results.forEach((suiteName, result) {
      allLogs.writeln('${'=' * 50}');
      allLogs.writeln('Test Suite: $suiteName');
      allLogs.writeln('${'=' * 50}');
      allLogs.writeln('Status: ${result.status}');
      allLogs.writeln('Summary: ${result.summary}');
      allLogs.writeln('Duration: ${result.duration}ms');
      
      if (result.errorMessage != null) {
        allLogs.writeln('Error: ${result.errorMessage}');
      }
      
      if (result.logs.isNotEmpty) {
        allLogs.writeln('');
        allLogs.writeln('Logs:');
        allLogs.writeln(result.logs);
      }
      
      allLogs.writeln('');
    });
    
    Clipboard.setData(ClipboardData(text: allLogs.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All test logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildConfiguration(),
            const SizedBox(height: 16),
            Expanded(child: _buildTestList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unit Test Runner',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Run mentee registration tests directly from the browser',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run All Tests'),
                  onPressed: isRunning ? null : runAllTests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Test Registration Flow'),
                  onPressed: isRunning ? null : testRegistrationFlow,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.assignment),
                  label: const Text('Test Acknowledgment'),
                  onPressed: isRunning ? null : testAcknowledgmentFlow,
                ),
                if (results.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copy All Logs'),
                    onPressed: copyAllLogsToClipboard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguration() {
    return ExpansionTile(
      title: const Text('Test Configuration'),
      leading: const Icon(Icons.settings),
      children: [
        SwitchListTile(
          title: const Text('Show Detailed Logs'),
          subtitle: const Text('Display verbose test output'),
          value: config.showDetailedLogs,
          onChanged: (value) {
            setState(() {
              config = TestRunConfiguration(
                showDetailedLogs: value,
                stopOnFirstFailure: config.stopOnFirstFailure,
                timeout: config.timeout,
              );
            });
          },
        ),
        SwitchListTile(
          title: const Text('Stop on First Failure'),
          subtitle: const Text('Halt test execution on first failed test'),
          value: config.stopOnFirstFailure,
          onChanged: (value) {
            setState(() {
              config = TestRunConfiguration(
                showDetailedLogs: config.showDetailedLogs,
                stopOnFirstFailure: value,
                timeout: config.timeout,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildTestList() {
    return ListView.builder(
      itemCount: testSuites.length,
      itemBuilder: (context, index) {
        final suite = testSuites[index];
        final result = results[suite.name];
        final isCurrentlyRunning = currentlyRunning == suite.name;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: Icon(suite.icon, size: 32),
                title: Text(
                  suite.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suite.description),
                    Text(
                      suite.path,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                trailing: _buildTestAction(suite, isCurrentlyRunning),
              ),
              if (result != null) _buildTestResults(suite.name, result),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestAction(TestSuite suite, bool isCurrentlyRunning) {
    if (isCurrentlyRunning) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final result = results[suite.name];
    if (result != null) {
      return Icon(
        result.isSuccess ? Icons.check_circle : Icons.error,
        color: result.isSuccess ? Colors.green : Colors.red,
        size: 32,
      );
    }

    return IconButton(
      icon: const Icon(Icons.play_arrow),
      onPressed: isRunning ? null : () => runTest(suite),
      tooltip: 'Run test',
    );
  }

  Widget _buildTestResults(String suiteName, TestResult result) {
    final color = result.status == TestStatus.error
        ? Colors.red[50]
        : result.isSuccess
            ? Colors.green[50]
            : Colors.orange[50];

    return Container(
      color: color,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              result.status == TestStatus.error
                  ? Icons.error_outline
                  : result.isSuccess
                      ? Icons.check_circle_outline
                      : Icons.warning_outlined,
              color: result.status == TestStatus.error
                  ? Colors.red
                  : result.isSuccess
                      ? Colors.green
                      : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(result.summary),
            const SizedBox(width: 16),
            Text(
              'Duration: ${result.duration}ms',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (result.passRate > 0) ...[
              const SizedBox(width: 16),
              Chip(
                label: Text('${result.passRate.toStringAsFixed(1)}% passing'),
                backgroundColor: result.passRate == 100 ? Colors.green : Colors.orange,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ],
        ),
        subtitle: result.errorMessage != null
            ? Text(
                'Error: ${result.errorMessage}',
                style: const TextStyle(color: Colors.red),
              )
            : null,
        children: [
          if (result.logs.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 300),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: SelectableText(
                      result.logs,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                      onPressed: () => copyLogsToClipboard(result.logs),
                      tooltip: 'Copy logs',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final totalTests = results.length;
    final passedSuites = results.values.where((r) => r.isSuccess).length;
    final failedSuites = results.values.where((r) => r.failed > 0).length;

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (totalTests > 0)
            Text(
              'Suites: $passedSuites passed, $failedSuites failed, $totalTests total',
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            Text(
              'No tests run yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          Row(
            children: [
              if (results.isNotEmpty) ...[
                TextButton.icon(
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Copy All Logs'),
                  onPressed: copyAllLogsToClipboard,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Results'),
                  onPressed: () {
                    setState(() {
                      results.clear();
                    });
                    // Clear test monitor results
                    testMonitor.clearResults();
                  },
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}