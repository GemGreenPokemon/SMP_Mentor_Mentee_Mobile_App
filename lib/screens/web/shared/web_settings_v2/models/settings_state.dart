import 'package:flutter/foundation.dart';

class SettingsState extends ChangeNotifier {
  int _selectedIndex = 0;
  String _searchQuery = '';
  Map<String, dynamic> _settingsData = {};
  bool _isLoading = false;
  bool _isSidebarCollapsed = false;
  String? _currentUserRole;
  Map<String, bool> _sectionLoadingStates = {};

  // Getters
  int get selectedIndex => _selectedIndex;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get settingsData => _settingsData;
  bool get isLoading => _isLoading;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  String? get currentUserRole => _currentUserRole;

  // Methods
  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void updateSettingsData(String key, dynamic value) {
    _settingsData[key] = value;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setSectionLoading(String section, bool loading) {
    _sectionLoadingStates[section] = loading;
    notifyListeners();
  }

  bool isSectionLoading(String section) {
    return _sectionLoadingStates[section] ?? false;
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    if (_isSidebarCollapsed != collapsed) {
      _isSidebarCollapsed = collapsed;
      notifyListeners();
    }
  }

  void setUserRole(String? role) {
    _currentUserRole = role;
    notifyListeners();
  }

  void resetState() {
    _selectedIndex = 0;
    _searchQuery = '';
    _settingsData = {};
    _isLoading = false;
    _sectionLoadingStates = {};
    notifyListeners();
  }

  @override
  void dispose() {
    resetState();
    super.dispose();
  }
}