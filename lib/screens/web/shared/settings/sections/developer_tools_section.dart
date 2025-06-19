import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';
import '../../../../mobile/shared/local_db_manager_screen.dart';
import '../../../../mobile/shared/firestore_manager_screen.dart';
import '../dialogs/sync_claims_dialog.dart';

class DeveloperToolsSection extends StatelessWidget {
  const DeveloperToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Developer Tools',
      icon: Icons.developer_mode,
      children: [
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
}