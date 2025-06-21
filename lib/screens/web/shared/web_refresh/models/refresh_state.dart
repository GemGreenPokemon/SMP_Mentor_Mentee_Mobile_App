import 'package:flutter/foundation.dart';

@immutable
class RefreshState {
  final bool isRefreshing;
  final bool isInitialLoad;
  final DateTime? lastRefresh;
  final String? error;

  const RefreshState({
    this.isRefreshing = false,
    this.isInitialLoad = true,
    this.lastRefresh,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasData => lastRefresh != null;
  bool get canRefresh => !isRefreshing && !isInitialLoad;

  bool shouldAutoRefresh(Duration threshold) {
    if (lastRefresh == null) return true;
    return DateTime.now().difference(lastRefresh!) > threshold;
  }

  String get lastRefreshDisplay {
    if (lastRefresh == null) return 'Never';
    
    final difference = DateTime.now().difference(lastRefresh!);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  RefreshState copyWith({
    bool? isRefreshing,
    bool? isInitialLoad,
    DateTime? lastRefresh,
    String? error,
  }) {
    return RefreshState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      error: error,
    );
  }
}