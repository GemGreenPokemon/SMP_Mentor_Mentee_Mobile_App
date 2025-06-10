import 'package:flutter/material.dart';
import '../../../services/direct_database_service.dart';

class FirestoreInitializerDialog extends StatefulWidget {
  final String initialState;
  final String initialCity;
  final String initialCampus;
  final Function(String state) onStateChanged;
  final Function(String city) onCityChanged;
  final Function(String campus) onCampusChanged;

  const FirestoreInitializerDialog({
    super.key,
    required this.initialState,
    required this.initialCity,
    required this.initialCampus,
    required this.onStateChanged,
    required this.onCityChanged,
    required this.onCampusChanged,
  });

  @override
  State<FirestoreInitializerDialog> createState() => _FirestoreInitializerDialogState();
}

class _FirestoreInitializerDialogState extends State<FirestoreInitializerDialog> {
  late String _selectedState;
  late String _selectedCity;
  late String _selectedCampus;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialState;
    _selectedCity = widget.initialCity;
    _selectedCampus = widget.initialCampus;
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

  List<Map<String, String>> _getCampusOptions(String city) {
    switch (city) {
      case 'Merced':
        return [
          {'value': 'UC_Merced', 'display': 'UC Merced', 'name': 'University of California, Merced'},
          {'value': 'Merced_College', 'display': 'Merced College', 'name': 'Merced College'},
        ];
      case 'Fresno':
        return [
          {'value': 'Fresno_State', 'display': 'Fresno State', 'name': 'California State University, Fresno'},
          {'value': 'Fresno_City_College', 'display': 'Fresno City College', 'name': 'Fresno City College'},
        ];
      case 'Berkeley':
        return [
          {'value': 'UC_Berkeley', 'display': 'UC Berkeley', 'name': 'University of California, Berkeley'},
          {'value': 'Berkeley_City_College', 'display': 'Berkeley City College', 'name': 'Berkeley City College'},
        ];
      case 'Los Angeles':
        return [
          {'value': 'UCLA', 'display': 'UCLA', 'name': 'University of California, Los Angeles'},
          {'value': 'USC', 'display': 'USC', 'name': 'University of Southern California'},
          {'value': 'LA_City_College', 'display': 'LA City College', 'name': 'Los Angeles City College'},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, color: Color(0xFF0F2D52)),
          SizedBox(width: 8),
          Text('Initialize Firestore Database'),
        ],
      ),
      content: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure your database location before initialization:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // State Dropdown
              _buildDropdownSection(
                'State',
                _selectedState,
                ['California'].map((state) => DropdownMenuItem(
                  value: state,
                  child: Text(state),
                )).toList(),
                (value) {
                  setState(() {
                    _selectedState = value!;
                  });
                  widget.onStateChanged(value!);
                },
              ),
              const SizedBox(height: 16),
              
              // City Dropdown
              _buildDropdownSection(
                'City',
                _selectedCity,
                ['Merced', 'Fresno', 'Berkeley', 'Los Angeles'].map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                )).toList(),
                (value) {
                  setState(() {
                    _selectedCity = value!;
                    _updateCampusSelection(value);
                  });
                  widget.onCityChanged(value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Campus Dropdown
              _buildDropdownSection(
                'Campus',
                _selectedCampus,
                _getCampusOptions(_selectedCity).map((campus) => DropdownMenuItem(
                  value: campus['value'] as String,
                  child: Text(campus['display'] as String),
                )).toList(),
                (value) {
                  setState(() {
                    _selectedCampus = value!;
                  });
                  widget.onCampusChanged(value!);
                },
              ),
              const SizedBox(height: 24),
              
              // Preview Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Structure Preview:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2D52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedState/',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          Text(
                            '  └── $_selectedCity/',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          Text(
                            '      └── $_selectedCampus/',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          const Text(
                            '          ├── users/',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                          const Text(
                            '          ├── meetings/',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                          const Text(
                            '          ├── announcements/',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                          const Text(
                            '          └── ... (all collections)',
                            style: TextStyle(fontFamily: 'monospace', color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User Collection Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '          └── users/ (collection)',
                            style: TextStyle(
                              fontFamily: 'monospace', 
                              fontWeight: FontWeight.bold, 
                              color: Colors.amber[700]
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '              ├── {userId}/ (document)',
                            style: TextStyle(fontFamily: 'monospace', color: Colors.blue),
                          ),
                          const Text(
                            '              │   ├── id: String',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── name: String',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── email: String (unique)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── userType: "mentor" | "mentee" | "coordinator"',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── student_id: String (e.g., "JS12345")',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── mentor: String (mentor\'s student_id)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── mentee: String (JSON array of mentee IDs)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── department: String',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── year_major: String',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── acknowledgment_signed: "yes" | "no" | "not_applicable"',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── created_at: Timestamp',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   │',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const Text(
                            '              │   ├── checklists/ (subcollection)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                          ),
                          const Text(
                            '              │   ├── availability/ (subcollection)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                          ),
                          const Text(
                            '              │   ├── messages/ (subcollection)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                          ),
                          const Text(
                            '              │   ├── notes/ (subcollection)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                          ),
                          const Text(
                            '              │   └── ratings/ (subcollection)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isInitializing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isInitializing ? null : () => _initializeDatabase(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F2D52),
            foregroundColor: Colors.white,
          ),
          child: _isInitializing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Initialize Database'),
        ),
      ],
    );
  }

  Widget _buildDropdownSection(
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      // Get the university name from campus options
      final campusOptions = _getCampusOptions(_selectedCity);
      final selectedCampusData = campusOptions.firstWhere(
        (option) => option['value'] == _selectedCampus,
        orElse: () => {'name': _selectedCampus},
      );
      final universityName = selectedCampusData['name'] ?? _selectedCampus;
      
      // Use direct database service to bypass CORS issues
      Map<String, dynamic> result;
      try {
        result = await DirectDatabaseService.instance.initializeUniversityDirect(
          state: _selectedState,
          city: _selectedCity,
          campus: _selectedCampus,
          universityName: universityName,
        );
      } catch (e) {
        throw Exception('Database Error: ${e.toString()}');
      }
      
      setState(() {
        _isInitializing = false;
      });
      
      // Use addPostFrameCallback to avoid Navigator re-entrance
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Database initialized successfully!'),
                Text('Path: ${result['universityPath']}'),
                Text('Collections: ${(result['collections'] as List).length} created'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      
      // Use addPostFrameCallback to avoid Navigator re-entrance
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize database: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}