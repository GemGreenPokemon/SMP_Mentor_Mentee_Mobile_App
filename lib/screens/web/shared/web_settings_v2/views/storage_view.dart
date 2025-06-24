import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_settings/sections/file_storage_settings_section.dart';
import '../controllers/settings_controller.dart';
import '../utils/settings_constants.dart';

class StorageView extends StatefulWidget {
  const StorageView({super.key});

  @override
  State<StorageView> createState() => _StorageViewState();
}

class _StorageViewState extends State<StorageView> {
  late String _downloadLocation;

  @override
  void initState() {
    super.initState();
    final controller = context.read<SettingsController>();
    _downloadLocation = controller.getSetting('downloadLocation') ?? 'Default Downloads Folder';
  }

  void _showDownloadLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Download Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Default Downloads Folder'),
              trailing: _downloadLocation == 'Default Downloads Folder'
                  ? Icon(Icons.check, color: SettingsDashboardConstants.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Default Downloads Folder';
                });
                context.read<SettingsController>().updateSetting('downloadLocation', _downloadLocation);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Documents Folder'),
              trailing: _downloadLocation == 'Documents Folder'
                  ? Icon(Icons.check, color: SettingsDashboardConstants.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Documents Folder';
                });
                context.read<SettingsController>().updateSetting('downloadLocation', _downloadLocation);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Custom Location...'),
              trailing: const Icon(Icons.folder),
              onTap: () {
                // TODO: Implement custom location picker
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will free up space by removing cached data. Your saved files and settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: SettingsDashboardConstants.primaryButtonStyle,
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < SettingsDashboardConstants.mobileBreakpoint;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? SettingsDashboardConstants.compactPadding
            : SettingsDashboardConstants.defaultPadding,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FileStorageSettingsSection(
            downloadLocation: _downloadLocation,
            onDownloadLocationPressed: _showDownloadLocationDialog,
            onClearCachePressed: _showClearCacheDialog,
          ),
        ),
      ),
    );
  }
}