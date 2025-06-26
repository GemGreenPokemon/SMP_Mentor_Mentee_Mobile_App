import 'dart:async';
import 'models/tab_state.dart';
import 'models/visibility_event.dart';

/// Abstract interface for TabVisibilityManager to support multiple platforms
abstract class TabVisibilityManagerInterface {
  // State
  String get tabId;
  bool get isLeader;
  bool get isVisible;
  bool get isInitialized;
  
  // Streams
  Stream<bool> get visibilityStream;
  Stream<bool> get leadershipStream;
  Stream<Map<String, dynamic>> get dataUpdateStream;

  /// Initialize the tab visibility manager
  Future<void> initialize();

  /// Register visibility change callback
  void onVisibilityChange(String key, Function(bool isVisible) callback);

  /// Register leadership change callback
  void onLeadershipChange(String key, Function(bool isLeader) callback);

  /// Register data update callback
  void onDataUpdate(String key, Function(Map<String, dynamic> data) callback);

  /// Remove callbacks
  void removeCallback(String key);

  /// Share data with other tabs
  void shareData(String key, Map<String, dynamic> data);

  /// Get shared data
  Map<String, dynamic>? getSharedData(String key);

  /// Check if should make API call (is leader and visible)
  bool shouldMakeApiCall();

  /// Force leader election (useful for testing)
  Future<void> forceLeaderElection();

  /// Clean up resources
  void dispose();
}