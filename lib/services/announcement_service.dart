import 'package:flutter/material.dart';
import 'cloud_function_service.dart';
import 'auth_service.dart';

class AnnouncementService extends ChangeNotifier {
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  
  // Loading states
  bool _isLoading = false;
  String? _error;
  
  // Cache for announcements
  List<Map<String, dynamic>> _announcements = [];
  DateTime? _lastFetchTime;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get announcements => List.from(_announcements);
  
  /// Get announcements for current user
  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    try {
      // Check if we need to refresh (cache for 5 minutes)
      if (!forceRefresh && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
        return;
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final userRole = await _authService.getUserRole();
      if (userRole == null) {
        throw Exception('User role not found');
      }
      
      final result = await _cloudFunctions.getAnnouncements(
        universityPath: _cloudFunctions.getCurrentUniversityPath(),
        userType: userRole,
        limit: 50,
      );
      
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawAnnouncements = result['data'];
        _announcements = rawAnnouncements.map((announcement) {
          final Map<String, dynamic> announcementMap = Map<String, dynamic>.from(announcement);
          return {
            'id': announcementMap['id'],
            'title': announcementMap['title'],
            'content': announcementMap['content'],
            'time': _formatAnnouncementTime(announcementMap['created_at']),
            'priority': announcementMap['priority'] ?? 'none',
            'target_audience': announcementMap['target_audience'],
            'created_by': announcementMap['created_by'],
          };
        }).toList();
        _lastFetchTime = DateTime.now();
      } else {
        throw Exception(result['error'] ?? 'Failed to fetch announcements');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Create a new announcement
  Future<bool> createAnnouncement({
    required String title,
    required String content,
    required String priority,
    required String targetAudience,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print('📢 === CREATE ANNOUNCEMENT START ===');
      print('📢 Current user: ${_authService.currentUser?.email} (${_authService.currentUser?.uid})');
      print('📢 Checking user role before creating announcement...');
      
      // Double-check user role and try to sync claims if needed
      final userRole = await _authService.getUserRole();
      print('📢 User role from auth service: $userRole');
      
      if (userRole == null || userRole == 'mentee') {
        print('📢 ⚠️ Invalid role for announcement creation. Attempting claims sync...');
        
        try {
          // Try to sync claims one more time
          final syncResult = await _cloudFunctions.syncUserClaimsOnLogin();
          if (syncResult['success'] == true) {
            print('📢 ✅ Claims synced, forcing token refresh...');
            await _authService.currentUser?.getIdToken(true);
            await Future.delayed(const Duration(seconds: 1));
            
            // Check role again
            final newRole = await _authService.getUserRole();
            print('📢 New role after sync: $newRole');
          }
        } catch (e) {
          print('📢 ❌ Failed to sync claims: $e');
        }
      }
      
      print('📢 Creating announcement with Cloud Function...');
      final result = await _cloudFunctions.createAnnouncement(
        universityPath: _cloudFunctions.getCurrentUniversityPath(),
        title: title,
        content: content,
        priority: priority,
        targetAudience: targetAudience,
      );
      
      if (result['success'] == true) {
        // Refresh announcements to include the new one
        await fetchAnnouncements(forceRefresh: true);
        return true;
      } else {
        throw Exception(result['error'] ?? 'Failed to create announcement');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating announcement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update an existing announcement
  Future<bool> updateAnnouncement({
    required String announcementId,
    String? title,
    String? content,
    String? priority,
    String? targetAudience,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _cloudFunctions.updateAnnouncement(
        universityPath: _cloudFunctions.getCurrentUniversityPath(),
        announcementId: announcementId,
        title: title,
        content: content,
        priority: priority,
        targetAudience: targetAudience,
      );
      
      if (result['success'] == true) {
        // Refresh announcements to reflect the update
        await fetchAnnouncements(forceRefresh: true);
        return true;
      } else {
        throw Exception(result['error'] ?? 'Failed to update announcement');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating announcement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Delete an announcement
  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _cloudFunctions.deleteAnnouncement(
        universityPath: _cloudFunctions.getCurrentUniversityPath(),
        announcementId: announcementId,
      );
      
      if (result['success'] == true) {
        // Remove from local cache
        _announcements.removeWhere((announcement) => announcement['id'] == announcementId);
        return true;
      } else {
        throw Exception(result['error'] ?? 'Failed to delete announcement');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting announcement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Check if current user can edit/delete the announcement
  Future<bool> canEditAnnouncement(String createdBy) async {
    try {
      final userRole = await _authService.getUserRole();
      final currentUser = _authService.currentUser;
      
      // Coordinators can edit any announcement
      if (userRole == 'coordinator') {
        return true;
      }
      
      // Mentors can only edit their own announcements
      if (userRole == 'mentor' && currentUser?.uid == createdBy) {
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking edit permissions: $e');
      return false;
    }
  }
  
  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Format announcement timestamp for display
  String _formatAnnouncementTime(dynamic timestamp) {
    try {
      DateTime createdAt;
      if (timestamp is String) {
        createdAt = DateTime.parse(timestamp);
      } else if (timestamp is Map && timestamp['_seconds'] != null) {
        // Firestore timestamp format
        createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}