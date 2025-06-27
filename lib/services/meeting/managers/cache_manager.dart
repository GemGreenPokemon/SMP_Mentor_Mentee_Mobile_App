import 'dart:async';
import '../utils/meeting_constants.dart';

/// Manages caching for the meeting service to minimize Firestore queries
class MeetingCacheManager {
  // Singleton instance
  static final MeetingCacheManager _instance = MeetingCacheManager._internal();
  factory MeetingCacheManager() => _instance;
  MeetingCacheManager._internal();
  
  // Cache maps
  final Map<String, String> _userDocIdCache = {};
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration (30 minutes)
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  /// Get cached user document ID
  String? getCachedUserDocId(String uid) {
    final cacheKey = '${MeetingConstants.cacheKeyUserDocId}$uid';
    if (_isValidCache(cacheKey)) {
      return _userDocIdCache[uid];
    }
    return null;
  }
  
  /// Cache user document ID
  void cacheUserDocId(String uid, String docId) {
    _userDocIdCache[uid] = docId;
    _updateTimestamp('${MeetingConstants.cacheKeyUserDocId}$uid');
  }
  
  /// Get cached user data
  Map<String, dynamic>? getCachedUserData(String uid) {
    final cacheKey = '${MeetingConstants.cacheKeyUserData}$uid';
    if (_isValidCache(cacheKey)) {
      return _userDataCache[uid];
    }
    return null;
  }
  
  /// Cache user data
  void cacheUserData(String uid, Map<String, dynamic> userData) {
    _userDataCache[uid] = userData;
    _updateTimestamp('${MeetingConstants.cacheKeyUserData}$uid');
  }
  
  /// Clear all caches
  void clearAllCaches() {
    _userDocIdCache.clear();
    _userDataCache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Clear cache for a specific user
  void clearUserCache(String uid) {
    _userDocIdCache.remove(uid);
    _userDataCache.remove(uid);
    _cacheTimestamps.remove('${MeetingConstants.cacheKeyUserDocId}$uid');
    _cacheTimestamps.remove('${MeetingConstants.cacheKeyUserData}$uid');
  }
  
  /// Check if cache is still valid
  bool _isValidCache(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    final age = DateTime.now().difference(timestamp);
    return age < _cacheDuration;
  }
  
  /// Update cache timestamp
  void _updateTimestamp(String key) {
    _cacheTimestamps[key] = DateTime.now();
  }
  
  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    return {
      'userDocIdCacheSize': _userDocIdCache.length,
      'userDataCacheSize': _userDataCache.length,
      'totalCacheEntries': _cacheTimestamps.length,
      'oldestEntry': _getOldestCacheEntry(),
    };
  }
  
  String? _getOldestCacheEntry() {
    if (_cacheTimestamps.isEmpty) return null;
    
    var oldestKey = _cacheTimestamps.keys.first;
    var oldestTime = _cacheTimestamps[oldestKey]!;
    
    _cacheTimestamps.forEach((key, time) {
      if (time.isBefore(oldestTime)) {
        oldestKey = key;
        oldestTime = time;
      }
    });
    
    return '$oldestKey (${DateTime.now().difference(oldestTime).inMinutes} minutes old)';
  }
}