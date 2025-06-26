// Export the interface
export 'tab_visibility_helpers_interface.dart';

// Conditional imports
import 'tab_visibility_helpers_interface.dart';
import 'tab_visibility_helpers_mobile.dart'
    if (dart.library.html) 'tab_visibility_helpers_web.dart' as impl;
import '../models/tab_state.dart';

/// Factory to create the appropriate TabVisibilityHelpers implementation
class TabVisibilityHelpers {
  static TabVisibilityHelpersInterface? _instance;
  
  /// Get the singleton instance of TabVisibilityHelpers
  /// 
  /// Returns the appropriate implementation based on platform:
  /// - Web: TabVisibilityHelpersWeb with localStorage support
  /// - Mobile: TabVisibilityHelpersMobile with in-memory storage
  static TabVisibilityHelpersInterface getInstance() {
    _instance ??= _createInstance();
    return _instance!;
  }
  
  static TabVisibilityHelpersInterface _createInstance() {
    // The conditional import will handle this automatically
    // On web: impl.TabVisibilityHelpersWeb
    // On mobile: impl.TabVisibilityHelpersMobile
    return impl.TabVisibilityHelpersImpl();
  }
  
  // Static methods that delegate to the instance
  static String generateTabId() => getInstance().generateTabId();
  static bool isTabTimedOut(TabState tab) => getInstance().isTabTimedOut(tab);
  static List<TabState> getActiveTabs() => getInstance().getActiveTabs();
  static void saveTabs(List<TabState> tabs) => getInstance().saveTabs(tabs);
  static String? getCurrentLeader() => getInstance().getCurrentLeader();
  static void setLeader(String tabId) => getInstance().setLeader(tabId);
  static void clearAllData() => getInstance().clearAllData();
  static bool isBrowserSupported() => getInstance().isBrowserSupported();
  static Map<String, dynamic>? getSharedData(String key) => getInstance().getSharedData(key);
  static void saveSharedData(String key, Map<String, dynamic> data) => getInstance().saveSharedData(key, data);
  
  // Prevent instantiation
  TabVisibilityHelpers._();
}