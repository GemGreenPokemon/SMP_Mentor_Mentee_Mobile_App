import '../utils/settings_constants.dart';

class SettingsState {
  // Notification Settings
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  
  // Appearance Settings
  final bool darkMode;
  final String language;
  final double fontSize;
  final String theme;
  
  // File Storage Settings
  final String downloadLocation;
  final bool autoDownload;
  final int maxFileSize;
  
  // Account Settings
  final bool profilePublic;
  final bool showEmail;
  final bool twoFactorEnabled;
  
  const SettingsState({
    this.notificationsEnabled = SettingsConstants.defaultNotificationsEnabled,
    this.emailNotifications = SettingsConstants.defaultEmailNotifications,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.darkMode = SettingsConstants.defaultDarkMode,
    this.language = SettingsConstants.defaultLanguage,
    this.fontSize = 16.0,
    this.theme = 'default',
    this.downloadLocation = SettingsConstants.defaultDownloadLocation,
    this.autoDownload = false,
    this.maxFileSize = 100, // MB
    this.profilePublic = true,
    this.showEmail = false,
    this.twoFactorEnabled = false,
  });
  
  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? darkMode,
    String? language,
    double? fontSize,
    String? theme,
    String? downloadLocation,
    bool? autoDownload,
    int? maxFileSize,
    bool? profilePublic,
    bool? showEmail,
    bool? twoFactorEnabled,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      downloadLocation: downloadLocation ?? this.downloadLocation,
      autoDownload: autoDownload ?? this.autoDownload,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      profilePublic: profilePublic ?? this.profilePublic,
      showEmail: showEmail ?? this.showEmail,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'darkMode': darkMode,
      'language': language,
      'fontSize': fontSize,
      'theme': theme,
      'downloadLocation': downloadLocation,
      'autoDownload': autoDownload,
      'maxFileSize': maxFileSize,
      'profilePublic': profilePublic,
      'showEmail': showEmail,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }
  
  factory SettingsState.fromMap(Map<String, dynamic> map) {
    return SettingsState(
      notificationsEnabled: map['notificationsEnabled'] ?? SettingsConstants.defaultNotificationsEnabled,
      emailNotifications: map['emailNotifications'] ?? SettingsConstants.defaultEmailNotifications,
      pushNotifications: map['pushNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      darkMode: map['darkMode'] ?? SettingsConstants.defaultDarkMode,
      language: map['language'] ?? SettingsConstants.defaultLanguage,
      fontSize: (map['fontSize'] ?? 16.0).toDouble(),
      theme: map['theme'] ?? 'default',
      downloadLocation: map['downloadLocation'] ?? SettingsConstants.defaultDownloadLocation,
      autoDownload: map['autoDownload'] ?? false,
      maxFileSize: map['maxFileSize'] ?? 100,
      profilePublic: map['profilePublic'] ?? true,
      showEmail: map['showEmail'] ?? false,
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
    );
  }
}