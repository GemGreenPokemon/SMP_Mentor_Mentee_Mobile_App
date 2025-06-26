import '../models/tab_state.dart';

/// Abstract interface for TabVisibilityHelpers to support multiple platforms
abstract class TabVisibilityHelpersInterface {
  /// Generate a unique tab ID
  String generateTabId();

  /// Check if a tab has timed out
  bool isTabTimedOut(TabState tab);

  /// Get all active tabs from storage
  List<TabState> getActiveTabs();

  /// Save tabs to storage
  void saveTabs(List<TabState> tabs);

  /// Get current leader tab ID
  String? getCurrentLeader();

  /// Set leader tab ID
  void setLeader(String tabId);

  /// Clear all tab visibility data (useful for cleanup)
  void clearAllData();

  /// Check if browser/platform supports required APIs
  bool isBrowserSupported();

  /// Get shared data from storage
  Map<String, dynamic>? getSharedData(String key);

  /// Save shared data to storage
  void saveSharedData(String key, Map<String, dynamic> data);
}