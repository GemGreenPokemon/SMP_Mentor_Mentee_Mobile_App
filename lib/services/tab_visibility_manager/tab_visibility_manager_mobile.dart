import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/tab_state.dart';
import 'models/visibility_event.dart';
import 'tab_visibility_manager_interface.dart';

/// Mobile implementation of TabVisibilityManager
/// 
/// Since mobile apps don't have tabs like web browsers, this is a stub implementation
/// that always reports the app as visible and as the leader.
class TabVisibilityManagerMobile implements TabVisibilityManagerInterface {
  // Singleton pattern
  static final TabVisibilityManagerMobile _instance = TabVisibilityManagerMobile._internal();
  factory TabVisibilityManagerMobile() => _instance;
  TabVisibilityManagerMobile._internal();

  // State
  final String _tabId = 'mobile_app_${DateTime.now().millisecondsSinceEpoch}';
  bool _isInitialized = false;
  final bool _isLeader = true; // Mobile app is always the leader
  final bool _isVisible = true; // Mobile app is always visible when running
  
  // Stream controllers
  final _visibilityController = StreamController<bool>.broadcast();
  final _leadershipController = StreamController<bool>.broadcast();
  final _dataUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Callbacks storage
  final Map<String, Function(bool)> _visibilityCallbacks = {};
  final Map<String, Function(bool)> _leadershipCallbacks = {};
  final Map<String, Function(Map<String, dynamic>)> _dataCallbacks = {};
  
  // Local data storage for mobile
  final Map<String, Map<String, dynamic>> _sharedData = {};

  // Public getters
  @override
  String get tabId => _tabId;
  @override
  bool get isLeader => _isLeader;
  @override
  bool get isVisible => _isVisible;
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Stream<bool> get visibilityStream => _visibilityController.stream;
  @override
  Stream<bool> get leadershipStream => _leadershipController.stream;
  @override
  Stream<Map<String, dynamic>> get dataUpdateStream => _dataUpdateController.stream;

  /// Initialize the tab visibility manager
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('TabVisibilityManager: Initializing mobile implementation');
    _isInitialized = true;
    
    // Emit initial states
    _visibilityController.add(_isVisible);
    _leadershipController.add(_isLeader);
  }

  /// Register visibility change callback
  @override
  void onVisibilityChange(String key, Function(bool isVisible) callback) {
    _visibilityCallbacks[key] = callback;
  }

  /// Register leadership change callback
  @override
  void onLeadershipChange(String key, Function(bool isLeader) callback) {
    _leadershipCallbacks[key] = callback;
  }

  /// Register data update callback
  @override
  void onDataUpdate(String key, Function(Map<String, dynamic> data) callback) {
    _dataCallbacks[key] = callback;
  }

  /// Remove callbacks
  @override
  void removeCallback(String key) {
    _visibilityCallbacks.remove(key);
    _leadershipCallbacks.remove(key);
    _dataCallbacks.remove(key);
  }

  /// Share data with other tabs (stored locally on mobile)
  @override
  void shareData(String key, Map<String, dynamic> data) {
    if (!_isInitialized) return;
    
    _sharedData[key] = data;
    _dataUpdateController.add(data);
    
    // Notify callbacks
    for (final callback in _dataCallbacks.values) {
      callback(data);
    }
  }

  /// Get shared data
  @override
  Map<String, dynamic>? getSharedData(String key) {
    if (!_isInitialized) return null;
    return _sharedData[key];
  }

  /// Check if should make API call (always true on mobile)
  @override
  bool shouldMakeApiCall() {
    return true; // Mobile app always makes API calls
  }

  /// Force leader election (no-op on mobile)
  @override
  Future<void> forceLeaderElection() async {
    // No-op on mobile since there's only one instance
    debugPrint('TabVisibilityManager: Force leader election called (no-op on mobile)');
  }

  /// Clean up resources
  @override
  void dispose() {
    if (!_isInitialized) return;
    
    _visibilityCallbacks.clear();
    _leadershipCallbacks.clear();
    _dataCallbacks.clear();
    _sharedData.clear();
    
    _visibilityController.close();
    _leadershipController.close();
    _dataUpdateController.close();
    
    _isInitialized = false;
  }
}

// Type alias for conditional imports
typedef TabVisibilityManagerImpl = TabVisibilityManagerMobile;