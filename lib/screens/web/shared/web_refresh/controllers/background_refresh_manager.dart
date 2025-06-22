import 'dart:async';
import 'package:flutter/foundation.dart';
import 'refresh_controller.dart';
import '../models/refresh_strategy.dart';

/// Manages background refresh for multiple controllers across the app
class BackgroundRefreshManager {
  static BackgroundRefreshManager? _instance;
  
  /// Singleton instance
  static BackgroundRefreshManager get instance {
    _instance ??= BackgroundRefreshManager._();
    return _instance!;
  }
  
  BackgroundRefreshManager._();
  
  /// Map of registered controllers with their IDs
  final Map<String, RefreshController> _controllers = {};
  
  /// Map tracking visibility state of each controller
  final Map<String, bool> _visibilityStates = {};
  
  /// Map tracking background refresh counts for memory management
  final Map<String, int> _backgroundRefreshCounts = {};
  
  /// Timer for monitoring and managing background refreshes
  Timer? _monitoringTimer;
  
  /// Whether background refresh is globally enabled
  bool _globalBackgroundRefreshEnabled = true;
  
  /// Register a controller with the manager
  void register(String id, RefreshController controller) {
    _controllers[id] = controller;
    _visibilityStates[id] = true; // Assume visible on registration
    _backgroundRefreshCounts[id] = 0;
    
    // Start monitoring if this is the first controller
    if (_controllers.length == 1) {
      _startMonitoring();
    }
    
    if (kDebugMode) {
      print('BackgroundRefreshManager: Registered controller $id');
    }
  }
  
  /// Unregister a controller
  void unregister(String id) {
    _controllers.remove(id);
    _visibilityStates.remove(id);
    _backgroundRefreshCounts.remove(id);
    
    // Stop monitoring if no controllers remain
    if (_controllers.isEmpty) {
      _stopMonitoring();
    }
    
    if (kDebugMode) {
      print('BackgroundRefreshManager: Unregistered controller $id');
    }
  }
  
  /// Update visibility state for a controller
  void updateVisibility(String id, bool isVisible) {
    if (!_controllers.containsKey(id)) return;
    
    final wasVisible = _visibilityStates[id] ?? true;
    _visibilityStates[id] = isVisible;
    
    final controller = _controllers[id]!;
    
    if (wasVisible && !isVisible) {
      // Page became hidden
      _onControllerHidden(id, controller);
    } else if (!wasVisible && isVisible) {
      // Page became visible
      _onControllerVisible(id, controller);
    }
  }
  
  /// Called when a controller's page becomes hidden
  void _onControllerHidden(String id, RefreshController controller) {
    if (kDebugMode) {
      print('BackgroundRefreshManager: Controller $id became hidden');
    }
    
    // Reset background refresh count
    _backgroundRefreshCounts[id] = 0;
    
    // Update controller's refresh behavior based on strategy
    final strategy = controller.config.backgroundStrategy ?? RefreshStrategy.none;
    
    if (strategy.allowsBackgroundRefresh && _globalBackgroundRefreshEnabled) {
      // Adjust refresh interval for background
      controller.adjustRefreshInterval(strategy.backgroundIntervalMultiplier);
    } else {
      // Pause refresh
      controller.pauseAutoRefresh();
    }
  }
  
  /// Called when a controller's page becomes visible
  void _onControllerVisible(String id, RefreshController controller) {
    if (kDebugMode) {
      print('BackgroundRefreshManager: Controller $id became visible');
    }
    
    // Reset background refresh count
    _backgroundRefreshCounts[id] = 0;
    
    // Resume normal refresh behavior
    controller.resumeAutoRefresh();
    
    // Only refresh if data is actually stale (more than staleDataThreshold old)
    if (controller.state.shouldAutoRefresh(controller.config.staleDataThreshold)) {
      controller.refresh(silent: true);
    }
  }
  
  /// Start monitoring background refreshes
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkBackgroundRefreshLimits();
    });
  }
  
  /// Stop monitoring
  void _stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }
  
  /// Check and enforce background refresh limits
  void _checkBackgroundRefreshLimits() {
    _controllers.forEach((id, controller) {
      final isVisible = _visibilityStates[id] ?? true;
      
      if (!isVisible) {
        final count = _backgroundRefreshCounts[id] ?? 0;
        final maxCount = controller.config.maxBackgroundRefreshes ?? 10;
        
        if (count >= maxCount) {
          // Pause refresh if limit reached
          controller.pauseAutoRefresh();
          if (kDebugMode) {
            print('BackgroundRefreshManager: Controller $id reached background refresh limit');
          }
        }
      }
    });
  }
  
  /// Track a background refresh
  void trackBackgroundRefresh(String id) {
    if (_visibilityStates[id] == false) {
      _backgroundRefreshCounts[id] = (_backgroundRefreshCounts[id] ?? 0) + 1;
    }
  }
  
  /// Enable or disable background refresh globally
  void setGlobalBackgroundRefreshEnabled(bool enabled) {
    _globalBackgroundRefreshEnabled = enabled;
    
    // Update all hidden controllers
    _controllers.forEach((id, controller) {
      if (_visibilityStates[id] == false) {
        if (enabled) {
          _onControllerHidden(id, controller);
        } else {
          controller.pauseAutoRefresh();
        }
      }
    });
  }
  
  /// Get statistics about background refresh
  Map<String, dynamic> getStatistics() {
    return {
      'totalControllers': _controllers.length,
      'visibleControllers': _visibilityStates.values.where((v) => v).length,
      'hiddenControllers': _visibilityStates.values.where((v) => !v).length,
      'backgroundRefreshCounts': Map<String, int>.from(_backgroundRefreshCounts),
      'globalEnabled': _globalBackgroundRefreshEnabled,
    };
  }
  
  /// Dispose of the manager
  void dispose() {
    _stopMonitoring();
    _controllers.clear();
    _visibilityStates.clear();
    _backgroundRefreshCounts.clear();
  }
}