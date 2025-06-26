import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/refresh_config.dart';
import '../models/refresh_state.dart';
import '../models/refresh_strategy.dart';
import '../utils/platform_focus_listener.dart';
import 'background_refresh_manager.dart';

abstract class RefreshController<T> extends ChangeNotifier {
  final RefreshConfig config;
  
  RefreshState _state = const RefreshState();
  T? _data;
  Timer? _autoRefreshTimer;
  StreamSubscription? _focusSubscription;
  
  // Background refresh properties
  bool _isVisible = true;
  Duration? _currentRefreshInterval;
  bool _isPaused = false;
  String? _controllerId;

  RefreshController({RefreshConfig? config}) 
    : config = config ?? const RefreshConfig() {
    _initialize();
  }

  T? get data => _data;
  RefreshState get state => _state;
  bool get hasData => _data != null;
  bool get isVisible => _isVisible;

  void _initialize() {
    _currentRefreshInterval = config.autoRefreshInterval;
    
    if (config.enableAutoRefresh) {
      _setupAutoRefresh();
    }
    
    if (config.refreshOnFocus && kIsWeb) {
      _setupFocusListener();
    }
  }
  
  /// Register this controller with an ID for background refresh management
  void registerForBackgroundRefresh(String id) {
    _controllerId = id;
    if (config.keepAliveInBackground) {
      BackgroundRefreshManager.instance.register(id, this);
    }
  }

  void _setupAutoRefresh() {
    if (_isPaused) return;
    
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      _currentRefreshInterval ?? config.autoRefreshInterval,
      (_) => _performAutoRefresh(),
    );
  }

  void _setupFocusListener() {
    _focusSubscription?.cancel();
    final focusListener = PlatformFocusListener();
    _focusSubscription = focusListener.listenForFocus(() {
      _performAutoRefresh();
    });
  }

  void _performAutoRefresh() {
    if (state.shouldAutoRefresh(config.staleDataThreshold)) {
      if (kDebugMode) {
        print('RefreshController: Performing auto refresh (visible: $_isVisible, controller: $_controllerId)');
      }
      refresh(silent: true);
      
      // Track background refresh if not visible
      if (!_isVisible && _controllerId != null) {
        BackgroundRefreshManager.instance.trackBackgroundRefresh(_controllerId!);
      }
    } else if (kDebugMode) {
      final timeSinceLastRefresh = state.lastRefresh != null 
          ? DateTime.now().difference(state.lastRefresh!).inSeconds 
          : 'never';
      print('RefreshController: Skip auto refresh - data not stale (last refresh: $timeSinceLastRefresh seconds ago)');
    }
  }

  Future<T> fetchData();

  Future<T?> refresh({bool silent = false}) async {
    if (_state.isRefreshing) {
      if (kDebugMode) {
        print('RefreshController: Skipping refresh - already refreshing');
      }
      return _data;
    }

    if (kDebugMode) {
      print('RefreshController: Starting refresh (silent: $silent, controller: $_controllerId)');
    }

    _updateState(_state.copyWith(
      isRefreshing: !silent,
      error: null,
    ));

    try {
      _data = await fetchData();
      _updateState(_state.copyWith(
        isRefreshing: false,
        isInitialLoad: false,
        lastRefresh: DateTime.now(),
        error: null,
      ));
      return _data;
    } catch (e) {
      _updateState(_state.copyWith(
        isRefreshing: false,
        isInitialLoad: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<T?> initialLoad() async {
    _updateState(const RefreshState(
      isInitialLoad: true,
      isRefreshing: false,
    ));
    return refresh();
  }

  void _updateState(RefreshState newState) {
    _state = newState;
    notifyListeners();
  }

  void updateConfig(RefreshConfig newConfig) {
    if (config.enableAutoRefresh != newConfig.enableAutoRefresh) {
      if (newConfig.enableAutoRefresh) {
        _setupAutoRefresh();
      } else {
        _autoRefreshTimer?.cancel();
      }
    }
    
    if (config.refreshOnFocus != newConfig.refreshOnFocus) {
      if (newConfig.refreshOnFocus) {
        _setupFocusListener();
      } else {
        _focusSubscription?.cancel();
      }
    }
  }
  
  /// Update visibility state of this controller
  void setVisibility(bool isVisible) {
    if (_isVisible == isVisible) return;
    
    _isVisible = isVisible;
    
    if (_controllerId != null && config.keepAliveInBackground) {
      BackgroundRefreshManager.instance.updateVisibility(_controllerId!, isVisible);
    }
  }
  
  /// Pause auto refresh
  void pauseAutoRefresh() {
    _isPaused = true;
    _autoRefreshTimer?.cancel();
  }
  
  /// Resume auto refresh
  void resumeAutoRefresh() {
    _isPaused = false;
    if (config.enableAutoRefresh) {
      _setupAutoRefresh();
    }
  }
  
  /// Adjust refresh interval (used for background refresh)
  void adjustRefreshInterval(double multiplier) {
    final baseInterval = config.backgroundRefreshInterval ?? config.autoRefreshInterval;
    _currentRefreshInterval = Duration(
      milliseconds: (baseInterval.inMilliseconds * multiplier).round(),
    );
    
    // Restart timer with new interval
    if (config.enableAutoRefresh && !_isPaused) {
      _setupAutoRefresh();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _focusSubscription?.cancel();
    
    // Unregister from background refresh manager
    if (_controllerId != null && config.keepAliveInBackground) {
      BackgroundRefreshManager.instance.unregister(_controllerId!);
    }
    
    super.dispose();
  }
}