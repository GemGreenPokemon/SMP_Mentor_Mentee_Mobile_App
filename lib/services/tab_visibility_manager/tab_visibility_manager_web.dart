import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'models/tab_state.dart';
import 'models/visibility_event.dart';
import 'utils/tab_visibility_constants.dart';
import 'utils/tab_visibility_helpers.dart';
import 'tab_visibility_manager_interface.dart';

/// Web implementation of TabVisibilityManager
/// 
/// This service implements a leader election pattern where only one tab (the leader)
/// makes API calls while other tabs receive updates via localStorage events.
/// 
/// Features:
/// - Automatic leader election when tabs open/close
/// - Visibility detection to pause background tabs
/// - Shared data synchronization between tabs
/// - Graceful fallback if localStorage is unavailable
class TabVisibilityManagerWeb implements TabVisibilityManagerInterface {
  // Singleton pattern
  static final TabVisibilityManagerWeb _instance = TabVisibilityManagerWeb._internal();
  factory TabVisibilityManagerWeb() => _instance;
  TabVisibilityManagerWeb._internal();

  // State
  late String _tabId;
  bool _isInitialized = false;
  bool _isLeader = false;
  bool _isVisible = true;
  Timer? _heartbeatTimer;
  Timer? _leaderCheckTimer;
  
  // Callbacks
  final Map<String, Function(bool)> _visibilityCallbacks = {};
  final Map<String, Function(bool)> _leadershipCallbacks = {};
  final Map<String, Function(Map<String, dynamic>)> _dataCallbacks = {};
  
  // Stream controllers
  final _visibilityController = StreamController<bool>.broadcast();
  final _leadershipController = StreamController<bool>.broadcast();
  final _dataUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
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
    
    // Check browser support
    if (!kIsWeb || !TabVisibilityHelpers.isBrowserSupported()) {
      debugPrint('TabVisibilityManager: Browser not supported or not running on web');
      _isLeader = true; // Default to leader if not supported
      _isInitialized = true;
      return;
    }
    
    try {
      _tabId = TabVisibilityHelpers.generateTabId();
      debugPrint('TabVisibilityManager: Initializing with tab ID: $_tabId');
      
      // Set up visibility listener
      _setupVisibilityListener();
      
      // Set up storage event listener
      _setupStorageListener();
      
      // Register this tab
      _registerTab();
      
      // Start leader election
      await _electLeader();
      
      // Start heartbeat
      _startHeartbeat();
      
      // Clean up on page unload
      html.window.onBeforeUnload.listen((_) {
        dispose();
      });
      
      _isInitialized = true;
      debugPrint('TabVisibilityManager: Initialization complete. Is leader: $_isLeader');
    } catch (e) {
      debugPrint('TabVisibilityManager: Error during initialization: $e');
      _isLeader = true; // Fallback to leader on error
      _isInitialized = true;
    }
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

  /// Share data with other tabs
  @override
  void shareData(String key, Map<String, dynamic> data) {
    if (!_isInitialized) return;
    
    try {
      // Save data
      TabVisibilityHelpers.saveSharedData(key, data);
      
      // Broadcast event
      _broadcastEvent(VisibilityEvent(
        type: VisibilityEventType.dataUpdated,
        tabId: _tabId,
        timestamp: DateTime.now(),
        data: {'key': key},
      ));
    } catch (e) {
      debugPrint('TabVisibilityManager: Error sharing data: $e');
    }
  }

  /// Get shared data
  @override
  Map<String, dynamic>? getSharedData(String key) {
    if (!_isInitialized) return null;
    return TabVisibilityHelpers.getSharedData(key);
  }

  /// Check if should make API call (is leader and visible)
  @override
  bool shouldMakeApiCall() {
    return _isLeader && _isVisible;
  }

  /// Force leader election (useful for testing)
  @override
  Future<void> forceLeaderElection() async {
    await _electLeader();
  }

  // Private methods

  void _setupVisibilityListener() {
    html.document.onVisibilityChange.listen((_) {
      final wasVisible = _isVisible;
      _isVisible = !html.document.hidden!;
      
      if (wasVisible != _isVisible) {
        debugPrint('TabVisibilityManager: Visibility changed to $_isVisible');
        _updateTabState();
        _visibilityController.add(_isVisible);
        
        // Notify callbacks
        for (final callback in _visibilityCallbacks.values) {
          callback(_isVisible);
        }
        
        // If became visible and not leader, check for leader
        if (_isVisible && !_isLeader) {
          _checkForLeader();
        }
      }
    });
  }

  void _setupStorageListener() {
    html.window.onStorage.listen((html.StorageEvent event) {
      if (event.key == TabVisibilityConstants.eventKey && event.newValue != null) {
        try {
          final eventData = VisibilityEvent.fromJson(Map<String, dynamic>.from(
            Uri.splitQueryString(event.newValue!)
          ));
          _handleStorageEvent(eventData);
        } catch (e) {
          debugPrint('TabVisibilityManager: Error parsing storage event: $e');
        }
      }
    });
  }

  void _handleStorageEvent(VisibilityEvent event) {
    switch (event.type) {
      case VisibilityEventType.tabBecameLeader:
        if (event.tabId != _tabId && _isLeader) {
          // Another tab became leader, step down
          _setLeadership(false);
        }
        break;
      case VisibilityEventType.dataUpdated:
        if (event.data != null && event.data!['key'] != null) {
          final key = event.data!['key'] as String;
          final data = TabVisibilityHelpers.getSharedData(key);
          if (data != null) {
            _dataUpdateController.add(data);
            
            // Notify callbacks
            for (final callback in _dataCallbacks.values) {
              callback(data);
            }
          }
        }
        break;
      default:
        break;
    }
  }

  void _registerTab() {
    final tabs = TabVisibilityHelpers.getActiveTabs();
    final newTab = TabState(
      tabId: _tabId,
      isVisible: _isVisible,
      isLeader: false,
      lastActivity: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    tabs.add(newTab);
    TabVisibilityHelpers.saveTabs(tabs);
  }

  void _updateTabState() {
    final tabs = TabVisibilityHelpers.getActiveTabs();
    final index = tabs.indexWhere((tab) => tab.tabId == _tabId);
    
    if (index != -1) {
      tabs[index] = tabs[index].copyWith(
        isVisible: _isVisible,
        isLeader: _isLeader,
        lastActivity: DateTime.now(),
      );
      TabVisibilityHelpers.saveTabs(tabs);
    }
  }

  Future<void> _electLeader() async {
    final tabs = TabVisibilityHelpers.getActiveTabs();
    final currentLeader = TabVisibilityHelpers.getCurrentLeader();
    
    // Check if current leader is still active
    final leaderExists = tabs.any((tab) => tab.tabId == currentLeader);
    
    if (!leaderExists || currentLeader == null) {
      // No leader or leader is gone, elect new one
      // Prefer visible tabs, then oldest tab
      final visibleTabs = tabs.where((tab) => tab.isVisible).toList();
      final candidateTabs = visibleTabs.isNotEmpty ? visibleTabs : tabs;
      
      if (candidateTabs.isNotEmpty) {
        final newLeader = candidateTabs.first;
        
        if (newLeader.tabId == _tabId) {
          // This tab becomes leader
          _setLeadership(true);
          TabVisibilityHelpers.setLeader(_tabId);
          
          // Broadcast leadership change
          _broadcastEvent(VisibilityEvent(
            type: VisibilityEventType.tabBecameLeader,
            tabId: _tabId,
            timestamp: DateTime.now(),
          ));
        }
      }
    } else if (currentLeader == _tabId && !_isLeader) {
      // This tab is marked as leader but doesn't know it
      _setLeadership(true);
    }
  }

  void _setLeadership(bool isLeader) {
    if (_isLeader != isLeader) {
      _isLeader = isLeader;
      debugPrint('TabVisibilityManager: Leadership changed to $_isLeader');
      _leadershipController.add(_isLeader);
      
      // Notify callbacks
      for (final callback in _leadershipCallbacks.values) {
        callback(_isLeader);
      }
      
      _updateTabState();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(TabVisibilityConstants.leaderHeartbeatInterval, (_) {
      _updateTabState();
      
      // Clean up timed out tabs
      final tabs = TabVisibilityHelpers.getActiveTabs();
      final activeTabs = tabs.where((tab) => !TabVisibilityHelpers.isTabTimedOut(tab)).toList();
      
      if (activeTabs.length < tabs.length) {
        TabVisibilityHelpers.saveTabs(activeTabs);
      }
      
      // Check if still leader
      if (_isLeader) {
        final currentLeader = TabVisibilityHelpers.getCurrentLeader();
        if (currentLeader != _tabId) {
          _electLeader();
        }
      }
    });
  }

  void _checkForLeader() {
    _leaderCheckTimer?.cancel();
    _leaderCheckTimer = Timer(TabVisibilityConstants.leaderElectionDelay, () {
      _electLeader();
    });
  }

  void _broadcastEvent(VisibilityEvent event) {
    try {
      final storage = html.window.localStorage;
      storage[TabVisibilityConstants.eventKey] = Uri(
        queryParameters: event.toJson().map((k, v) => MapEntry(k, v.toString()))
      ).query;
    } catch (e) {
      debugPrint('TabVisibilityManager: Error broadcasting event: $e');
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    if (!_isInitialized) return;
    
    try {
      // Cancel timers
      _heartbeatTimer?.cancel();
      _leaderCheckTimer?.cancel();
      
      // Remove this tab
      final tabs = TabVisibilityHelpers.getActiveTabs();
      tabs.removeWhere((tab) => tab.tabId == _tabId);
      TabVisibilityHelpers.saveTabs(tabs);
      
      // If was leader, trigger new election
      if (_isLeader) {
        TabVisibilityHelpers.setLeader('');
      }
      
      // Clear callbacks
      _visibilityCallbacks.clear();
      _leadershipCallbacks.clear();
      _dataCallbacks.clear();
      
      // Close streams
      _visibilityController.close();
      _leadershipController.close();
      _dataUpdateController.close();
      
    } catch (e) {
      debugPrint('TabVisibilityManager: Error during disposal: $e');
    }
  }
}

// Type alias for conditional imports
typedef TabVisibilityManagerImpl = TabVisibilityManagerWeb;