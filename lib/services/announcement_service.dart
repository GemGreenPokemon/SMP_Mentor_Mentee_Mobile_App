import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'cloud_function_service.dart';
import 'auth_service.dart';
import 'tab_visibility_manager/tab_visibility_manager.dart';

class AnnouncementService extends ChangeNotifier {
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  late final TabVisibilityManagerInterface _tabVisibilityManager;
  
  AnnouncementService() {
    _tabVisibilityManager = TabVisibilityManager.getInstance();
  }
  
  // Loading states
  bool _isLoading = false;
  String? _error;
  
  // Cache for announcements
  List<Map<String, dynamic>> _announcements = [];
  DateTime? _lastFetchTime;
  
  // Tab visibility tracking
  bool _isInitialized = false;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get announcements => List.from(_announcements);
  
  /// Initialize the announcement service with tab visibility management
  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;
    
    try {
      await _tabVisibilityManager.initialize();
      
      // Listen for leadership changes
      _tabVisibilityManager.onLeadershipChange('announcement_service', (isLeader) {
        debugPrint('AnnouncementService: Leadership changed to $isLeader');
        if (isLeader && _lastFetchTime == null) {
          // Became leader and no data yet, fetch announcements
          fetchAnnouncements();
        }
      });
      
      // Listen for data updates from other tabs
      _tabVisibilityManager.onDataUpdate('announcement_service', (data) {
        if (data['type'] == 'announcements_update') {
          _handleAnnouncementsUpdate(data['announcements']);
        }
      });
      
      // Listen for visibility changes
      _tabVisibilityManager.onVisibilityChange('announcement_service', (isVisible) {
        debugPrint('AnnouncementService: Visibility changed to $isVisible');
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AnnouncementService: $e');
    }
  }
  
  /// Get announcements for current user
  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    try {
      // Check if we need to refresh (cache for 5 minutes)
      if (!forceRefresh && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
        return;
      }
      
      // Check if we should make the API call (only if leader and visible on web)
      if (kIsWeb && _isInitialized && !_tabVisibilityManager.shouldMakeApiCall()) {
        debugPrint('AnnouncementService: Not making API call - not leader or not visible');
        
        // Try to get cached data from other tabs
        final cachedData = _tabVisibilityManager.getSharedData('announcements');
        if (cachedData != null && cachedData['announcements'] != null) {
          _handleAnnouncementsUpdate(cachedData['announcements']);
        }
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
        // Get user info ONCE at the beginning
        final currentUserId = _authService.currentUser?.uid;
        
        final List<dynamic> rawAnnouncements = result['data'];
        _announcements = rawAnnouncements.map((announcement) {
          final Map<String, dynamic> announcementMap = Map<String, dynamic>.from(announcement);
          
          // Pre-calculate edit permission for this announcement
          bool canEdit = false;
          if (userRole == 'coordinator') {
            canEdit = true;  // Coordinators can edit all announcements
          } else if (userRole == 'mentor' && announcementMap['created_by'] == currentUserId) {
            canEdit = true;  // Mentors can edit their own announcements
          }
          
          return {
            'id': announcementMap['id'],
            'title': announcementMap['title'],
            'content': announcementMap['content'],
            'time': _formatAnnouncementTime(announcementMap['created_at']),
            'priority': announcementMap['priority'] ?? 'none',
            'target_audience': announcementMap['target_audience'],
            'created_by': announcementMap['created_by'],
            'canEdit': canEdit,  // Add pre-calculated permission
          };
        }).toList();
        _lastFetchTime = DateTime.now();
        
        // Share announcements with other tabs if on web
        if (kIsWeb && _isInitialized) {
          _tabVisibilityManager.shareData('announcements', {
            'type': 'announcements_update',
            'announcements': _announcements,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
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
  /// @deprecated Use pre-calculated canEdit field from announcements instead
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
  
  /// Handle announcements update from other tabs
  void _handleAnnouncementsUpdate(dynamic announcementsData) {
    try {
      if (announcementsData is List) {
        _announcements = List<Map<String, dynamic>>.from(
          announcementsData.map((item) => Map<String, dynamic>.from(item))
        );
        _lastFetchTime = DateTime.now();
        notifyListeners();
        debugPrint('AnnouncementService: Updated announcements from shared data');
      }
    } catch (e) {
      debugPrint('Error handling announcements update: $e');
    }
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
  
  @override
  void dispose() {
    if (_isInitialized) {
      _tabVisibilityManager.removeCallback('announcement_service');
    }
    super.dispose();
  }
}