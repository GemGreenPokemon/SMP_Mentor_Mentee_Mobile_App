import 'package:flutter/material.dart';
import '../../../services/cloud_function_service.dart';
import '../../../services/auth_service.dart';

class SyncClaimsDialog extends StatefulWidget {
  const SyncClaimsDialog({super.key});

  @override
  State<SyncClaimsDialog> createState() => _SyncClaimsDialogState();
}

class _SyncClaimsDialogState extends State<SyncClaimsDialog> {
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _status = 'Ready to sync claims';
  String _details = '';

  Future<void> _syncClaims() async {
    setState(() {
      _isLoading = true;
      _status = 'Syncing claims...';
      _details = '';
    });

    try {
      // Get current token info
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Error: No user logged in';
          _isLoading = false;
        });
        return;
      }

      // Check current claims
      final tokenBefore = await user.getIdTokenResult();
      setState(() {
        _details += 'Current claims: ${tokenBefore.claims}\n';
        _details += 'Current role: ${tokenBefore.claims?['role'] ?? 'NOT SET'}\n\n';
      });

      // Call sync function
      setState(() {
        _details += 'Calling sync function...\n';
      });
      
      final result = await _cloudFunctions.syncUserClaimsOnLogin();
      
      if (result['success'] == true) {
        setState(() {
          _details += '✅ Cloud function succeeded\n';
          _details += 'Claims set: ${result['claims']}\n\n';
          _details += 'Forcing token refresh...\n';
        });

        // Force token refresh
        await user.getIdToken(true);
        await Future.delayed(const Duration(seconds: 2));

        // Check new claims
        final tokenAfter = await user.getIdTokenResult(true);
        setState(() {
          _details += '\nToken after refresh:\n';
          _details += 'New claims: ${tokenAfter.claims}\n';
          _details += 'New role: ${tokenAfter.claims?['role'] ?? 'STILL NOT SET'}\n';
          
          if (tokenAfter.claims?['role'] != null) {
            _status = '✅ Success! Role is now: ${tokenAfter.claims?['role']}';
          } else {
            _status = '❌ Failed - claims still not set';
          }
        });
      } else {
        setState(() {
          _status = '❌ Sync failed';
          _details += 'Error: ${result['message'] ?? result['error'] ?? 'Unknown error'}\n';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error occurred';
        _details += 'Exception: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync User Claims'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _status.contains('✅') ? Colors.green : 
                       _status.contains('❌') ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            if (_details.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _details,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _syncClaims,
          child: const Text('Sync Claims'),
        ),
      ],
    );
  }
}