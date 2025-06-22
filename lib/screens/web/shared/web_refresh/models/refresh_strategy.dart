/// Defines the strategy for background refresh behavior when the page is not visible
enum RefreshStrategy {
  /// No background refresh - refresh is paused when page is not visible
  none,
  
  /// Maintain current refresh interval even when page is not visible
  maintain,
  
  /// Increase refresh frequency when page is hidden to ensure fresh data on return
  aggressive,
  
  /// Adaptive refresh based on data staleness and user patterns
  smart,
}

/// Extension methods for RefreshStrategy
extension RefreshStrategyExtension on RefreshStrategy {
  /// Get the refresh interval multiplier for background refresh
  double get backgroundIntervalMultiplier {
    switch (this) {
      case RefreshStrategy.none:
        return 0; // No refresh
      case RefreshStrategy.maintain:
        return 1.0; // Same as foreground
      case RefreshStrategy.aggressive:
        return 0.5; // Twice as fast
      case RefreshStrategy.smart:
        return 0.75; // Slightly faster
    }
  }
  
  /// Whether this strategy allows background refresh
  bool get allowsBackgroundRefresh => this != RefreshStrategy.none;
  
  /// Get human-readable description
  String get description {
    switch (this) {
      case RefreshStrategy.none:
        return 'No background refresh';
      case RefreshStrategy.maintain:
        return 'Keep normal refresh rate';
      case RefreshStrategy.aggressive:
        return 'Faster refresh when hidden';
      case RefreshStrategy.smart:
        return 'Adaptive refresh based on usage';
    }
  }
}