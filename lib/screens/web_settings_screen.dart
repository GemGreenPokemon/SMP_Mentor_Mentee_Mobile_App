import 'package:flutter/material.dart';
import '../utils/developer_session.dart';
import '../utils/responsive.dart';
import 'firestore_manager_screen.dart';
import 'local_db_manager_screen.dart';

class WebSettingsScreen extends StatefulWidget {
  final bool isMentor;
  const WebSettingsScreen({super.key, this.isMentor = true});

  @override
  State<WebSettingsScreen> createState() => _WebSettingsScreenState();
}

class _WebSettingsScreenState extends State<WebSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  String _downloadLocation = 'Default Downloads Folder';

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    double contentMaxWidth = isDesktop ? 800 : (isTablet ? 600 : double.infinity);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 24,
          ),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildWebSection(
                  'Notifications',
                  Icons.notifications,
                  [
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive app notifications',
                      _notificationsEnabled,
                      (value) => setState(() => _notificationsEnabled = value),
                    ),
                    _buildSwitchTile(
                      'Email Notifications',
                      'Receive email updates',
                      _emailNotifications,
                      (value) => setState(() => _emailNotifications = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Appearance',
                  Icons.palette,
                  [
                    _buildSwitchTile(
                      'Dark Mode',
                      'Toggle dark/light theme',
                      _darkMode,
                      (value) => setState(() => _darkMode = value),
                    ),
                    _buildListTile(
                      'Language',
                      _language,
                      Icons.language,
                      () => _showLanguageDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Files & Storage',
                  Icons.folder,
                  [
                    _buildListTile(
                      'Download Location',
                      _downloadLocation,
                      Icons.download,
                      () => _showDownloadLocationDialog(),
                    ),
                    _buildListTile(
                      'Clear Cache',
                      'Free up space by clearing cached data',
                      Icons.cleaning_services,
                      () => _showClearCacheDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Account',
                  Icons.person,
                  [
                    _buildListTile(
                      'Change Password',
                      null,
                      Icons.lock,
                      () {
                        // TODO: Implement change password
                      },
                    ),
                    _buildListTile(
                      'Privacy Settings',
                      null,
                      Icons.privacy_tip,
                      () {
                        // TODO: Implement privacy settings
                      },
                    ),
                    _buildListTile(
                      'Connected Accounts',
                      'Google Drive, OneDrive',
                      Icons.cloud,
                      () {
                        // TODO: Implement connected accounts
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Help & Support',
                  Icons.help,
                  [
                    _buildListTile(
                      'FAQ',
                      null,
                      Icons.question_answer,
                      () {
                        // TODO: Show FAQ
                      },
                    ),
                    _buildListTile(
                      'Contact Support',
                      null,
                      Icons.support_agent,
                      () {
                        // TODO: Show contact support options
                      },
                    ),
                    _buildListTile(
                      'About',
                      'Version 1.0.0',
                      Icons.info,
                      () {
                        // TODO: Show about dialog
                      },
                    ),
                  ],
                ),
                if (DeveloperSession.isActive) ...[
                  const SizedBox(height: 24),
                  _buildWebSection(
                    'Developer Tools',
                    Icons.developer_mode,
                    [
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
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF0F2D52)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F2D52),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F2D52),
      ),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: _language == 'English' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: _language == 'Spanish' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'Spanish';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: _language == 'French' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
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
                  ? const Icon(Icons.check, color: Color(0xFF0F2D52))
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
                  ? const Icon(Icons.check, color: Color(0xFF0F2D52))
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
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
}