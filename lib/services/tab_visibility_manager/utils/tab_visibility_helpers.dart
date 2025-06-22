import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import '../models/tab_state.dart';
import 'tab_visibility_constants.dart';

/// Helper functions for tab visibility management
class TabVisibilityHelpers {
  /// Generate a unique tab ID
  static String generateTabId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'tab_${timestamp}_$random';
  }

  /// Check if a tab has timed out
  static bool isTabTimedOut(TabState tab) {
    final now = DateTime.now();
    final timeSinceActivity = now.difference(tab.lastActivity);
    return timeSinceActivity > TabVisibilityConstants.tabTimeoutDuration;
  }

  /// Get all active tabs from localStorage
  static List<TabState> getActiveTabs() {
    try {
      final storage = html.window.localStorage;
      final tabsJson = storage[TabVisibilityConstants.tabsKey];
      
      if (tabsJson == null) return [];
      
      final List<dynamic> tabsList = jsonDecode(tabsJson);
      final tabs = tabsList
          .map((json) => TabState.fromJson(json))
          .where((tab) => !isTabTimedOut(tab))
          .toList();
      
      // Sort by creation time to maintain consistent ordering
      tabs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return tabs;
    } catch (e) {
      print('Error getting active tabs: $e');
      return [];
    }
  }

  /// Save tabs to localStorage
  static void saveTabs(List<TabState> tabs) {
    try {
      final storage = html.window.localStorage;
      final tabsJson = jsonEncode(tabs.map((tab) => tab.toJson()).toList());
      storage[TabVisibilityConstants.tabsKey] = tabsJson;
    } catch (e) {
      print('Error saving tabs: $e');
    }
  }

  /// Get current leader tab ID
  static String? getCurrentLeader() {
    try {
      final storage = html.window.localStorage;
      return storage[TabVisibilityConstants.leaderKey];
    } catch (e) {
      print('Error getting current leader: $e');
      return null;
    }
  }

  /// Set leader tab ID
  static void setLeader(String tabId) {
    try {
      final storage = html.window.localStorage;
      storage[TabVisibilityConstants.leaderKey] = tabId;
    } catch (e) {
      print('Error setting leader: $e');
    }
  }

  /// Clear all tab visibility data (useful for cleanup)
  static void clearAllData() {
    try {
      final storage = html.window.localStorage;
      final keys = storage.keys.where((key) => key.startsWith(TabVisibilityConstants.storagePrefix)).toList();
      for (final key in keys) {
        storage.remove(key);
      }
    } catch (e) {
      print('Error clearing tab visibility data: $e');
    }
  }

  /// Check if browser supports required APIs
  static bool isBrowserSupported() {
    try {
      // Check for localStorage support
      final storage = html.window.localStorage;
      storage['test'] = 'test';
      storage.remove('test');
      
      // Check for visibility API support
      final document = html.document;
      return document.hidden != null;
    } catch (e) {
      return false;
    }
  }

  /// Get shared data from localStorage
  static Map<String, dynamic>? getSharedData(String key) {
    try {
      final storage = html.window.localStorage;
      final fullKey = '${TabVisibilityConstants.dataKey}_$key';
      final dataJson = storage[fullKey];
      
      if (dataJson == null) return null;
      
      return jsonDecode(dataJson);
    } catch (e) {
      print('Error getting shared data: $e');
      return null;
    }
  }

  /// Save shared data to localStorage
  static void saveSharedData(String key, Map<String, dynamic> data) {
    try {
      final storage = html.window.localStorage;
      final fullKey = '${TabVisibilityConstants.dataKey}_$key';
      storage[fullKey] = jsonEncode(data);
    } catch (e) {
      print('Error saving shared data: $e');
    }
  }
}