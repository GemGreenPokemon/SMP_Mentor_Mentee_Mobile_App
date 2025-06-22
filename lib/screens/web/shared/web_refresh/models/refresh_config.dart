import 'package:flutter/foundation.dart';
import 'refresh_strategy.dart';

@immutable
class RefreshConfig {
  final Duration autoRefreshInterval;
  final Duration staleDataThreshold;
  final bool enablePullToRefresh;
  final bool enableAutoRefresh;
  final bool refreshOnFocus;
  final bool showLastUpdated;
  final bool showRefreshIndicator;
  
  // Background refresh options
  final RefreshStrategy? backgroundStrategy;
  final Duration? backgroundRefreshInterval;
  final bool keepAliveInBackground;
  final int? maxBackgroundRefreshes;

  const RefreshConfig({
    this.autoRefreshInterval = const Duration(minutes: 5),
    this.staleDataThreshold = const Duration(minutes: 3),
    this.enablePullToRefresh = true,
    this.enableAutoRefresh = true,
    this.refreshOnFocus = true,
    this.showLastUpdated = true,
    this.showRefreshIndicator = true,
    this.backgroundStrategy,
    this.backgroundRefreshInterval,
    this.keepAliveInBackground = false,
    this.maxBackgroundRefreshes,
  });

  RefreshConfig copyWith({
    Duration? autoRefreshInterval,
    Duration? staleDataThreshold,
    bool? enablePullToRefresh,
    bool? enableAutoRefresh,
    bool? refreshOnFocus,
    bool? showLastUpdated,
    bool? showRefreshIndicator,
    RefreshStrategy? backgroundStrategy,
    Duration? backgroundRefreshInterval,
    bool? keepAliveInBackground,
    int? maxBackgroundRefreshes,
  }) {
    return RefreshConfig(
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
      staleDataThreshold: staleDataThreshold ?? this.staleDataThreshold,
      enablePullToRefresh: enablePullToRefresh ?? this.enablePullToRefresh,
      enableAutoRefresh: enableAutoRefresh ?? this.enableAutoRefresh,
      refreshOnFocus: refreshOnFocus ?? this.refreshOnFocus,
      showLastUpdated: showLastUpdated ?? this.showLastUpdated,
      showRefreshIndicator: showRefreshIndicator ?? this.showRefreshIndicator,
      backgroundStrategy: backgroundStrategy ?? this.backgroundStrategy,
      backgroundRefreshInterval: backgroundRefreshInterval ?? this.backgroundRefreshInterval,
      keepAliveInBackground: keepAliveInBackground ?? this.keepAliveInBackground,
      maxBackgroundRefreshes: maxBackgroundRefreshes ?? this.maxBackgroundRefreshes,
    );
  }
}