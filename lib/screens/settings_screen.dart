import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // optional retains kDebugMode if needed
import '../utils/developer_session.dart';
import 'firestore_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isMentor;
  const SettingsScreen({super.key, this.isMentor = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  String _downloadLocation = 'Default Downloads Folder';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'Notifications',
            [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive app notifications'),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive email updates'),
                value: _emailNotifications,
                onChanged: (bool value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            'Appearance',
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle dark/light theme'),
                value: _darkMode,
                onChanged: (bool value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            'Files & Storage',
            [
              ListTile(
                title: const Text('Download Location'),
                subtitle: Text(_downloadLocation),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDownloadLocationDialog(),
              ),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up space by clearing cached data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            'Account',
            [
              ListTile(
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement change password
                },
              ),
              ListTile(
                title: const Text('Privacy Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement privacy settings
                },
              ),
              ListTile(
                title: const Text('Connected Accounts'),
                subtitle: const Text('Google Drive, OneDrive'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement connected accounts
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            'Help & Support',
            [
              ListTile(
                title: const Text('FAQ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show FAQ
                },
              ),
              ListTile(
                title: const Text('Contact Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show contact support options
                },
              ),
              ListTile(
                title: const Text('About'),
                subtitle: const Text('Version 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show about dialog
                },
              ),
            ],
          ),
          if (DeveloperSession.isActive) ...[
            const Divider(),
            _buildSection(
              'Developer Tools',
              [
                ListTile(
                  title: const Text('Local DB Manager'),
                  trailing: const Icon(Icons.storage),
                  onTap: () {
                    // TODO: Implement local database UI
                  },
                ),
                ListTile(
                  title: const Text('Firestore Manager'),
                  trailing: const Icon(Icons.cloud),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FirestoreManagerScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Messaging Loopback Test'),
                  trailing: const Icon(Icons.message),
                  onTap: () {
                    // TODO: Implement messaging loopback test UI
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: _language == 'English' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: _language == 'Spanish' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _language = 'Spanish';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: _language == 'French' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _language = 'French';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Default Downloads Folder'),
              trailing: _downloadLocation == 'Default Downloads Folder'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Default Downloads Folder';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Documents Folder'),
              trailing: _downloadLocation == 'Documents Folder'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Documents Folder';
                });
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
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
}