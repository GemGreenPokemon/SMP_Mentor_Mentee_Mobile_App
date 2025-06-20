import '../models/campus_data.dart';

class CampusHelpers {
  /// Updates campus selection based on the selected city
  /// Returns the default campus value for the city
  static String updateCampusSelection(String city) {
    return CampusData.getDefaultCampusForCity(city);
  }
  
  /// Gets campus options for a specific city
  /// Returns a list of maps compatible with existing dropdown implementations
  static List<Map<String, String>> getCampusOptions(String city) {
    final campuses = CampusData.getCampusesForCity(city);
    return campuses.map((campus) => campus.toMap()).toList();
  }
  
  /// Validates if a campus value exists for a given city
  static bool isValidCampus(String city, String campusValue) {
    final campuses = CampusData.getCampusesForCity(city);
    return campuses.any((campus) => campus.value == campusValue);
  }
  
  /// Gets the display name for a campus value
  static String getCampusDisplayName(String city, String campusValue) {
    final campuses = CampusData.getCampusesForCity(city);
    final campus = campuses.firstWhere(
      (c) => c.value == campusValue,
      orElse: () => CampusInfo(value: campusValue, display: campusValue, fullName: campusValue),
    );
    return campus.display;
  }
  
  /// Gets the full name for a campus value
  static String getCampusFullName(String city, String campusValue) {
    final campuses = CampusData.getCampusesForCity(city);
    final campus = campuses.firstWhere(
      (c) => c.value == campusValue,
      orElse: () => CampusInfo(value: campusValue, display: campusValue, fullName: campusValue),
    );
    return campus.fullName;
  }
  
  /// Builds the database path structure
  static String buildDatabasePath(String state, String city, String campus) {
    return '$state/$city/$campus';
  }
  
  /// Validates the complete location selection
  static bool isValidLocationSelection(String? state, String? city, String? campus) {
    if (state == null || city == null || campus == null) return false;
    if (state.isEmpty || city.isEmpty || campus.isEmpty) return false;
    
    // Check if state is valid
    if (!CampusData.getStates().contains(state)) return false;
    
    // Check if city is valid for state
    if (!CampusData.getCitiesForState(state).contains(city)) return false;
    
    // Check if campus is valid for city
    return isValidCampus(city, campus);
  }
}