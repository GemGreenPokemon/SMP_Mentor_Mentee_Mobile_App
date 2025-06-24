import 'package:flutter/material.dart';
import '../../web_settings/sections/database_admin_section.dart';
import '../../web_settings/widgets/dialogs/database_initialization_choice_dialog.dart';
import '../../web_settings/widgets/dialogs/firestore_initializer_dialog.dart';
import '../../web_settings/widgets/dialogs/cloud_function_initializer_dialog.dart';
import '../utils/settings_constants.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/cloud_function_service.dart';

class DatabaseAdminView extends StatefulWidget {
  final Function({Function()? onSuccess}) onShowAuthOverlay;
  final bool isAuthenticated;
  
  const DatabaseAdminView({
    super.key,
    required this.onShowAuthOverlay,
    required this.isAuthenticated,
  });

  @override
  State<DatabaseAdminView> createState() => _DatabaseAdminViewState();
}

class _DatabaseAdminViewState extends State<DatabaseAdminView> {
  final AuthService _authService = AuthService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  
  // Firestore initializer variables
  String _selectedState = 'California';
  String _selectedCity = 'Merced';
  String _selectedCampus = 'UC_Merced';

  bool _requiresAuth() {
    return !widget.isAuthenticated && !_authService.isLoggedIn;
  }

  // Handle database initialization with Cloud Functions
  Future<void> _handleDatabaseInitialization() async {
    // Show options dialog - Cloud Function vs Direct (for testing)
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => const DatabaseInitializationChoiceDialog(),
    );

    if (choice == 'cloud') {
      await _handleCloudFunctionInit();
    } else if (choice == 'direct') {
      _showFirestoreInitializerDialog();
    }
  }

  // Handle Cloud Function initialization with authentication
  Future<void> _handleCloudFunctionInit() async {
    // Check if user is authenticated
    if (_requiresAuth()) {
      widget.onShowAuthOverlay(onSuccess: () {
        _showCloudFunctionInitializerDialog();
      });
      return;
    }

    // Check if user has super admin permissions
    final isSuperAdmin = await _authService.isSuperAdmin();
    if (!isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super admin permissions required for database initialization'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed with Cloud Function initialization
    _showCloudFunctionInitializerDialog();
  }

  void _showFirestoreInitializerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FirestoreInitializerDialog(
        initialState: _selectedState,
        initialCity: _selectedCity,
        initialCampus: _selectedCampus,
        onStateChanged: (state) {
          setState(() {
            _selectedState = state;
          });
        },
        onCityChanged: (city) {
          setState(() {
            _selectedCity = city;
            _updateCampusSelection(city);
          });
        },
        onCampusChanged: (campus) {
          setState(() {
            _selectedCampus = campus;
          });
        },
      ),
    );
  }

  void _showCloudFunctionInitializerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloudFunctionInitializerDialog(
        initialState: _selectedState,
        initialCity: _selectedCity,
        initialCampus: _selectedCampus,
        cloudFunctions: _cloudFunctions,
        onStateChanged: (state) {
          setState(() {
            _selectedState = state;
          });
        },
        onCityChanged: (city) {
          setState(() {
            _selectedCity = city;
            _updateCampusSelection(city);
          });
        },
        onCampusChanged: (campus) {
          setState(() {
            _selectedCampus = campus;
          });
        },
      ),
    );
  }

  void _updateCampusSelection(String city) {
    switch (city) {
      case 'Merced':
        _selectedCampus = 'UC_Merced';
        break;
      case 'Fresno':
        _selectedCampus = 'Fresno_State';
        break;
      case 'Berkeley':
        _selectedCampus = 'UC_Berkeley';
        break;
      case 'Los Angeles':
        _selectedCampus = 'UCLA';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < SettingsDashboardConstants.mobileBreakpoint;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? SettingsDashboardConstants.compactPadding
            : SettingsDashboardConstants.defaultPadding,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: DatabaseAdminSection(
            onInitializeDatabase: _handleDatabaseInitialization,
          ),
        ),
      ),
    );
  }
}