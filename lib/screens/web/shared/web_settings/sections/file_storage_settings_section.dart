import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';
import '../utils/settings_constants.dart';

class FileStorageSettingsSection extends StatelessWidget {
  final String downloadLocation;
  final VoidCallback onDownloadLocationPressed;
  final VoidCallback onClearCachePressed;

  const FileStorageSettingsSection({
    super.key,
    required this.downloadLocation,
    required this.onDownloadLocationPressed,
    required this.onClearCachePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Files & Storage',
      icon: Icons.folder,
      children: [
        _buildListTile(
          'Download Location',
          downloadLocation,
          Icons.download,
          onDownloadLocationPressed,
        ),
        _buildListTile(
          'Clear Cache',
          'Free up space by clearing cached data',
          Icons.cleaning_services,
          onClearCachePressed,
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
        leading: Icon(icon, color: SettingsConstants.primaryColor),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}