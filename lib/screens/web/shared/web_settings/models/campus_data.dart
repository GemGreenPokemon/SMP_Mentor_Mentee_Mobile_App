class CampusData {
  static const Map<String, List<String>> stateCities = {
    'California': ['Merced', 'Fresno', 'Berkeley', 'Los Angeles'],
    'Texas': ['Houston', 'Dallas', 'Austin', 'Prairie View'],
  };

  static const Map<String, List<CampusInfo>> cityCampuses = {
    // California campuses
    'Merced': [
      CampusInfo(
        value: 'UC_Merced',
        display: 'UC Merced',
        fullName: 'University of California, Merced',
      ),
      CampusInfo(
        value: 'Merced_College',
        display: 'Merced College',
        fullName: 'Merced College',
      ),
    ],
    'Fresno': [
      CampusInfo(
        value: 'Fresno_State',
        display: 'Fresno State',
        fullName: 'California State University, Fresno',
      ),
      CampusInfo(
        value: 'Fresno_City_College',
        display: 'Fresno City College',
        fullName: 'Fresno City College',
      ),
    ],
    'Berkeley': [
      CampusInfo(
        value: 'UC_Berkeley',
        display: 'UC Berkeley',
        fullName: 'University of California, Berkeley',
      ),
      CampusInfo(
        value: 'Berkeley_City_College',
        display: 'Berkeley City College',
        fullName: 'Berkeley City College',
      ),
    ],
    'Los Angeles': [
      CampusInfo(
        value: 'UCLA',
        display: 'UCLA',
        fullName: 'University of California, Los Angeles',
      ),
      CampusInfo(
        value: 'USC',
        display: 'USC',
        fullName: 'University of Southern California',
      ),
      CampusInfo(
        value: 'LA_City_College',
        display: 'LA City College',
        fullName: 'Los Angeles City College',
      ),
    ],
    // Texas campuses
    'Houston': [
      CampusInfo(
        value: 'UH',
        display: 'UH',
        fullName: 'University of Houston',
      ),
      CampusInfo(
        value: 'Rice',
        display: 'Rice',
        fullName: 'Rice University',
      ),
      CampusInfo(
        value: 'TSU',
        display: 'TSU',
        fullName: 'Texas Southern University',
      ),
    ],
    'Dallas': [
      CampusInfo(
        value: 'UTD',
        display: 'UTD',
        fullName: 'University of Texas at Dallas',
      ),
      CampusInfo(
        value: 'SMU',
        display: 'SMU',
        fullName: 'Southern Methodist University',
      ),
    ],
    'Austin': [
      CampusInfo(
        value: 'UT',
        display: 'UT',
        fullName: 'University of Texas at Austin',
      ),
    ],
    'Prairie View': [
      CampusInfo(
        value: 'PVAMU',
        display: 'PVAMU',
        fullName: 'Prairie View A&M University',
      ),
    ],
  };

  static List<String> getStates() => stateCities.keys.toList();

  static List<String> getCitiesForState(String state) {
    return stateCities[state] ?? [];
  }

  static List<CampusInfo> getCampusesForCity(String city) {
    return cityCampuses[city] ?? [];
  }

  static String getDefaultCampusForCity(String city) {
    final campuses = getCampusesForCity(city);
    return campuses.isNotEmpty ? campuses.first.value : '';
  }
}

class CampusInfo {
  final String value;
  final String display;
  final String fullName;

  const CampusInfo({
    required this.value,
    required this.display,
    required this.fullName,
  });

  Map<String, String> toMap() => {
    'value': value,
    'display': display,
    'name': fullName,
  };
}