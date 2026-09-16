class StorageKeys {
  // Auth keys
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String isLoggedIn = 'is_logged_in';
  static const String biometricEnabled = 'biometric_enabled';
  static const String authIsAuthenticated = 'auth_is_authenticated';
  static const String authUserId = 'auth_user_id';
  static const String authRole = 'auth_role';
  static const String authUserPhone = 'auth_user_phone';
  static const String authExpiresAt = 'auth_expires_at';
  static const String authAccountStatus = 'auth_account_status';
  static const String pendingRegistrations = 'pending_registrations';

  // Organization chart keys
  static const String orgChartSearchHistory = 'org_chart_search_history';
  static const String orgChartViewMode = 'org_chart_view_mode';
  static const String orgChartIsHorizontal = 'org_chart_is_horizontal';
  static const String orgChartIsCompactMode = 'org_chart_is_compact_mode';
  
  // Profile keys
  static const String userProfile = 'user_profile';
  
  // Settings keys
  static const String language = 'language';
  static const String theme = 'theme';
  
  // HR keys
  static const String hrEmployeesList = 'hr_employees_list';

  // Fingerprint keys (prefix — append userId)
  static const String fingerprintPrefix = 'device_fp_';

  // App lifecycle keys
  // Marks that the app ran at least once on this install. Used to detect
  // a fresh install (e.g. after delete on iOS) since SharedPreferences is
  // wiped on uninstall while the iOS Keychain (secure storage) survives.
  static const String appInstallFlag = 'app_install_flag';
}
