import 'package:flutter/material.dart';
import '../models/settings_state.dart';
import '../models/settings_navigation_item.dart';
import '../utils/settings_helpers.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../utils/developer_session.dart';

class SettingsController extends ChangeNotifier {
  final SettingsState _state = SettingsState();
  final AuthService _authService = AuthService();
  
  List<SettingsNavigationItem> _navigationItems = [];
  String? _currentRoute;
  
  // Getters
  SettingsState get state => _state;
  List<SettingsNavigationItem> get navigationItems => _navigationItems;
  String? get currentRoute => _currentRoute;
  int get selectedIndex => _state.selectedIndex;
  bool get isSidebarCollapsed => _state.isSidebarCollapsed;
  
  SettingsController() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Get user role
      final userRole = await _getUserRole();
      _state.setUserRole(userRole);
      
      // Generate navigation items based on role
      _navigationItems = SettingsHelpers.generateNavigationItems(userRole);
      
      // Set initial route
      if (_navigationItems.isNotEmpty) {
        final firstClickableItem = _navigationItems.firstWhere(
          (item) => item.isClickable,
          orElse: () => _navigationItems.first,
        );
        _currentRoute = firstClickableItem.route;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing SettingsController: $e');
    }
  }

  Future<String?> _getUserRole() async {
    try {
      // Check if developer session is active
      if (DeveloperSession.isActive) {
        return 'developer';
      }
      
      // Get role from auth service
      final role = await _authService.getUserRole();
      return role;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  void navigateToIndex(int index) {
    if (index < 0 || index >= _navigationItems.length) return;
    
    final clickableItems = _navigationItems.where((item) => item.isClickable).toList();
    if (index >= clickableItems.length) return;
    
    final item = clickableItems[index];
    navigateToRoute(item.route ?? '/settings');
  }

  void navigateToRoute(String route) {
    _currentRoute = route;
    
    // Find the index of the item with this route
    final clickableItems = _navigationItems.where((item) => item.isClickable).toList();
    final index = clickableItems.indexWhere((item) => item.route == route);
    
    if (index != -1) {
      _state.setSelectedIndex(index);
    }
    
    notifyListeners();
  }

  void navigateById(String id) {
    final item = _navigationItems.firstWhere(
      (item) => item.id == id && item.isClickable,
      orElse: () => _navigationItems.first,
    );
    
    if (item.route != null) {
      navigateToRoute(item.route!);
    }
  }

  void toggleSidebar() {
    _state.toggleSidebar();
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    _state.setSidebarCollapsed(collapsed);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _state.setSearchQuery(query);
    notifyListeners();
  }

  void updateSetting(String key, dynamic value) {
    _state.updateSettingsData(key, value);
    notifyListeners();
  }

  dynamic getSetting(String key) {
    return _state.settingsData[key];
  }

  void setSectionLoading(String section, bool loading) {
    _state.setSectionLoading(section, loading);
    notifyListeners();
  }

  bool isSectionLoading(String section) {
    return _state.isSectionLoading(section);
  }

  void setGlobalLoading(bool loading) {
    _state.setLoading(loading);
    notifyListeners();
  }

  Future<void> refreshUserRole() async {
    final newRole = await _getUserRole();
    if (newRole != _state.currentUserRole) {
      _state.setUserRole(newRole);
      _navigationItems = SettingsHelpers.generateNavigationItems(newRole);
      
      // Check if current route is still accessible
      final currentItem = _navigationItems.firstWhere(
        (item) => item.route == _currentRoute,
        orElse: () => _navigationItems.firstWhere(
          (item) => item.isClickable,
          orElse: () => _navigationItems.first,
        ),
      );
      
      if (currentItem.route != _currentRoute) {
        navigateToRoute(currentItem.route ?? '/settings');
      }
      
      notifyListeners();
    }
  }

  void reset() {
    _state.resetState();
    _navigationItems = [];
    _currentRoute = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }
}