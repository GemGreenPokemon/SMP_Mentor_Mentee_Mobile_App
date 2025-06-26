// Export the interface and models
export 'tab_visibility_manager_interface.dart';
export 'models/tab_state.dart';
export 'models/visibility_event.dart';

// Conditional imports
import 'tab_visibility_manager_interface.dart';
import 'tab_visibility_manager_mobile.dart'
    if (dart.library.html) 'tab_visibility_manager_web.dart' as impl;

/// Factory to create the appropriate TabVisibilityManager implementation
class TabVisibilityManager {
  static TabVisibilityManagerInterface? _instance;
  
  /// Get the singleton instance of TabVisibilityManager
  /// 
  /// Returns the appropriate implementation based on platform:
  /// - Web: TabVisibilityManagerWeb with full tab management
  /// - Mobile: TabVisibilityManagerMobile with stub implementation
  static TabVisibilityManagerInterface getInstance() {
    // The conditional import will automatically select the correct implementation
    // On web: impl.TabVisibilityManagerWeb
    // On mobile: impl.TabVisibilityManagerMobile
    _instance ??= impl.TabVisibilityManagerImpl();
    return _instance!;
  }
  
  // Prevent instantiation
  TabVisibilityManager._();
}