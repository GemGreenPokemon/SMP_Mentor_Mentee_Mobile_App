import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // optional retains kDebugMode if needed
import 'package:provider/provider.dart';
import '../utils/developer_session.dart';
import '../utils/test_mode_manager.dart';
import '../services/mentor_service.dart';
import 'firestore_manager_screen.dart';
import 'local_db_manager_screen.dart';
import 'local_mentor_selection_screen.dart';

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
  void initState() {
    super.initState();
    // Initialize test mode manager to load saved state
    TestModeManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop (normal navigation)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If we can't pop, we likely came from developer menu
              // Navigate to developer home if in developer mode, otherwise to login
              if (DeveloperSession.isActive) {
                Navigator.pushReplacementNamed(context, '/dev');
              } else {
                // Go to the appropriate dashboard based on user type
                // For now, go to login as a safe fallback
                Navigator.pushReplacementNamed(context, '/');
              }
            }
          },
        ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocalDbManagerScreen(),
                      ),
                    );
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
                const Divider(height: 1),
                StatefulBuilder(
                  builder: (context, setLocalState) {
                    return SwitchListTile(
                      title: const Text('Test Mode'),
                      subtitle: TestModeManager.isTestMode && TestModeManager.currentTestUser != null
                          ? Text('Testing as: ${TestModeManager.currentTestUser!.name}')
                          : const Text('Test app as a local database user'),
                      value: TestModeManager.isTestMode,
                      onChanged: (bool value) async {
                        final mentorService = Provider.of<MentorService>(context, listen: false);
                        
                        if (value) {
                          // Navigate to mentor selection screen
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocalMentorSelectionScreen(),
                            ),
                          );
                          
                          // Refresh the switch state if a selection was made
                          if (result == true) {
                            // Refresh MentorService to load database data
                            await mentorService.refresh();
                            setLocalState(() {});
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test mode enabled - using database data'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } else {
                          // Disable test mode
                          await TestModeManager.disableTestMode();
                          // Refresh MentorService to use mock data
                          await mentorService.refresh();
                          setLocalState(() {});
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test mode disabled - using mock data'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                if (TestModeManager.isTestMode)
                  ListTile(
                    title: const Text('Change Test User'),
                    subtitle: Text('Currently: ${TestModeManager.currentTestUser?.name ?? "None"}'),
                    trailing: const Icon(Icons.person_search),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocalMentorSelectionScreen(),
                        ),
                      );
                      
                      if (result == true && mounted) {
                        // Refresh MentorService with new test user data
                        final mentorService = Provider.of<MentorService>(context, listen: false);
                        await mentorService.refresh();
                        setState(() {}); // Refresh to show new user
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Test user changed to: ${TestModeManager.currentTestUser?.name ?? "Unknown"}'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
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