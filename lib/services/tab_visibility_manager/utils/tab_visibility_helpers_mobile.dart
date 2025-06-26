import 'dart:math';
import '../models/tab_state.dart';
import 'tab_visibility_constants.dart';
import 'tab_visibility_helpers_interface.dart';

/// Mobile implementation of TabVisibilityHelpers
/// 
/// Since mobile apps don't have tabs like web browsers, this is a stub implementation
/// that provides minimal functionality required for the app to work on mobile.
class TabVisibilityHelpersMobile implements TabVisibilityHelpersInterface {
  // Local storage for mobile (in-memory)
  static final List<TabState> _tabs = [];
  static String? _leaderId;
  static final Map<String, Map<String, dynamic>> _sharedData = {};

  /// Generate a unique tab ID
  @override
  String generateTabId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'mobile_tab_${timestamp}_$random';
  }

  /// Check if a tab has timed out (always false on mobile)
  @override
  bool isTabTimedOut(TabState tab) {
    // Mobile app tabs don't timeout
    return false;
  }

  /// Get all active tabs from storage
  @override
  List<TabState> getActiveTabs() {
    // Return the single mobile app "tab"
    return List.from(_tabs);
  }

  /// Save tabs to storage
  @override
  void saveTabs(List<TabState> tabs) {
    _tabs.clear();
    _tabs.addAll(tabs);
  }

  /// Get current leader tab ID
  @override
  String? getCurrentLeader() {
    return _leaderId;
  }

  /// Set leader tab ID
  @override
  void setLeader(String tabId) {
    _leaderId = tabId;
  }

  /// Clear all tab visibility data
  @override
  void clearAllData() {
    _tabs.clear();
    _leaderId = null;
    _sharedData.clear();
  }

  /// Check if platform supports required APIs (always true on mobile)
  @override
  bool isBrowserSupported() {
    // Mobile platform is always supported
    return true;
  }

  /// Get shared data from storage
  @override
  Map<String, dynamic>? getSharedData(String key) {
    return _sharedData[key];
  }

  /// Save shared data to storage
  @override
  void saveSharedData(String key, Map<String, dynamic> data) {
    _sharedData[key] = Map.from(data);
  }
}

// Type alias for conditional imports
typedef TabVisibilityHelpersImpl = TabVisibilityHelpersMobile;