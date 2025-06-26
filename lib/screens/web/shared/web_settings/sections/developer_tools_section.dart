import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';
import '../../../../mobile/shared/local_db_manager_screen.dart';
import '../../../../mobile/shared/firestore_manager_screen.dart';
import '../widgets/dialogs/sync_claims_dialog.dart';
import '../../web_test_runner/widgets/dialogs/test_runner_dialog.dart';
import '../../web_test_runner/services/test_monitor_service.dart';
import '../../web_test_runner/models/test_monitor_status.dart';

class DeveloperToolsSection extends StatelessWidget {
  const DeveloperToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Developer Tools',
      icon: Icons.developer_mode,
      children: [
        _buildTestStatusCard(context),
        const SizedBox(height: 8),
        _buildListTile(
          'Local DB Manager',
          null,
          Icons.storage,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LocalDbManagerScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          'Firestore Manager',
          null,
          Icons.cloud,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FirestoreManagerScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          'Messaging Loopback Test',
          null,
          Icons.message,
          () {
            // TODO: Implement messaging loopback test UI
          },
        ),
        _buildListTile(
          'Sync Auth Claims',
          'Fix permission issues by syncing custom claims',
          Icons.sync,
          () {
            showDialog(
              context: context,
              builder: (context) => const SyncClaimsDialog(),
            );
          },
        ),
        _buildListTile(
          'Unit Test Runner',
          'Run mentee registration tests',
          Icons.bug_report,
          () {
            showDialog(
              context: context,
              builder: (context) => const TestRunnerDialog(),
              barrierDismissible: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildListTile(String title, String? subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F2D52)),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTestStatusCard(BuildContext context) {
    return StreamBuilder<TestMonitorStatus>(
      stream: testMonitor.statusStream,
      initialData: testMonitor.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? TestMonitorStatus.empty();
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const TestRunnerDialog(),
                barrierDismissible: false,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Suite Health',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          testMonitor.getStatusSummary(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status.totalTests > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status.passRate == 100 
                          ? Colors.green[100] 
                          : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${status.passRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: status.passRate == 100 
                            ? Colors.green[700] 
                            : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}