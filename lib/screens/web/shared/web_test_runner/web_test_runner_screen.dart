import 'package:flutter/material.dart';
import 'widgets/dialogs/test_runner_dialog.dart';
import 'models/test_monitor_status.dart';
import 'services/test_monitor_service.dart';
import 'utils/test_runner_constants.dart';

class WebTestRunnerScreen extends StatefulWidget {
  const WebTestRunnerScreen({Key? key}) : super(key: key);

  @override
  State<WebTestRunnerScreen> createState() => _WebTestRunnerScreenState();
}

class _WebTestRunnerScreenState extends State<WebTestRunnerScreen> {
  @override
  void initState() {
    super.initState();
    testMonitor.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TestRunnerColors.background,
      appBar: AppBar(
        title: const Text('Test Runner'),
        backgroundColor: TestRunnerColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              testMonitor.clearResults();
            },
            tooltip: 'Clear all test results',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Add test configuration dialog
            },
            tooltip: 'Test settings',
          ),
        ],
      ),
      body: StreamBuilder<TestMonitorStatus>(
        stream: testMonitor.statusStream,
        initialData: testMonitor.currentStatus,
        builder: (context, snapshot) {
          final status = snapshot.data ?? TestMonitorStatus.empty();
          
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(status),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildTestSuitesList(status),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(TestMonitorStatus status) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: status.allPassing 
                  ? Colors.green[100] 
                  : status.totalTests == 0 
                    ? Colors.grey[100]
                    : Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                status.allPassing 
                  ? Icons.check_circle 
                  : status.totalTests == 0
                    ? Icons.pending
                    : Icons.error,
                color: status.allPassing 
                  ? Colors.green[700] 
                  : status.totalTests == 0
                    ? Colors.grey[700]
                    : Colors.red[700],
                size: 48,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Suite Health',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    testMonitor.getStatusSummary(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (status.totalTests > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatChip(
                          '${status.passingTests}',
                          'Passing',
                          Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          '${status.failingTests}',
                          'Failing',
                          Colors.red,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          '${status.passRate.toStringAsFixed(0)}%',
                          'Pass Rate',
                          status.passRate == 100 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run All Tests'),
                  onPressed: _openTestRunner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TestRunnerColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Tests'),
                  onPressed: _openTestRunner,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                  onPressed: () {
                    // TODO: Implement test history
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSuitesList(TestMonitorStatus status) {
    if (status.suiteResults.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tests have been run yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "Run All Tests" to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Test Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: status.suiteResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = status.suiteResults.entries.elementAt(index);
                final suiteName = entry.key;
                final result = entry.value;
                
                return ListTile(
                  leading: Icon(
                    result.isSuccess ? Icons.check_circle : Icons.error,
                    color: result.isSuccess ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    suiteName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(result.summary),
                  trailing: Text(
                    '${result.duration}ms',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    // TODO: Show detailed results
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openTestRunner() {
    showDialog(
      context: context,
      builder: (context) => const TestRunnerDialog(),
      barrierDismissible: false,
    );
  }
}