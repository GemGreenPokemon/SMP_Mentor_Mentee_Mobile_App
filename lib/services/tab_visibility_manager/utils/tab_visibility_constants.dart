/// Constants for tab visibility management
class TabVisibilityConstants {
  // Storage keys
  static const String storagePrefix = 'tab_visibility_';
  static const String tabsKey = '${storagePrefix}tabs';
  static const String leaderKey = '${storagePrefix}leader';
  static const String dataKey = '${storagePrefix}shared_data';
  static const String eventKey = '${storagePrefix}event';
  
  // Timing constants
  static const Duration leaderHeartbeatInterval = Duration(seconds: 5);
  static const Duration tabTimeoutDuration = Duration(seconds: 15);
  static const Duration leaderElectionDelay = Duration(milliseconds: 500);
  static const Duration dataRefreshInterval = Duration(minutes: 5);
  
  // Tab limits
  static const int maxTabsTracked = 20;
  
  // Event channel names
  static const String visibilityChannel = 'tab_visibility_channel';
  static const String dataChannel = 'tab_data_channel';
}