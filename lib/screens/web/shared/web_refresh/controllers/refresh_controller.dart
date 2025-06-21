import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/refresh_config.dart';
import '../models/refresh_state.dart';

abstract class RefreshController<T> extends ChangeNotifier {
  final RefreshConfig config;
  
  RefreshState _state = const RefreshState();
  T? _data;
  Timer? _autoRefreshTimer;
  StreamSubscription? _focusSubscription;

  RefreshController({RefreshConfig? config}) 
    : config = config ?? const RefreshConfig() {
    _initialize();
  }

  T? get data => _data;
  RefreshState get state => _state;
  bool get hasData => _data != null;

  void _initialize() {
    if (config.enableAutoRefresh) {
      _setupAutoRefresh();
    }
    
    if (config.refreshOnFocus && kIsWeb) {
      _setupFocusListener();
    }
  }

  void _setupAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      config.autoRefreshInterval,
      (_) => _performAutoRefresh(),
    );
  }

  void _setupFocusListener() {
    _focusSubscription?.cancel();
    _focusSubscription = html.window.onFocus.listen((_) {
      _performAutoRefresh();
    });
  }

  void _performAutoRefresh() {
    if (state.shouldAutoRefresh(config.staleDataThreshold)) {
      refresh(silent: true);
    }
  }

  Future<T> fetchData();

  Future<T?> refresh({bool silent = false}) async {
    if (_state.isRefreshing) return _data;

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

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _focusSubscription?.cancel();
    super.dispose();
  }
}